# NCN Operating System Releases

The NCNs define their products per image layer:

* Management node SquashFS images are always SLE_HPC (SuSE High Performance Computing)
* Utility Storage nodes Ceph Images are always SLE_HPC (SuSE High Performance Computing) _with_ SES (SuSE Enterprise Storage)

The sles-release RPM is _uninstalled_ for NCNs, and instead, the sle_HPC-release RPM is installed. These
both provide the same files, but differ for `os-release` and `/etc/product.d/baseproduct`.

The ses-release RPM is installed on top of the sle_HPC-release RPM in the Ceph images.

The following example shows the two product files for a utility storage node booted from the Ceph image.
This node is capable of high performance computing and serving enterprise storage.

```bash
ls -l /etc/products.d/
total 5
lrwxrwxrwx 1 root root   12 Jan  1 06:43 baseproduct -> SLE_HPC.prod
-rw-r--r-- 1 root root 1587 Oct 21 15:27 ses.prod
-rw-r--r-- 1 root root 2956 Jun 10  2020 SLE_HPC.prod
grep '<summary' /etc/products.d/*.prod
/etc/products.d/ses.prod:  <summary>SUSE Enterprise Storage 7</summary>
/etc/products.d/SLE_HPC.prod:  <summary>SUSE Linux Enterprise High Performance Computing 15 SP3</summary>
```

Kubernetes nodes will report SLE HPC only, which is reflected in the `kubectl` output.

```bash
kubectl get nodes -o wide
NAME       STATUS   ROLES                  AGE   VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
ncn-m001   Ready    control-plane,master   27h   v1.20.13   10.252.1.4    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
ncn-m002   Ready    control-plane,master   8d    v1.20.13   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
ncn-m003   Ready    control-plane,master   8d    v1.20.13   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
ncn-w001   Ready    <none>                 8d    v1.20.13   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
ncn-w002   Ready    <none>                 8d    v1.20.13   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
ncn-w003   Ready    <none>                 8d    v1.20.13   10.252.1.9    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
```
