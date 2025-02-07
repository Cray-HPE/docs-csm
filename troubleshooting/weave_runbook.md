# Weave Container Network Interface Troubleshooting

- [Weave Container Network Interface Troubleshooting](#weave-container-network-interface-troubleshooting)
    - [Background](#background)
    - [Check the status of the Weave Pods](#check-the-status-of-the-weave-pods)
    - [Check the status of the Weave connections](#check-the-status-of-the-weave-connections)
    - [Check the Weave maximum transmission unit (MTU)](#check-the-weave-maximum-transmission-unit-mtu)

## Background

CSM uses the Weave Container Network Interface (CNI) which creates an overlay network across multiple Kubernetes cluster
nodes enabling Pod-to-Pod communication.

Weave has two modes of operation.

- Fast path mode (`fastdp`) which operates in kernel space and uses `VxLAN` for encapsulation. CSM uses Weave in this mode.
- Sleeve mode which operates in user space. This mode can support features such as encryption of L2 traffic but has a
  noticeable performance impact.

Weave problem can manifest themselves in a number of ways

- DNS lookups may fail.
- `cray` CLI commands run on Kubernetes nodes may fail.
- Pods may show signs of network communication problems in their logs, for example connection timeouts.

## Check the status of the Weave Pods

(`ncn-mw#`) On any Kubernetes NCN run:

```bash
kubectl -n kube-system get pod -l name=weave-net -o wide
```

Example output:

```console
NAME              READY   STATUS    RESTARTS      AGE   IP            NODE       NOMINATED NODE   READINESS GATES
weave-net-9hvch   2/2     Running   1 (34h ago)   34h   10.252.1.13   ncn-w004   <none>           <none>
weave-net-brsnc   2/2     Running   1 (34h ago)   34h   10.252.1.9    ncn-w001   <none>           <none>
weave-net-ljf5l   2/2     Running   1 (34h ago)   34h   10.252.1.7    ncn-w003   <none>           <none>
weave-net-mq7jm   2/2     Running   1 (34h ago)   34h   10.252.1.8    ncn-w002   <none>           <none>
weave-net-nz4bz   2/2     Running   2 (12h ago)   12h   10.252.1.12   ncn-m001   <none>           <none>
weave-net-tdkqc   2/2     Running   1 (34h ago)   34h   10.252.1.14   ncn-w005   <none>           <none>
weave-net-tzgzx   2/2     Running   1 (34h ago)   34h   10.252.1.11   ncn-m002   <none>           <none>
weave-net-w5r64   2/2     Running   1 (34h ago)   34h   10.252.1.10   ncn-m003   <none>           <none>
```

Every CSM master and worker node should have a `weave-net` Pod. If a node is missing from the output, verify it is a member of the Kubernetes cluster.

One commonly seen problem is that a `weave-net` Pod has been evicted from the node. The usual cause of this is the root file system filling up beyond 80% full.
To correct this issue, resolve the problem that caused the `weave-net` Pod to be evicted and the restart it if necessary.

## Check the status of the Weave connections

(`ncn-mw#`) On any Kubernetes NCN run:

```bash
weave --local status connections
```

Example output:

```console
-> 10.252.1.10:6783      established fastdp 0a:71:c0:05:59:11(ncn-m003) mtu=1376
-> 10.252.1.11:6783      established fastdp da:cf:fe:8a:46:28(ncn-m002) mtu=1376
-> 10.252.1.14:6783      established fastdp d6:5c:7b:4d:80:4f(ncn-w005) mtu=1376
-> 10.252.1.8:6783       established fastdp 72:a0:c4:07:6d:fa(ncn-w002) mtu=1376
-> 10.252.1.13:6783      established fastdp a6:52:76:1e:2b:1a(ncn-w004) mtu=1376
-> 10.252.1.7:6783       established fastdp ba:0d:82:16:53:36(ncn-w003) mtu=1376
-> 10.252.1.9:6783       established fastdp 3e:84:f2:95:79:75(ncn-w001) mtu=1376
```

Example output if a node has degraded into Sleeve mode:

```console
<- 10.252.1.14:60853     established sleeve d6:5c:7b:4d:80:4f(ncn-w005) mtu=8938
```

The health checks run as part of [Validate CSM Health](../operations/validate_csm_health.md) also detect if a node is running in Sleeve mode.

Example output:

```console
Result: FAIL
Source: http://ncn-m001.hmn:9001/ncn-kubernetes-tests-master
Test Name: Weave Health
Description: Check that Weave is healthy. Run "weave --local status connections" on any unhealthy node and check the MTU.
Test Summary: Command: k8s_check_weave_status: stdout: patterns not found: [!/.*sleeve/]
Execution Time: 0.000059541 seconds
Node: ncn-m001
```

A common cause of this problem is an incorrectly sized ARP cache. On the affected node check the output of the `dmesg`
command or the `/var/log/messages` file for neighbor table overflow messages.

Example output:

```console
[Tue Jul 23 14:51:07 2024] neighbour: arp_cache: neighbor table overflow!
```

If the ARP cache is too small, then performance will be poor as entries are continually purged from and added to the cache.

See the [ARP Cache Tuning Guide](../operations/configuration_management/ARP_cache_tuning.md) for guidance on sizing the cache
correctly for the system.

## Check the Weave maximum transmission unit (MTU)

If the Weave MTU is mismatched between nodes poor performance may be observed and one or more of the Weave connections may degrade
into Sleeve mode.

As indicated in [Check the status of the Weave connections](#check-the-status-of-the-weave-connections) the Weave MTU should be `1367`

1. (`ncn-mw#`) Check the MTU of the `weave` network interface.

   ```bash
   ip ad show weave
   ```

   Example output:

   ```console
   19: weave: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 qdisc noqueue state UP group default qlen 1000
   link/ether e2:92:46:1a:36:55 brd ff:ff:ff:ff:ff:ff
   inet 10.43.0.0/12 brd 10.47.255.255 scope global weave
   valid_lft forever preferred_lft forever
   inet6 fe80::e092:46ff:fe1a:3655/64 scope link
   valid_lft forever preferred_lft forever
   ```

1. (`ncn-mw#`) Check the MTU configured in the `weave-net` DaemonSet.

   ```bash
   kubectl -n kube-system get ds weave-net -o yaml | yq4 eval '.spec.template.spec.containers[] | select(.name=="weave") | .env'
   ```
  
   Example output:

   ```console
   - name: HOSTNAME
     valueFrom:
       fieldRef:
         apiVersion: v1
         fieldPath: spec.nodeName
   - name: IPALLOC_RANGE
     value: 10.32.0.0/12
   - name: WEAVE_MTU
     value: "1376"
   - name: INIT_CONTAINER
     value: "true"
   ```

1. (`ncn-mw#`) Check the MTU configured in the BSS metadata.

   ```bash
   craysys metadata get kubernetes-weave-mtu
   ```

   Example output:

   ```console
   1376
   ```

If the MTU on the `weave` network interface is incorrect but the MTU in the `weave-net` DaemonSet is configured correctly
restart the `weave-net` Pod on the affected node. If restarting the Pod fails to resolve the problem then reboot the node.

If the DaemonSet or BSS metadata value is set incorrectly refer to [Cray FN #6636 - Shasta 1.4 Weave MTU Regression](https://support.hpe.com/hpesc/docDisplay?docLocale=en_US&docId=crsc6636en_us)
