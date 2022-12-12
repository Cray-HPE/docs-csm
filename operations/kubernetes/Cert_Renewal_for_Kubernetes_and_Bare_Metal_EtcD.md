# Kubernetes and Bare Metal EtcD Certificate Renewal

As part of the installation, Kubernetes generates certificates for the required subcomponents.
This document will help walk through the process of renewing the certificates.

**IMPORTANT:**

- Depending on the version of Kubernetes, the command may or may not reside under the `alpha` category. Use `kubectl certs --help` and `kubectl alpha certs --help` to determine this.
  The overall command syntax is the same; the only difference is whether or not the command structure includes `alpha`.
- The node referenced in this document as `ncn-m` is the master node selected to renew the certificates on.
- This document is based off a base hardware configuration of three master nodes and three worker nodes. Utility storage nodes are not mentioned because they are not running Kubernetes. Make sure to update any commands that run on multiple nodes accordingly.

Procedures for Certificate Renewal:

- [File Locations](#file-locations)
- [Check Certificates](#check-certificates)
- [Backup Existing Certificates](#backup-existing-certificates)
- [Renew All Certificates](#renew-all-certificates)
- [Renew Etcd Certificate](#renew-etcd-certificate)
- [Update Client Secrets](#update-client-secrets)

## File Locations

**IMPORTANT:** Master nodes will have certificates for both Kubernetes services and the Kubernetes client. Workers will only have the certificates for the Kubernetes client.

Services (master nodes):

```text
/etc/kubernetes/pki/apiserver.crt
/etc/kubernetes/pki/apiserver-etcd-client.crt
/etc/kubernetes/pki/apiserver-etcd-client.key
/etc/kubernetes/pki/apiserver.key
/etc/kubernetes/pki/apiserver-kubelet-client.crt
/etc/kubernetes/pki/apiserver-kubelet-client.key
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
/etc/kubernetes/pki/front-proxy-client.crt
/etc/kubernetes/pki/front-proxy-client.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/etcd/ca.key
/etc/kubernetes/pki/etcd/healthcheck-client.crt
/etc/kubernetes/pki/etcd/healthcheck-client.key
/etc/kubernetes/pki/etcd/peer.crt
/etc/kubernetes/pki/etcd/peer.key
/etc/kubernetes/pki/etcd/server.crt
/etc/kubernetes/pki/etcd/server.key
```

Client (master and worker nodes):

```text
/var/lib/kubelet/pki/kubelet-client-2021-09-07-17-06-36.pem
/var/lib/kubelet/pki/kubelet-client-current.pem
/var/lib/kubelet/pki/kubelet.crt
/var/lib/kubelet/pki/kubelet.key
```

## Check Certificates

1. Log into a master node.

1. Check the expiration of the certificates.

    ```bash
    kubeadm certs check-expiration --config /etc/kubernetes/kubeadmcfg.yaml
    ```

    Example output:

    ```text
    WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]

    CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
    admin.conf                 Sep 24, 2021 15:21 UTC   14d                                     no
    apiserver                  Sep 24, 2021 15:21 UTC   14d             ca                      no
    apiserver-etcd-client      Sep 24, 2021 15:20 UTC   14d             ca                      no
    apiserver-kubelet-client   Sep 24, 2021 15:21 UTC   14d             ca                      no
    controller-manager.conf    Sep 24, 2021 15:21 UTC   14d                                     no
    etcd-healthcheck-client    Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
    etcd-peer                  Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
    etcd-server                Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
    front-proxy-client         Sep 24, 2021 15:21 UTC   14d             front-proxy-ca          no
    scheduler.conf             Sep 24, 2021 15:21 UTC   14d                                     no

    CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
    ca                      Sep 02, 2030 15:21 UTC   8y              no
    etcd-ca                 Sep 02, 2030 15:19 UTC   8y              no
    front-proxy-ca          Sep 02, 2030 15:21 UTC   8y              no
    ```

## Backup Existing Certificates

1. Backup existing certificates on master nodes:

    ```bash
    pdsh -w ncn-m00[1-3] tar cvf /root/cert_backup.tar /etc/kubernetes/pki/ /var/lib/kubelet/pki/
    ```

    Example output:

    ```text
    ncn-m001: tar: Removing leading / from member names
    ncn-m001: /etc/kubernetes/pki/
    ncn-m001: /etc/kubernetes/pki/front-proxy-client.key
    ncn-m001: tar: Removing leading / from hard link targets
    ncn-m001: /etc/kubernetes/pki/apiserver-etcd-client.key
    ncn-m001: /etc/kubernetes/pki/sa.key

    [...]
    ```

1. Backup existing certificates on worker nodes:

    **IMPORTANT:** The range of nodes below should reflect the size of the environment. This should run on every worker node.

    ```bash
    pdsh -w ncn-w00[1-3] tar cvf /root/cert_backup.tar /var/lib/kubelet/pki/
    ```

    Example output:

    ```text
    ncn-w003: tar: Removing leading / from member names
    ncn-w003: /var/lib/kubelet/pki/
    ncn-w003: /var/lib/kubelet/pki/kubelet.key
    ncn-w003: /var/lib/kubelet/pki/kubelet-client-2021-09-07-17-06-36.pem
    ncn-w003: /var/lib/kubelet/pki/kubelet.crt

    [...]
    ```

## Renew All Certificates

Run the following steps on each master node.

1. Renew the certificates.

    ```bash
    kubeadm certs renew all --config /etc/kubernetes/kubeadmcfg.yaml
    ```

    Example output:

    ```text
    WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
    certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
    certificate for serving the Kubernetes API renewed
    certificate the apiserver uses to access etcd renewed
    certificate for the API server to connect to kubelet renewed
    certificate embedded in the kubeconfig file for the controller manager to use renewed
    certificate for liveness probes to healthcheck etcd renewed
    certificate for etcd nodes to communicate with each other renewed
    certificate for serving etcd renewed
    certificate for the front proxy client renewed
    certificate embedded in the kubeconfig file for the scheduler manager to use renewed
    ```

1. Check the new expiration.

    ```bash
    kubeadm certs check-expiration --config /etc/kubernetes/kubeadmcfg.yaml
    ```

    Example output:

    ```text
    WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
    CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
    admin.conf                 Sep 22, 2022 17:13 UTC   364d                                    no
    apiserver                  Sep 22, 2022 17:13 UTC   364d            ca                      no
    apiserver-etcd-client      Sep 22, 2022 17:13 UTC   364d            etcd-ca                 no
    apiserver-kubelet-client   Sep 22, 2022 17:13 UTC   364d            ca                      no
    controller-manager.conf    Sep 22, 2022 17:13 UTC   364d                                    no
    etcd-healthcheck-client    Sep 22, 2022 17:13 UTC   364d            etcd-ca                 no
    etcd-peer                  Sep 22, 2022 17:13 UTC   364d            etcd-ca                 no
    etcd-server                Sep 22, 2022 17:13 UTC   364d            etcd-ca                 no
    front-proxy-client         Sep 22, 2022 17:13 UTC   364d            front-proxy-ca          no
    scheduler.conf             Sep 22, 2022 17:13 UTC   364d                                    no

    CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
    ca                      Sep 02, 2030 15:21 UTC   8y              no
    etcd-ca                 Sep 02, 2030 15:19 UTC   8y              no
    front-proxy-ca          Sep 02, 2030 15:21 UTC   8y              no
    ```

1. Check to see if only some of the certificates were updated.

    ```bash
    ls -l /etc/kubernetes/pki
    ```

    Example output:

    ```text
    -rw-r--r-- 1 root root 1249 Sep 22 17:13 apiserver.crt
    -rw-r--r-- 1 root root 1090 Sep 22 17:13 apiserver-etcd-client.crt
    -rw------- 1 root root 1675 Sep 22 17:13 apiserver-etcd-client.key
    -rw------- 1 root root 1679 Sep 22 17:13 apiserver.key
    -rw-r--r-- 1 root root 1099 Sep 22 17:13 apiserver-kubelet-client.crt
    -rw------- 1 root root 1679 Sep 22 17:13 apiserver-kubelet-client.key
    -rw------- 1 root root 1025 Sep 21 20:50 ca.crt
    -rw------- 1 root root 1679 Sep 21 20:50 ca.key
    drwxr-xr-x 2 root root  162 Sep 21 20:50 etcd
    -rw------- 1 root root 1038 Sep 21 20:50 front-proxy-ca.crt
    -rw------- 1 root root 1679 Sep 21 20:50 front-proxy-ca.key
    -rw-r--r-- 1 root root 1058 Sep 22 17:13 front-proxy-client.crt
    -rw------- 1 root root 1675 Sep 22 17:13 front-proxy-client.key
    -rw------- 1 root root 1675 Sep 21 20:50 sa.key
    -rw------- 1 root root  451 Sep 21 20:50 sa.pub
    ```

    ```bash
    ls -l /etc/kubernetes/pki/etcd
    ```

    Example output:

    ```text
    -rw-r--r-- 1 root root 1017 Sep 21 20:50 ca.crt
    -rw-r--r-- 1 root root 1675 Sep 21 20:50 ca.key
    -rw-r--r-- 1 root root 1094 Sep 22 17:13 healthcheck-client.crt
    -rw------- 1 root root 1679 Sep 22 17:13 healthcheck-client.key
    -rw-r--r-- 1 root root 1139 Sep 22 17:13 peer.crt
    -rw------- 1 root root 1679 Sep 22 17:13 peer.key
    -rw-r--r-- 1 root root 1139 Sep 22 17:13 server.crt
    -rw------- 1 root root 1675 Sep 22 17:13 server.key
    ```

   Not all the certificate files were updated in this example.

   **IMPORTANT:** Some certificates were not updated because they have a distant expiration time and did not need to be updated. **This is expected.**

      Certificates most likely to not be updated due to a distant expiration:

      ```bash
      CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
      ca                      Sep 02, 2030 15:21 UTC   8y              no
      etcd-ca                 Sep 02, 2030 15:19 UTC   8y              no
      front-proxy-ca          Sep 02, 2030 15:21 UTC   8y              no
      ```

      This means we can ignore the fact that our `ca.crt/key, front-proxy-ca.crt/key, and etcd ca.crt/key were not updated.`

1. Check the expiration of the certificates files that do not have a current date and are of the `.crt` or `.pem` format. See [File Locations](#file-locations) for the list of files.

   ***This task is for each master node and below example checks each certificate in [File Locations](#file-locations).***

   ```bash
   for i in $(ls /etc/kubernetes/pki/*.crt;ls /etc/kubernetes/pki/etcd/*.crt;ls /var/lib/kubelet/pki/*.crt;ls /var/lib/kubelet/pki/*.pem);do echo ${i}; openssl x509 -enddate -noout -in ${i};done
   ```

   Example output:

   ```text
   /etc/kubernetes/pki/apiserver.crt
   notAfter=Sep 22 17:13:28 2022 GMT
   /etc/kubernetes/pki/apiserver-etcd-client.crt
   notAfter=Sep 22 17:13:28 2022 GMT
   /etc/kubernetes/pki/apiserver-kubelet-client.crt
   notAfter=Sep 22 17:13:28 2022 GMT
   /etc/kubernetes/pki/ca.crt
   notAfter=Sep  4 09:31:10 2031 GMT
   /etc/kubernetes/pki/front-proxy-ca.crt
   notAfter=Sep  4 09:31:11 2031 GMT
   /etc/kubernetes/pki/front-proxy-client.crt
   notAfter=Sep 22 17:13:29 2022 GMT
   /etc/kubernetes/pki/etcd/ca.crt
   notAfter=Sep  4 09:30:28 2031 GMT
   /etc/kubernetes/pki/etcd/healthcheck-client.crt
   notAfter=Sep 22 17:13:29 2022 GMT
   /etc/kubernetes/pki/etcd/peer.crt
   notAfter=Sep 22 17:13:29 2022 GMT
   /etc/kubernetes/pki/etcd/server.crt
   notAfter=Sep 22 17:13:29 2022 GMT
   /var/lib/kubelet/pki/kubelet.crt
   notAfter=Sep 21 19:50:16 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-2021-09-07-17-06-36.pem
   notAfter=Sep  4 17:01:38 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-current.pem
   notAfter=Sep  4 17:01:38 2022 GMT
   ```

   **IMPORTANT:** Do **NOT** forget to verify certificates in `/etc/kubernetes/pki/etcd`.
   - As noted in the above output, all certificates including those for Etcd were updated. Note that `apiserver-etcd-client.crt` is critical as it is the cert that allows the Kubernetes API server to talk to the bare-metal etcd cluster.
     Also, the `/var/lib/kubelet/pki/` certificates will be updated in the Kubernetes client section that follows.

1. Restart `etcd`.

   Once the steps to renew the needed certificates have been completed on all the master nodes, log into each master node one at a time and run the following:

   ```bash
   systemctl restart etcd.service
   ```

**Run the remaining steps on both master and worker nodes.**

1. Restart `kubelet`.

   Run the following command on each Kubernetes node.

   **IMPORTANT:** The following example will need to be adjusted to reflect the correct amount of master and worker nodes in the environment being used.

   ```bash
   pdsh -w ncn-m00[1-3] -w ncn-w00[1-3] systemctl restart kubelet.service
   ```

1. Fix `kubectl` command access.

   **`NOTE`** The following command will only respond with `Unauthorized` if certificates have expired. In any case, the new client certificates will need to be distributed in the following steps.

   1. View the status of the nodes.

      ```bash
      kubectl get nodes
      ```

      The following is returned if certificates have expired:

      ```text
      error: You must be logged in to the server (Unauthorized)
      ```

   1. Copy `/etc/kubernetes/admin.conf` to `/root/.kube/config`.

      ```bash
      cp /etc/kubernetes/admin.conf /root/.kube/config
      ```

   1. Check the status of the nodes again.

      ```bash
      kubectl get nodes
      ```

      Example output:

      ```text
      NAME       STATUS   ROLES    AGE    VERSION
      ncn-m001   Ready    master   370d   v1.18.6
      ncn-m002   Ready    master   370d   v1.18.6
      ncn-m003   Ready    master   370d   v1.18.6
      ncn-w001   Ready    <none>   370d   v1.18.6
      ncn-w002   Ready    <none>   370d   v1.18.6
      ncn-w003   Ready    <none>   370d   v1.18.6
      ```

1. Distribute the client certificate to the rest of the cluster.

   **`NOTE`** There may be errors when copying files. The target may or may not exist depending on the version of CSM.

   - **DO NOT** copy this to the master node where this work is being performed.
   - Copy `/etc/kubernetes/admin.conf` to all master and worker nodes.

   Client access:

   **`NOTE`** Update the following command with the appropriate range of worker nodes.

   ```bash
   pdcp -w ncn-m00[2-3] -w ncn-w00[1-3] /etc/kubernetes/admin.conf /etc/kubernetes/
   ```

### Regenerate `kubelet` `.pem` Certificates

1. Backup certificates for `kubelet` on each master and worker node:

   **IMPORTANT:** The following example will need to be adjusted to reflect the correct number of master and worker nodes in the environment being used.

   ```bash
   pdsh -w ncn-m00[1-3] -w ncn-w00[1-3] tar cvf \
               /root/kubelet_certs.tar /etc/kubernetes/kubelet.conf /var/lib/kubelet/pki/
   ```

2. Log into the master node where the other certificates were updated.

   1. Get the current `apiserver-advertise-address`.

      ```bash
      kubectl config view|grep server
      ```

      Example output:

      ```text
      server: https://10.252.120.2:6442
      ```

   1. Generate a new `kubelet.conf` file in the `/root/` directory with the IP address from the previous command.

      **`NOTE`** The `apiserver-advertise-address` may vary, so do not copy and paste without verifying.

      ```bash
      for node in $(kubectl get nodes -o json|jq -r '.items[].metadata.name'); do kubeadm alpha kubeconfig user --org system:nodes \
                               --client-name system:node:$node --apiserver-advertise-address 10.252.120.2 --apiserver-bind-port 6442 > /root/$node.kubelet.conf; done
      ```

      There should be a new `kubelet.conf` file per node running Kubernetes.

3. Copy each file to the corresponding node shown in the filename.

   **`NOTE`** Update the below command with the appropriate number of master and worker nodes.

   ```bash
   for node in ncn-m00{1..3} ncn-w00{1..3}; do scp /root/$node.kubelet.conf $node:/etc/kubernetes/; done
   ```

4. Log into each node one at a time and run the following commands:

   ```bash
   systemctl stop kubelet.service &&
        rm -v /etc/kubernetes/kubelet.conf /var/lib/kubelet/pki/* &&
        cp -v /etc/kubernetes/$(hostname -s).kubelet.conf /etc/kubernetes/kubelet.conf &&
        systemctl start kubelet.service && 
        kubeadm init phase kubelet-finalize all --cert-dir /var/lib/kubelet/pki/ && echo OK
   ```

5. Check the expiration of the `kubectl` certificate files. See [File Locations](#file-locations) for the list of files.

   **This task is for each master and worker node. The example checks each `kubelet` certificate in [File Locations](#file-locations).**

   ```bash
   for i in $(ls /var/lib/kubelet/pki/*.crt;ls /var/lib/kubelet/pki/*.pem);do echo ${i}; openssl x509 -enddate -noout -in ${i};done
   ```

   Example output:

   ```text
   /var/lib/kubelet/pki/kubelet.crt
   notAfter=Sep 22 17:37:30 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-2021-09-22-18-37-30.pem
   notAfter=Sep 22 18:32:30 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-current.pem
   notAfter=Sep 22 18:32:30 2022 GMT
   ```

6. Perform a rolling reboot of master nodes.

   Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) process.

   **IMPORTANT:** Verify pods are running on the master node that was rebooted before proceeding to the next node.

7. Perform a rolling reboot of worker nodes.

   Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) process.

## Renew Etcd Certificate

If [Check Certificates](#check-certificates) indicates that only the `apiserver-etcd-client` need to be renewed, then the following can be used to renew just that one certificate.
The full [Renew All Certificates](#renew-all-certificates) procedure will also renew this certificate.

Run the following steps on each master node.

1. Renew the Etcd certificate.

    ```bash
    kubeadm certs renew apiserver-etcd-client --config /etc/kubernetes/kubeadmcfg.yaml
    systemctl restart etcd.service
    systemctl restart kubelet.service
    ```

## Update Client Secrets

The client secrets can be updated independently from the Kubernetes certs.

Run the following steps from a master node.

1. Update the client certificate for `kube-etcdbackup`.

   1. Update the `kube-etcdbackup-etcd` secret.

      ```bash
      kubectl --namespace=kube-system create secret generic kube-etcdbackup-etcd \
                     --from-file=/etc/kubernetes/pki/etcd/ca.crt \
                     --from-file=tls.crt=/etc/kubernetes/pki/etcd/server.crt \
                     --from-file=tls.key=/etc/kubernetes/pki/etcd/server.key \
                     --save-config --dry-run=client -o yaml | kubectl apply -f -
      ```

   1. Check the certificate's expiration date to verify that the certificate is not expired.

      ```bash
      kubectl get secret -n kube-system kube-etcdbackup-etcd -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
      ```

      Example output:

      ```text
      notAfter=May  4 22:37:16 2023 GMT
      ```

   1. Check that the next `kube-etcdbackup` cronjob `Completed`. This cronjob runs every 10 minutes.

      ```bash
      kubectl get pod -l app.kubernetes.io/instance=cray-baremetal-etcd-backup -n kube-system
      ```

      Example output:

      ```text
      NAME                               READY   STATUS      RESTARTS   AGE
      kube-etcdbackup-1652201400-czh5p   0/1     Completed   0          107s
      ```

1. Update the client certificate for `etcd-client`.

   1. Update the `etcd-client-cert` secret.

      ```bash
      kubectl --namespace=sysmgmt-health create secret generic etcd-client-cert \
                     --from-file=etcd-client=/etc/kubernetes/pki/apiserver-etcd-client.crt \
                     --from-file=etcd-client-key=/etc/kubernetes/pki/apiserver-etcd-client.key \
                     --from-file=etcd-ca=/etc/kubernetes/pki/etcd/ca.crt \
                     --save-config --dry-run=client -o yaml | kubectl apply -f -
      ```

   1. Check the certificates' expiration dates to verify that none of the certificate are expired.

      1. Check the `etcd-ca` expiration date.

         ```bash
         kubectl get secret -n sysmgmt-health etcd-client-cert -o json | jq -r '.data."etcd-ca" | @base64d' | openssl x509 -noout -enddate
         ```

         Example output:

         ```text
         notAfter=May  1 18:20:23 2032 GMT
         ```

      1. Check the `etcd-client` expiration date.

         ```bash
         kubectl get secret -n sysmgmt-health etcd-client-cert -o json | jq -r '.data."etcd-client" | @base64d' | openssl x509 -noout -enddate
         ```

         Example output:

         ```text
         notAfter=May  4 18:20:24 2023 GMT
         ```

   1. Restart Prometheus.

      ```bash
      kubectl rollout restart -n sysmgmt-health statefulSet/prometheus-cray-sysmgmt-health-promet-prometheus
      kubectl rollout status -n sysmgmt-health statefulSet/prometheus-cray-sysmgmt-health-promet-prometheus
      ```

      Example output:

      ```text
      Waiting for 1 pods to be ready...
      statefulset rolling update complete ...
      ```

   1. Check for any `tls` errors from the active Prometheus targets. No errors are expected.

      ```bash
      PROM_IP=$(kubectl get services -n sysmgmt-health cray-sysmgmt-health-promet-prometheus -o json | jq -r '.spec.clusterIP')
      curl -s http://${PROM_IP}:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(."scrapePool" == "sysmgmt-health/cray-sysmgmt-health-promet-kube-etcd/0")' | grep lastError | sort -u
      ```

      Example output:

      ```text
        "lastError": "",
      ```
