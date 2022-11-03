# Kubernetes and Bare Metal EtcD Certificate Renewal

## Scope

As part of the installation, Kubernetes generates certificates for the required subcomponents. This document will help walk through the process of renewing the certificates.

**`IMPORTANT:`** Depending on the version of Kubernetes, the command may or may not reside under the alpha category. Use `kubectl certs --help` and `kubectl alpha certs --help` to determine this. The overall command syntax should be the same and this is just whether or not the command structure will require `alpha` in it.

**`IMPORTANT:`** When you pick your master node to renew the certificatess on, that is the node that will be referenced in this document as `ncn-m`.

**`IMPORTANT:`** This document is based off a base hardware configuration of 3 masters and 3 workers (We are leaving off utility storage since they are not running Kubernetes). Please make sure to update any commands that run on multiple nodes accordingly.

## File locations

**`IMPORTANT:`** Master nodes will have certificates for both Kubernetes services and the Kubernetes client. Workers will only have the certificates for the Kubernetes client.

Services (master nodes):

```
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

```
/var/lib/kubelet/pki/kubelet-client-2021-09-07-17-06-36.pem
/var/lib/kubelet/pki/kubelet-client-current.pem
/var/lib/kubelet/pki/kubelet.crt
/var/lib/kubelet/pki/kubelet.key
```

## Procedure

Check the expiration of the certificates.

1. Log into a master node and run the following:

    ```bash
    ncn-m# kubeadm alpha certs check-expiration --config /etc/kubernetes/kubeadmcfg.yaml
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

### Backing up existing certificates

1. Backup existing certificates.

    Master Nodes:

    ```bash
    ncn-m# pdsh -w ncn-m00[1-3] tar cvf /root/cert_backup.tar /etc/kubernetes/pki/ /var/lib/kubelet/pki/
    ncn-m001: tar: Removing leading / from member names
    ncn-m001: /etc/kubernetes/pki/
    ncn-m001: /etc/kubernetes/pki/front-proxy-client.key
    ncn-m001: tar: Removing leading / from hard link targets
    ncn-m001: /etc/kubernetes/pki/apiserver-etcd-client.key
    ncn-m001: /etc/kubernetes/pki/sa.key
    .
    .
    ..  shortened output
    ```

    Worker Nodes:

    **`IMPORTANT:`** The range of nodes below should reflect the size of the environment. This should run on every worker node.

    ```bash
    ncn-m# pdsh -w ncn-w00[1-3] tar cvf /root/cert_backup.tar /var/lib/kubelet/pki/
    ncn-w003: tar: Removing leading / from member names
    ncn-w003: /var/lib/kubelet/pki/
    ncn-w003: /var/lib/kubelet/pki/kubelet.key
    ncn-w003: /var/lib/kubelet/pki/kubelet-client-2021-09-07-17-06-36.pem
    ncn-w003: /var/lib/kubelet/pki/kubelet.crt
    .
    .
    ..  shortened output
    ```

### Renewing Certificates

#### On each master node

