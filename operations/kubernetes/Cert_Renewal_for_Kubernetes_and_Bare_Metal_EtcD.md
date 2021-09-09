# Kubernetes and Bare Metal EtcD Certificate Renewal

## Scope

As part of the installation, Kubernetes generates certificates for the required subcomponents.  This Document will help walk thru the process of renewing the certificates.

**`IMPORTANT:`** Depending on the version of Kubernetes, the command may or may not reside under the alpha category.  Use `kubectl certs --help` and `kubectl alpha certs --help` to determine this.  The overall command syntax should be the same and this is just whether or not the command structure will require `alpha` in it.

**`IMPORTANT:`** When you pick your master node to renew the certs on, then that is the node that will be referenced in this document as `ncn-m`.

## File locations:

**`IMPORTANT:`** Master nodes will have certificates for both Kubernetes services and the Kubernetes client.  Workers will only have the certificates for the Kubernetes client.

Services:

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

Client:

```bash
/var/lib/kubelet/pki/kubelet-client-2020-09-04-14-44-04.pem
/var/lib/kubelet/pki/kubelet-client-2021-06-24-13-11-08.pem
/var/lib/kubelet/pki/kubelet-client-current.pem
/var/lib/kubelet/pki/kubelet.crt
/var/lib/kubelet/pki/kubelet.key
```
## Procedure

Check the expiration of the certificates

1. log into a master node and run the following:

    ```bash
    m001:~ # kubeadm alpha certs check-expiration
    [check-expiration] Reading configuration from the cluster...
    [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config     -oyaml'
    
    CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
    admin.conf                 Sep 24, 2021 15:21 UTC   14d                                     no
    apiserver                  Sep 24, 2021 15:21 UTC   14d             ca                      no
    apiserver-kubelet-client   Sep 24, 2021 15:21 UTC   14d             ca                      no
    controller-manager.conf    Sep 24, 2021 15:21 UTC   14d                                     no
    front-proxy-client         Sep 24, 2021 15:21 UTC   14d             front-proxy-ca          no
    scheduler.conf             Sep 24, 2021 15:21 UTC   14d                                     no
    
    CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
    ca                      Sep 02, 2030 14:43 UTC   8y              no
    front-proxy-ca          Sep 02, 2030 14:43 UTC   8y              no
    ```

