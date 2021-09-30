# Kubernetes and Bare Metal EtcD Certificate Renewal

## Scope

As part of the installation, Kubernetes generates certificates for the required subcomponents. This Document will help walk thru the process of renewing the certificates.

<<<<<<< HEAD
**`IMPORTANT:`** Depending on the version of Kubernetes, the command may or may not reside under the alpha category. Use `kubectl certs --help` and `kubectl alpha certs --help` to determine this. The overall command syntax should be the same and this is just whether or not the command structure will require `alpha` in it.

**`IMPORTANT:`** When you pick your master node to renew the certs on, then that is the node that will be referenced in this document as `ncn-m`.

**`IMPORTANT:`** This document is based of a base hardware configuration of 3 masters and 3 workers (We are leaving off utility storage since they are not running kubernetes). Please make sure to update any commands that run on multiple nodes accordingly.  
=======
**`IMPORTANT:`** Depending on the version of Kubernetes, the command may or may not reside under the alpha category.  Use `kubectl certs --help` and `kubectl alpha certs --help` to determine this. The overall command syntax should be the same and this is just whether or not the command structure will require `alpha` in it.

**`IMPORTANT:`** When you pick your master node to renew the certs on, then that is the node that will be referenced in this document as `ncn-m`.

**`IMPORTANT:`** This document is based off a base hardware configuration of 3 masters and 3 workers (We are leaving off utility storage since they are not running kubernetes).  Please make sure to update any commands that run on multiple nodes accordingly.  
>>>>>>> 2f112768... CASMINST-3100 - update to the cert renewal process.

## File locations

**`IMPORTANT:`** Master nodes will have certificates for both Kubernetes services and the Kubernetes client. Workers will only have the certificates for the Kubernetes client.

Services (master nodes):

```bash
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

```bash
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

<<<<<<< HEAD
   **`IMPORTANT:`** The range of nodes below should reflect the size of the environment. This should run on every worker node.
=======
    **`IMPORTANT:`** The range of nodes below should reflect the size of the environment.  This should run on every worker node.
>>>>>>> 2f112768... CASMINST-3100 - update to the cert renewal process.

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

<<<<<<< HEAD
   ***This task is for each master node and below is just a single example of checking one certificate. The below example checks each certificate in [File Locations](#file-locations).***
=======
   ***This task is for each master node and below example checks each certificate in [File Locations](#file-locations).***
>>>>>>> 2f112768... CASMINST-3100 - update to the cert renewal process.

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
<<<<<<< HEAD
   - As noted in our above output only non-etcd only certificates were updated. Please note `apiserver-etcd-client.crt` is a Kubernetes api cert not an etcd only cert.
=======
   - As noted in our above output all certificates including those for etcd were updated. Please note `apiserver-etcd-client.crt` is a Kubernetes api cert not an etcd only cert. Also the /var/lib/kubelet/pki/ certs will be updated in the Kubernetes client section that follows.
>>>>>>> 2f112768... CASMINST-3100 - update to the cert renewal process.

1. Restart etcd.

   Once the steps to renew the needed certs have been completed on all the master nodes, then log into each master node one at a time and do:

   ```bash
   ncn-m# systemctl restart etcd.service
   ```

#### On master and worker nodes

1. Restart kubelet.

   On each kubernetes node do:

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
   - Copy /etc/kubernetes/admin.conf to all master and worker nodes.

   Client access:

   **`NOTE:`** Please update the below command with the appropriate amount of worker nodes.

   ```
   ncn-m# pdcp -w ncn-m00[2-3] -w ncn-w00[1-3] /etc/kubernetes/admin.conf /etc/kubernetes/
   ```


## Regenerating kubelet .pem certificates


1. Backup certs for `kubelet` on each `master` and `worker` node:

   **`IMPORTANT:`** The below example will need to be adjusted to reflect the correct amount of master and worker nodes in your environment.

   ```bash
   ncn-m# pdsh -w ncn-m00[1-3] -w ncn-w00[1-3] tar cvf /root/kubelet_certs.tar /etc/kubernetes/kubelet.conf /var/lib/kubelet/pki/
   ```

2. On the master node where you updated the other certificates do:

   Get your current apiserver-advertise-address.

   ```bash
   ncn# kubectl config view|grep server
    server: https://10.252.120.2:6442
   ```

   Using the ip address from the above output do:
   - The apiserver-advertise-address may vary, so make sure you are not copy and pasting without verifying.

   ```bash
   ncn-m# for node in $(kubectl get nodes -o json|jq -r '.items[].metadata.name'); do kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:$node --apiserver-advertise-address 10.252.120.2 --apiserver-bind-port 6442 > /root/$node.kubelet.conf; done
   ```

   This will generate a new kubelet.conf file in the /root/ directory. There should be a new file per node running kubernetes.

3. Copy each file to the corresponding node shown in the filename. 

   **`NOTE:`** Please update the below command with the appropriate amount of master and worker nodes.

   ```bash
   ncn-m# for node in ncn-m00{1..3} ncn-w00{1..3}; do scp /root/$node.kubelet.conf $node:/etc/kubernetes/; done
   ```

<<<<<<< HEAD
1. Copy each file to the corresponding node shown in the filename. Below this is shown as `<target node>`
   1. scp `<target node>`.kubelet.conf `<target node>`:/etc/kubernetes/$node.kubelet.conf

1. Log into each node one at a time and do the following.
=======
4. Log into each node one at a time and do the following.
>>>>>>> 2f112768... CASMINST-3100 - update to the cert renewal process.

   1. systemctl stop kubelet.service
   2. rm /etc/kubernetes/kubelet.conf
   3. rm /var/lib/kubelet/pki/*
   4. cp /etc/kubernetes/`<node>`.kubelet.conf /etc/kubernetes/kubelet.conf
   5. systemctl start kubelet.service
   6. kubeadm init phase kubelet-finalize all --cert-dir /var/lib/kubelet/pki/

5. Check the expiration of the kubectl certificates files.  See [File Locations](#file-locations) for the list of files.

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

   1. Follow the [Reboot_NCNs](../node_management/Reboot_NCNs.md) process.

      **IMPORTANT:** Please ensure you are verifying pods are running on the master node that was rebooted before proceeding to the next node.

7. Perform a rolling reboot of worker nodes.

   1. Before rebooting any worker node, scale nexus replicas to 0.
        
   ```bash
   ncn-m# kubectl scale deployment nexus -n nexus --replicas=0
   ```

   2. Follow the [Reboot_NCNs](../node_management/Reboot_NCNs.md) process.

   3. After rebooting all the worker nodes, scale nexus replicas back to 1.
        
   ```bash
   ncn-m# kubectl scale deployment nexus -n nexus --replicas=1
   ```
