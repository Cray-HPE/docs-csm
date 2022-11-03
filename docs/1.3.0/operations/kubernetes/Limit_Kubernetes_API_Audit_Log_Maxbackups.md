# Configure Kubernetes API Audit Log Maximum Backups

If Kubernetes API Auditing was enabled at install or upgrade, via the `CSI` option `--k8s-api-auditing-enabled true` or the `system_config.yaml` option `k8s-api-auditing-enabled: true`, apply this procedure to running Kubernetes Master Nodes.

## Prerequisites

This procedure requires administrative privileges and assumes that the device being used has:

- `kubectl` is installed
- Access to the site admin network

## Procedure

1. SSH as root to the first Kubernetes Master Node, canonically `ncn-m001`.

2. Verify Kubernetes API Auditing is enabled.

   You should see both of the following settings in `kube-apiserver.yaml`.

   ```bash
   ncn-m# egrep 'audit-log-path|audit-policy-file' /etc/kubernetes/manifests/kube-apiserver.yaml 
       - --audit-log-path=/var/log/audit/kl8s/apiserver/audit.log
       - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
   ```

3. Verify all Kubernetes API Server Pods are Running. You should have one for each master node.  

   ```bash
   ncn-m# kubectl get pod -n kube-system -l component=kube-apiserver -o wide
   NAME                      READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
   kube-apiserver-ncn-m001   1/1     Running   0          44m     10.252.1.4   ncn-m001   <none>           <none>
   kube-apiserver-ncn-m002   1/1     Running   0          2m1s    10.252.1.5   ncn-m002   <none>           <none>
   kube-apiserver-ncn-m003   1/1     Running   0          3d20h   10.252.1.6   ncn-m003   <none>           <none>
   ```

4. If Kubernetes API Auditing is enabled, add `--audit-log-maxbackup=100` command line option to the Kubernetes API Server.

   Make a backup of the `/etc/kubernetes/manifests/kube-apiserver.yaml`. Ensure the backup is to a directory other than `/etc/kubernetes/manifests/`.

   ```bash
   ncn-m# cp -a /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
   ```

   Edit the `/etc/kubernetes/manifests/kube-apiserver.yaml` file, adding `--audit-log-maxbackup=100` as an option after `--audit-policy-file`.

   ```bash
   ncn-m# grep -n "\-\-audit" /etc/kubernetes/manifests/kube-apiserver.yaml 
   46:    - --audit-log-path=/var/log/audit/kl8s/apiserver/audit.log
   47:    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
   48:    - --audit-log-maxbackup=100
   ```

5. Wait for the Kubernetes API Server Pod on the node to restart. Do not proceed until the pod is in a running state and is ready.

   Monitor the node and pod age using:

   ```bash
   ncn-m# kubectl get pod -n kube-system -l component=kube-apiserver -o wide
   NAME                      READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
   kube-apiserver-ncn-m001   1/1     Running   0          44m     10.252.1.4   ncn-m001   <none>           <none>
   kube-apiserver-ncn-m002   1/1     Running   0          2m1s    10.252.1.5   ncn-m002   <none>           <none>
   kube-apiserver-ncn-m003   1/1     Running   0          3d20h   10.252.1.6   ncn-m003   <none>           <none>
   ```

6. Repeat steps 2-5 for all other master nodes.
