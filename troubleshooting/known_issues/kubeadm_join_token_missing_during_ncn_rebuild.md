# Node Unable to Join Kubernetes Cluster During NCN Rebuild

## Description

During NCN master node rebuild, the node may fail to join the Kubernetes cluster due to a missing or expired bootstrap token.
This occurs when the token referenced in the join scripts located in `/etc/cray/kubernetes` is no longer present in the cluster's
token list or the `cluster-info` ConfigMap. The join scripts are created during initial cluster setup and may reference tokens
that have since expired or been removed from the cluster.

Bootstrap tokens should be automatically refreshed by the `cray-k8s-token-certs-refresh` cronjob, which runs hourly
(`0 */1 * * *`) on the first-master node. If this cronjob is not running or has failed, tokens may become stale, causing
node join failures.

## Symptoms

* The node fails to join the Kubernetes cluster during rebuild with a `kubeadm join` error.
* The error message indicates that a JWS signature cannot be found in the `cluster-info` ConfigMap for the token ID.

Example error output:

```text
Attempting to join node to the Kubernetes cluster (will continue to retry if it fails)
kubeadm join 10.252.1.2:6442 --token 770vrq.adapc6m1k68f14r3 --discovery-token-ca-cert-hash sha256:86d0422bb32949fc49fbac28eaf01abe37401f2e93203815c6bd1287403c9af5  --control-plane --certificate-key fa0d08d9b5257c63ae9c3c19c8c766059d46e91454f1325f4f60aac1b7cc6408 --apiserver-advertise-address=10.252.1.17 --apiserver-advertise-address=10.252.1.17...
[preflight] Running pre-flight checks
error execution phase preflight: couldn't validate the identity of the API Server: could not find a JWS signature in the cluster-info ConfigMap for token ID "770vrq"
To see the stack trace of this error execute with --v=5 or higher
```

## Verification

1. (`ncn-m#`) Identify the first-master node from BSS.

   Command:

   ```bash
   cray bss bootparameters list --hosts Global --format toml | grep first-master-hostname
   ```

   Example output:

   ```toml
   first-master-hostname = "ncn-m001"
   ```

1. (`ncn-m#`) Check if the token exists in the cluster's token list.

   Command:

   ```bash
   kubeadm token list
   ```

   If the token referenced in the error (e.g., `770vrq`) is not listed, the token has expired or been removed.

1. (`ncn-m#`) Verify the token is missing from the `cluster-info` ConfigMap.

   Command:

   ```bash
   kubectl -n kube-public get cm cluster-info -o yaml
   ```

   If the token is not present in the ConfigMap, it needs to be regenerated.

1. (`first-master#`) Check if the `cray-k8s-token-certs-refresh` cronjob is configured and running on the first-master node.

   Command:

   ```bash
   cat /etc/cron.d/cray-k8s-token-certs-refresh
   ```

   Expected output:

   ```text
   0 */1 * * * root /srv/cray/scripts/kubernetes/token-certs-refresh.sh >> /var/log/cray/cron.log 2>&1
   ```

   Check recent cron log entries:

   ```bash
   grep token-certs-refresh /var/log/cray/cron.log | tail -10
   ```

   If the cronjob is missing or not running, this may be why tokens are stale.

## Solution

Rerun the `promote-initial-master.sh` script on the first-master node to regenerate the bootstrap tokens, update the join scripts,
and restore the `cray-k8s-token-certs-refresh` cronjob.

1. (`ncn-m#`) Identify the first-master node from BSS if not already known.

   Command:

   ```bash
   cray bss bootparameters list --hosts Global --format toml | grep first-master-hostname
   ```

   Example output:

   ```toml
   first-master-hostname = "ncn-m001"
   ```

1. (`first-master#`) Run the promote initial master script on the first-master node.

   Command:

   ```bash
   /usr/share/doc/csm/upgrade/scripts/k8s/promote-initial-master.sh
   ```

   This script will:
   * Create new bootstrap tokens
   * Update the `cluster-info` ConfigMap with the new tokens
   * Regenerate the join scripts in `/etc/cray/kubernetes` with valid tokens
   * Create/update the `cray-k8s-token-certs-refresh` cronjob to run hourly (`0 */1 * * *`)

1. (`first-master#`) Verify the cronjob is now configured.

   Command:

   ```bash
   cat /etc/cron.d/cray-k8s-token-certs-refresh
   ```

   Expected output:

   ```text
   0 */1 * * * root /srv/cray/scripts/kubernetes/token-certs-refresh.sh >> /var/log/cray/cron.log 2>&1
   ```

1. (`ncn-m#`) Retry the node rebuild process.

   The node should now be able to join the Kubernetes cluster using the updated tokens.

1. (`ncn-m#`) Verify the node has successfully joined the cluster.

   Command:

   ```bash
   kubectl get nodes
   ```

   The rebuilt node should appear in the node list with a `Ready` status.
