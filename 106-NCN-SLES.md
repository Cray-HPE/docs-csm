# NCN Operating System Release

The NCNs define their products per image layer:


##### VSHASTA
- All images are SLES (SuSE Linux Enterprise Server)

##### METAL

- Metal SquashFS are always SLE_HPC (SuSE High Performance Computing)
- Metal CEPH Storage Images are always SLE_HPC (SuSE High Performance Computing) _with_ SES (SuSE Enterprise Storage)


###### Release RPM Details

The sles-release RPM is _uninstalled_ for Metal, instead the sle_HPC-release RPM is installed. These 
both provide the same files, but differ for `os-release` and `/etc/product.d/baseproduct`.

The ses-release RPM is installed atop the sle_HPC-release RPM in our CEPH images. 


### Example - On a Live System

Below we can see the two product files for a CEPH node, in here we see we have a metal node that is capable
of high performance computing and serving enterprise storage.

 ```bash
ncn-s001# ls -l /etc/products.d/
total 5
lrwxrwxrwx 1 root root   12 Jan  1 06:43 baseproduct -> SLE_HPC.prod
-rw-r--r-- 1 root root 1587 Oct 21 15:27 ses.prod
-rw-r--r-- 1 root root 2956 Jun 10  2020 SLE_HPC.prod
ncn-s001# grep '<summary' /etc/products.d/*.prod
/etc/products.d/ses.prod:  <summary>SUSE Enterprise Storage 7</summary>
/etc/products.d/SLE_HPC.prod:  <summary>SUSE Linux Enterprise High Performance Computing 15 SP2</summary>
```

Kubernetes nodes on the other hand will report SLES HPC only, this is reflective in `kubectl` output:
> Remember, vshasta will show SUSE Linux Enterprise Server instead.
```
pit# kubectl get nodes -o wide
NAME       STATUS   ROLES    AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
ncn-m002   Ready    master   128m   v1.18.6   10.252.1.14   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.37-default   containerd://1.3.4
ncn-m003   Ready    master   127m   v1.18.6   10.252.1.13   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.37-default   containerd://1.3.4
ncn-w001   Ready    <none>   90m    v1.18.6   10.252.1.12   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.37-default   containerd://1.3.4
ncn-w002   Ready    <none>   88m    v1.18.6   10.252.1.11   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.37-default   containerd://1.3.4
ncn-w003   Ready    <none>   82m    v1.18.6   10.252.1.10   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.37-default   containerd://1.3.4 
```