1. Backup existing certificates

   Master Nodes:

   ```bash
   ncn-m# pdsh -w ncn-m00[1-3] tar cvf /root/cert_backup.tar /etc/kubernetes/pki/ /var/lib/kubelet/pki/
   ncn-m001: tar: Removing leading `/' from member names
   ncn-m001: /etc/kubernetes/pki/
   ncn-m001: /etc/kubernetes/pki/front-proxy-client.key
   ncn-m001: tar: Removing leading `/' from hard link targets
   ncn-m001: /etc/kubernetes/pki/apiserver-etcd-client.key
   ncn-m001: /etc/kubernetes/pki/sa.key
   .
   .
   ..  shortened output
   ```

   Worker Nodes:

   **`IMPORTANT:`** The range of nodes below should reflect the size of the environment.  This should run on ever worker node.

   ```bash
    # pdsh -w ncn-w00[1-3] tar cvf /root/cert_backup.tar /var/lib/kubelet/pki/
    ncn-w003: tar: Removing leading `/' from member names
    ncn-w003: /var/lib/kubelet/pki/
    ncn-w003: /var/lib/kubelet/pki/kubelet.key
    ncn-w003: /var/lib/kubelet/pki/kubelet-client-2021-05-31-23-50-02.pem
    ncn-w003: /var/lib/kubelet/pki/kubelet-client-2020-09-04-14-45-30.pem
    ncn-w003: /var/lib/kubelet/pki/kubelet.crt
    .
    .
    ..  shortened output
    ```

1. Renew the Certificates

   On each master node:

   ```bash
   # kubeadm alpha certs renew all
   [renew] Reading configuration from the cluster...
   [renew] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
   
   certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
   certificate for serving the Kubernetes API renewed
   certificate for the API server to connect to kubelet renewed
   certificate embedded in the kubeconfig file for the controller manager to use renewed
   certificate for the front proxy client renewed
   certificate embedded in the kubeconfig file for the scheduler manager to use renewed
   ```

1. Check the new expiration

   ```bash
   # kubeadm alpha certs check-expiration
   [check-expiration] Reading configuration from the cluster...
   [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config       -oyaml'
   
   CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
   admin.conf                 Sep 09, 2022 18:28 UTC   364d                                    no
   apiserver                  Sep 09, 2022 18:28 UTC   364d            ca                      no
   apiserver-kubelet-client   Sep 09, 2022 18:28 UTC   364d            ca                      no
   controller-manager.conf    Sep 09, 2022 18:28 UTC   364d                                    no
   front-proxy-client         Sep 09, 2022 18:28 UTC   364d            front-proxy-ca          no
   scheduler.conf             Sep 09, 2022 18:28 UTC   364d                                    no
   
   CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
   ca                      Sep 02, 2030 14:43 UTC   8y              no
   front-proxy-ca          Sep 02, 2030 14:43 UTC   8y              no
   ```

1. This command may have only updates some certificates.

   ```bash
   ncn-m#:~/etc/kubernetes/pki # ls -la
   total 168
   drwxr-xr-x 3 root root   4096 Sep  9 13:18 .
   drwxr-xr-x 3 root root   4096 Sep  9 13:59 ..
   -rw-r--r-- 1 root root   1387 Sep 24  2020 apiserver.crt
   -rw-r--r-- 1 root root   1090 Sep  4  2020 apiserver-etcd-client.crt
   -rw------- 1 root root   1675 Sep  4  2020 apiserver-etcd-client.key
   -rw------- 1 root root   1679 Sep 24  2020 apiserver.key
   -rw-r--r-- 1 root root   1099 Sep 24  2020 apiserver-kubelet-client.crt
   -rw------- 1 root root   1679 Sep 24  2020 apiserver-kubelet-client.key
   -rw-r--r-- 1 root root   1025 Sep  4  2020 ca.crt
   -rw------- 1 root root   1679 Sep  4  2020 ca.key
   -rw-r--r-- 1 root root 102400 Sep  9 13:18 cert_backup.tar
   drwxr-xr-x 2 root root   4096 Sep  4  2020 etcd
   -rw-r--r-- 1 root root   1038 Sep  4  2020 front-proxy-ca.crt
   -rw------- 1 root root   1675 Sep  4  2020 front-proxy-ca.key
   -rw-r--r-- 1 root root   1058 Sep 24  2020 front-proxy-client.crt
   -rw------- 1 root root   1679 Sep 24  2020 front-proxy-client.key
   -rw------- 1 root root   1675 Sep  4  2020 sa.key
   -rw------- 1 root root    451 Sep  4  2020 sa.pub
   ```

   As we can see not all the certificate files were updated.

   `IMPORTANT:` Some certificates were not updated because they have a distant expiration time.

    This will typically be certificates related to etcd:
     - apiserver-etcd-client.crt/key
     - healthcheck-client.crt/key
     - peer.crt/key
     - server.crt/key

      ```bash
      CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
      ca                      Sep 02, 2030 14:43 UTC   8y              no
      front-proxy-ca          Sep 02, 2030 14:43 UTC   8y              no
      ```

      This means we can ignore the fact that our `ca.crt/key, front-proxy-ca.crt/key can be ignored.`

1. Check the expiration of the certificates files that do not have a current date and are of the `.crt` or `.pem` format.

   Example:

   ```bash
   ncn-m # openssl x509 -enddate -noout -in apiserver-etcd-client.crt
   notAfter=Sep  4 14:42:48 2021 GMT
   ```

   **`IMPORTANT:`** DO NOT forget to verify certificates in /etc/kubernetes/pki/etcd

1. Update etcd certificates (if needed)

   On each master node do:

   ```bash
   kubeadm alpha certs renew etcd-server --config /etc/kubernetes/kubeadmcfg.yaml
   kubeadm alpha certs renew etcd-peer --config /etc/kubernetes/kubeadmcfg.yaml
   kubeadm alpha certs renew etcd-healthcheck-client --config /etc/kubernetes/kubeadmcfg.yaml
   kubeadm alpha certs renew apiserver-etcd-client --config /etc/kubernetes/kubeadmcfg.yaml
   ```

1. restart etcd

1. Restart kubelet on the node where the certificates were renewed.

1. Fix kubectl command access

   ```bash
   ncn-m# kubectl get pods
   error: You must be logged in to the server (Unauthorized)
   ncn-m# cp /etc/kubernetes/admin.conf config
   ncn-m#  # kubectl get nodes
   NAME       STATUS   ROLES    AGE    VERSION
   ncn-m001   Ready    master   370d   v1.18.6
   ncn-m002   Ready    master   370d   v1.18.6
   ncn-m003   Ready    master   370d   v1.18.6
   ncn-w001   Ready    <none>   370d   v1.18.6
   ncn-w002   Ready    <none>   370d   v1.18.6
   ncn-w003   Ready    <none>   370d   v1.18.6
   ```

2. Distribute the client certificate to the rest of the cluster

   `NOTE:` You may have errors copying files.  The target may or may not exist depending on the version of Shasta.  Any failures outside of the master nodes and worker 1 can either be ignored or investiaged.

   Client acces:

   ```bash
   ncn-m# pdcp -w ncn-m00[2-3] -w ncn-w00[1-3] config ~/.kube/
   pdcp@ncn-m001: ncn-w003: fatal: /root/.kube/: Is a directory
   pdcp@ncn-m001: ncn-w002: fatal: /root/.kube/: Is a directory
   ```