1. Renew the Certificates.

    ```bash
    ncn-m# kubeadm alpha certs renew all --config /etc/kubernetes/kubeadmcfg.yaml
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
    ncn-m# kubeadm alpha certs check-expiration --config /etc/kubernetes/kubeadmcfg.yaml
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

1. This command may have only updated some certificates.

    ```bash
    ncn-m# ncn-m001:~ # ls -l /etc/kubernetes/pki
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

    ncn-m# ls -l /etc/kubernetes/pki/etcd
    -rw-r--r-- 1 root root 1017 Sep 21 20:50 ca.crt
    -rw-r--r-- 1 root root 1675 Sep 21 20:50 ca.key
    -rw-r--r-- 1 root root 1094 Sep 22 17:13 healthcheck-client.crt
    -rw------- 1 root root 1679 Sep 22 17:13 healthcheck-client.key
    -rw-r--r-- 1 root root 1139 Sep 22 17:13 peer.crt
    -rw------- 1 root root 1679 Sep 22 17:13 peer.key
    -rw-r--r-- 1 root root 1139 Sep 22 17:13 server.crt
    -rw------- 1 root root 1675 Sep 22 17:13 server.key
    ```

   As we can see not all the certificate files were updated.

   `IMPORTANT:` Some certificates were not updated because they have a distant expiration time and did not need to be updated. ***This is expected.***

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

   **`IMPORTANT:`** DO NOT forget to verify certificates in /etc/kubernetes/pki/etcd.
   - As noted in our above output all certificates including those for etcd were updated. Please note `apiserver-etcd-client.crt` is a Kubernetes api cert not an etcd only cert. Also the `/var/lib/kubelet/pki/` certificates will be updated in the Kubernetes client section that follows.

1. Restart etcd.

   Once the steps to renew the needed certs have been completed on all the master nodes, then log into each master node one at a time and do:

   ```bash
   ncn-m# systemctl restart etcd.service
   ```

#### On master and worker nodes

1. Restart kubelet.

   On each Kubernetes node do:

   **`IMPORTANT:`** The below example will need to be adjusted to reflect the correct amount of master and worker nodes in your environment.

   ```bash
   ncn-m# pdsh -w ncn-m00[1-3] -w ncn-w00[1-3] systemctl restart kubelet.service
   ```

2. Fix kubectl command access.

   `NOTE:` Only if your certificates have expired will the following command respond with Unauthorized. In any case, the new client certificates will need to be distributed in the following steps.

   ```bash
   ncn-m# kubectl get nodes
   error: You must be logged in to the server (Unauthorized)
   ncn-m# cp /etc/kubernetes/admin.conf /root/.kube/config
   ncn-m#  # kubectl get nodes
   NAME       STATUS   ROLES    AGE    VERSION
   ncn-m001   Ready    master   370d   v1.18.6
   ncn-m002   Ready    master   370d   v1.18.6
   ncn-m003   Ready    master   370d   v1.18.6
   ncn-w001   Ready    <none>   370d   v1.18.6
   ncn-w002   Ready    <none>   370d   v1.18.6
   ncn-w003   Ready    <none>   370d   v1.18.6
   ```

3. Distribute the client certificate to the rest of the cluster.

   `NOTE:` You may have errors copying files. The target may or may not exist depending on the version of Shasta.
  
   - You `DO NOT` need to copy this to the master node where you are performing this work.
   - Shasta v1.3 and earlier copy /root/.kube/config to all master nodes and ncn-w001.
   - Shasta v1.4 and later copy `/etc/kubernetes/admin.conf` to all master and worker nodes.

   If you attempt to copy to workers nodes other than `ncn-w001` in a Shasta v1.3 or earlier system you will see this error `pdcp@ncn-m001: ncn-w003: fatal: /root/.kube/: Is a directory` and this is expected and can be ignored.

   Client access:

   **`NOTE:`** Please update the below command with the appropriate amount of worker nodes.

   For Shasta v1.4 and later :

   ```
   ncn-m# pdcp -w ncn-m00[2-3] -w ncn-w00[1-3] /etc/kubernetes/admin.conf /etc/kubernetes/
   ```

   For Shasta v1.3 and earlier :

   ```bash
   ncn-m# pdcp -w ncn-m00[2-3] -w ncn-w001 /root/.kube/config /root/.kube/
   ```

## Regenerating kubelet .pem certificates


1. Backup certificates for `kubelet` on each master and worker node:

   **`IMPORTANT:`** The below example will need to be adjusted to reflect the correct amount of master and worker nodes in your environment.

   ```bash
   ncn-m# pdsh -w ncn-m00[1-3] -w ncn-w00[1-3] tar cvf /root/kubelet_certs.tar /etc/kubernetes/kubelet.conf /var/lib/kubelet/pki/
   ```

2. On the master node where you updated the other certificates do:

   Get your current `apiserver-advertise-address`.

   ```bash
   ncn# kubectl config view|grep server
    server: https://10.252.120.2:6442
   ```

   Using the IP address from the above output do:
   - The `apiserver-advertise-address` may vary, so make sure you are not copy and pasting without verifying.

   ```bash
   ncn-m# for node in $(kubectl get nodes -o json|jq -r '.items[].metadata.name'); do kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:$node --apiserver-advertise-address 10.252.120.2 --apiserver-bind-port 6442 > /root/$node.kubelet.conf; done
   ```

   This will generate a new `kubelet.conf` file in the `/root/` directory. There should be a new file per node running Kubernetes.

3. Copy each file to the corresponding node shown in the filename.

   **`NOTE:`** Please update the below command with the appropriate amount of master and worker nodes.

   ```bash
   ncn-m# for node in ncn-m00{1..3} ncn-w00{1..3}; do scp /root/$node.kubelet.conf $node:/etc/kubernetes/; done
   ```

4. Log into each node one at a time and do the following.

   1. systemctl stop kubelet.service
   2. rm /etc/kubernetes/kubelet.conf
   3. rm /var/lib/kubelet/pki/*
   4. cp /etc/kubernetes/`<node>`.kubelet.conf /etc/kubernetes/kubelet.conf
   5. systemctl start kubelet.service
   6. kubeadm init phase kubelet-finalize all --cert-dir /var/lib/kubelet/pki/

5. Check the expiration of the kubectl certificates files. See [File Locations](#file-locations) for the list of files.

   ***This task is for each master and worker node. The example checks each kubelet certificate in [File Locations](#file-locations).***

   ```bash
   for i in $(ls /var/lib/kubelet/pki/*.crt;ls /var/lib/kubelet/pki/*.pem);do echo ${i}; openssl x509 -enddate -noout -in ${i};done

   /var/lib/kubelet/pki/kubelet.crt
   notAfter=Sep 22 17:37:30 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-2021-09-22-18-37-30.pem
   notAfter=Sep 22 18:32:30 2022 GMT
   /var/lib/kubelet/pki/kubelet-client-current.pem
   notAfter=Sep 22 18:32:30 2022 GMT
   ```

6. Perform a rolling reboot of master nodes.

   For Shasta v1.4 and later :

   1. Follow the [Reboot_NCNs](../node_management/Reboot_NCNs.md) process.

   For Shasta v1.3 and earlier :

   1. Follow the [Reboot_NCNs](https://github.com/Cray-HPE/docs-csm/blob/release/0.9/operations/node_management/Reboot_NCNs.md) process.

       **NOTES:**
       - ncn-w001 is the externally connected node. On Shasta v1.4 and later, ncn-m001 is the externally connected node.
       - The ncnGetXnames.sh script is not available; The xname can be found in the file `/etc/cray/xname` on the specific node.

   **IMPORTANT:** Please ensure you are verifying pods are running on the master node that was rebooted before proceeding to the next node.

7. Perform a rolling reboot of worker nodes.

   For Shasta v1.4 and later :
   1. Follow the [Reboot_NCNs](../node_management/Reboot_NCNs.md) process.

   For Shasta v1.3 and earlier :

   1. Before rebooting any worker node, scale nexus replicas to 0.
        
      ```bash
      ncn-m# kubectl scale deployment nexus -n nexus --replicas=0
      ```

   2. Follow the [Reboot_NCNs](https://github.com/Cray-HPE/docs-csm/blob/release/0.9/operations/node_management/Reboot_NCNs.md) process.

       **NOTES:**
       - ncn-w001 is the externally connected node. On Shasta v1.4 and later, ncn-m001 is the externally connected node.
       - The failover-leader.sh, ncnGetXnames.sh and add_pod_priority.sh scripts are not available or required when rebooting worker nodes.
       - After draining a worker, force delete any pod that fails to terminate due to `Cannot evict pod as it would violate the pod's disruption budget`.
         
         ```bash
         ncn-m# kubectl delete pod <pod-name> -n <namespace> --force
         ```

       - Reference the Shasta v1.3 Admin Guide for any steps related to checking system health.

   3. After rebooting all the worker nodes, scale nexus replicas back to 1 and verify nexus is running.
        
      ```bash
      ncn-m# kubectl scale deployment nexus -n nexus --replicas=1

       ncn-m# kubectl get pods -n nexus | grep nexus
       nexus-868d7b8466-gjnps       2/2     Running   0          5m
      ```

8. For Shasta v1.3 and earlier, restart the sonar cronjobs and verify vault etcd is healthy.

   1. Restart the sonar cronjobs.

      ```bash
      ncn-m# kubectl -n services get cronjob sonar-jobs-watcher -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' | kubectl replace --force -f -

      ncn-m# kubectl -n services get cronjob sonar-sync -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' | kubectl replace --force -f -
      ```

   2. After at least a minute, verify that the cronjobs have been scheduled.

      ```bash
      ncn-m# # kubectl get cronjobs -n services sonar-jobs-watcher
      NAME                 SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
      sonar-jobs-watcher   */1 * * * *   False     1        23s             5m10s

      ncn-m# kubectl get cronjobs -n services sonar-sync
      NAME         SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
      sonar-sync   */1 * * * *   False     1        32s             5m15s
      ```

   3. Check the health of vault etcd.
 
      ```bash
      ncn-m# for pod in $(kubectl get pods -l app=etcd -n vault -o jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} ###"; kubectl -n vault exec $pod  -- /bin/sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/etcdtls/operator/etcd-tls/etcd-client-ca.crt --cert /etc/etcdtls/operator/etcd-tls/etcd-client.crt --key /etc/etcdtls/operator/etcd-tls/etcd-client.key --endpoints https://localhost:2379 endpoint health"; done
      ```

   4. If the above health of vault etcd reports any pods as `unhealthy`, backup the secret, delete the secret. The operator will create a new secret.

      ```bash
      ncn-m# kubectl get secret -n vault cray-vault-etcd-tls -o yaml > /root/vault_sec.yaml
      ncn-m# kubectl delete secret -n vault cray-vault-etcd-tls
      ```
 
   5. Once the new secret has been created and the cray-vault-etcd pods are running, verify the health of vault etcd.

      ```bash
      ncn-m# kubectl get secret -n vault cray-vault-etcd-tls
    
      NAME                  TYPE     DATA   AGE
      cray-vault-etcd-tls   Opaque   9      5m
    
      ncn-m# kubectl get pods -l app=etcd -n vault
    
      NAME                         READY   STATUS    RESTARTS   AGE
      cray-vault-etcd-stzjf6dqd5   1/1     Running   0          10m
      cray-vault-etcd-ws59fgssxt   1/1     Running   0          10m
      cray-vault-etcd-xmvfxz48vs   1/1     Running   0          10m
    
      ncn-m# for pod in $(kubectl get pods -l app=etcd -n vault -o jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} ###"; kubectl -n vault exec $pod  -- /bin/sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/etcdtls/operator/etcd-tls/etcd-client-ca.crt --cert /etc/etcdtls/operator/etcd-tls/etcd-client.crt --key /etc/etcdtls/operator/etcd-tls/etcd-client.key --endpoints https://localhost:2379 endpoint health"; done

      ### cray-vault-etcd-stzjf6dqd5 ###
      https://localhost:2379 is healthy: successfully committed proposal: took = 19.999618ms
      ### cray-vault-etcd-ws59fgssxt ###
      https://localhost:2379 is healthy: successfully committed proposal: took = 19.597736ms
      ### cray-vault-etcd-xmvfxz48vs ###
      https://localhost:2379 is healthy: successfully committed proposal: took = 19.81056ms
      ```

      **NOTE:**

      Vault etcd errors such as `tls: bad certificate." Reconnecting` can be ignored.

      ```bash
      ncn-m# kubectl logs -l app=etcd -n vault  | grep "bad certificate\". Reconnecting"

      WARNING: 2021/09/24 17:35:11 grpc: addrConn.createTransport failed to connect to {0.0.0.0:2379 0  <nil>}. Err :connection error: desc = "transport: authentication handshake failed: remote error: tls: bad certificate". Reconnecting...
      ```

## Update client secrets

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
