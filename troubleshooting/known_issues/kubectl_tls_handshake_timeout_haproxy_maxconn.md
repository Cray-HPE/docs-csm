# `kubectl` TLS Handshake Timeout Caused by HAProxy Connection Exhaustion

## Issue description

`kubectl` commands fail with a TLS handshake timeout and the Kubernetes API server becomes unreachable via the HAProxy
load balancer endpoint. This can happen when a large number of stuck `kubectl` processes accumulate on NCN master and
worker nodes, exhausting the per-server connection limit (`maxconn`) configured in HAProxy. Once this limit is reached,
HAProxy cannot accept any new connections and all new `kubectl` requests time out.

## Symptoms

`kubectl` commands fail with the following error:

```text
Unable to connect to the server: net/http: TLS handshake timeout
```

Directly querying the HAProxy endpoint also fails:

```bash
curl -k https://<ncn-m001-nmn-ip>:6442/healthz
```

```text
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to <ncn-m001-nmn-ip>:6442
```

Other Kubernetes-dependent services may also report errors such as:

```text
Error from server (BadRequest): the server rejected our request for an unknown reason
```

or:

```text
error sending request: Post "https://<ncn-m001-hmn-ip>:6442/...": EOF
```

Restarting HAProxy (`systemctl restart haproxy`) may restore brief functionality, but the issue quickly recurs until
the underlying stuck processes are cleared.

## Diagnosis

### 1. Check HAProxy connection counts

On any master NCN, inspect the HAProxy stats socket to determine whether the session limit has been reached:

```bash
echo "show stat" | socat stdio /var/lib/haproxy/stats | grep "^k8s-api" | \
  awk -F, '{printf "%-15s qcur:%-4s qmax:%-4s scur:%-4s smax:%-4s slim:%-4s stot:%-6s status:%s\n", \
  $2, $3, $4, $5, $6, $7, $8, $18}'
```

When the issue is occurring, `scur` (current sessions) equals `slim` (session limit) for all backend servers,
indicating that no new connections can be accepted:

```text
k8s-api-1       qcur:0    qmax:0    scur:250  smax:250  slim:250  stot:309    status:UP
k8s-api-2       qcur:0    qmax:0    scur:250  smax:250  slim:250  stot:315    status:UP
k8s-api-3       qcur:0    qmax:0    scur:250  smax:250  slim:250  stot:1207   status:UP
```

### 2. Count stuck `kubectl` processes

Check the number of `kubectl` processes running on all master and worker nodes. A healthy node should have only a
handful of `kubectl` processes. Counts in the range of 90–130 per node indicate accumulation of stuck processes:

```bash
pdsh -w ncn-m00[1-3],ncn-w0[01-XX] 'ps aux | grep kubectl | wc -l'
```

Example output showing the problem:

```text
ncn-m002: 91
ncn-m003: 129
ncn-w001: 98
ncn-w007: 94
...
```

To see which processes are stuck, run the following on an affected node:

```bash
ps aux | grep kubectl | grep -v grep
```

Common offenders are health check scripts that have spawned many `kubectl rollout status` processes that never exit:

```text
root  3134904  0.0  0.0 1283728 42876 ?  Sl  Jan25  0:26 /usr/bin/kubectl rollout status -n kube-system daemonset.apps/weave-net
root  3579944  0.0  0.0   7184  3328 ?   S   Jan25  0:00 bash /opt/cray/tests/install/ncn/scripts/log_run.sh -l k8s_check_weave_net_daemon_set /usr/bin/kubectl rollout status -n kube-system daemonset.apps/weave-net
```

## Fix

### Step 1: Temporarily increase HAProxy `maxconn` to restore access

On **each** master NCN, edit `/etc/haproxy/haproxy.cfg` and increase the `maxconn` value in the `k8s-api` backend
from `250` to `2500` (or another suitably higher value):

```text
backend k8s-api
    ...
    default-server verify none check-ssl inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 2500 maxqueue 256 weight 100
```

Then reload HAProxy:

```bash
systemctl reload haproxy
```

This restores `kubectl` functionality while the stuck processes are cleaned up.

### Step 2: Kill stuck `kubectl` processes on all master and worker nodes

Run the following on each affected node to terminate the stuck processes. Replace `ncn-w0[01-XX]` with the appropriate
worker node range for the system:

```bash
pdsh -w ncn-m00[1-3],ncn-w0[01-XX] 'pkill -f "kubectl rollout status"'
```

Alternatively, to kill all `kubectl` processes (use with care):

```bash
pdsh -w ncn-m00[1-3],ncn-w0[01-XX] 'pkill kubectl'
```

### Step 3: Verify HAProxy connection counts return to normal

After clearing the stuck processes, confirm that session counts have dropped significantly:

```bash
while true; do
  echo "=== $(date) ==="
  echo "show stat" | socat stdio /var/lib/haproxy/stats | grep "^k8s-api" | \
    awk -F, '{printf "%-15s qcur:%-4s qmax:%-4s scur:%-4s smax:%-4s slim:%-4s stot:%-6s status:%s\n", \
    $2, $3, $4, $5, $6, $7, $8, $18}'
  sleep 5
done
```

Normal output (with `scur` well below `slim`) looks like:

```text
k8s-api-1       qcur:0    qmax:0    scur:27   smax:264  slim:2500 stot:486    status:UP
k8s-api-2       qcur:0    qmax:0    scur:22   smax:253  slim:2500 stot:485    status:UP
k8s-api-3       qcur:0    qmax:0    scur:25   smax:249  slim:2500 stot:485    status:UP
```

### Step 4 (optional): Bypass HAProxy for immediate access

While investigating, it is possible to communicate directly with a `kube-apiserver` process on a specific master node
by editing a copy of `admin.conf` to point at the node's IP and port `6443` instead of the HAProxy address.

Find the location of the current Kubernetes configuration file:

```bash
echo $KUBECONFIG
```

Example output:

```text
/etc/kubernetes/admin.conf
```

Copy the file and edit the `server` field to point directly at one of the master node IPs on port `6443`:

```bash
cp /etc/kubernetes/admin.conf /root/admin-direct.conf
```

```yaml
clusters:
- cluster:
    certificate-authority-data: <snip>
    server: https://10.252.1.14:6443   # Direct to kube-apiserver, bypassing HAProxy
```

```bash
kubectl --kubeconfig /root/admin-direct.conf get nodes
```
