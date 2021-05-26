# Download and Expand the CSM Release

Fetch the base installation CSM tarball and extract it, installing the contained CSI tool.

1. Start a typescript to capture the commands and output from this installation.
   ```bash
   ncn-m001# script -af csm-1.5-upgrade.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```
2. Download and extract the CSM software release to ncn-m001:

   Follow instructions at [Update CSM Product Stream](../../../../update_product_stream/index.md) to download the csm tarfile (csm-x.y.z.tar.gz).

3. Install/upgrade the CSI RPM.
   ```bash
   ncn-m001# rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
   ```

4. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet 
   access these RPMs will need to be externally downloaded and then copied to be installed.
   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

5. Show the version of CSI installed.
   ```bash
   ncn-m001# csi version
   ```
   
   Expected output looks similar to the following:
   ```
   CRAY-Site-Init build signature...
   Build Commit   : b3ed3046a460d804eb545d21a362b3a5c7d517a3-release-shasta-1.4
   Build Time     : 2021-02-04T21:05:32Z
   Go Version     : go1.14.9
   Git Version    : b3ed3046a460d804eb545d21a362b3a5c7d517a3
   Platform       : linux/amd64
   App. Version   : 1.5.18
    ```


# Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# ./${CSM_RELEASE}/lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```text
...
+ Nexus setup complete
setup-nexus.sh: OK
```

# Upgrade BSS

To make booting NCNs during an upgrade more reliable, upgrade BSS to the 1.5 version:

```bash
ncn-m001# helm -n services upgrade cray-hms-bss ./${CSM_RELEASE}/helm/cray-hms-bss-*.tgz
```

Then wait for the deployment to be fully upgraded:

```bash
ncn-m001# kubectl -n services rollout status deployment cray-bss
...
deployment "cray-bss" successfully rolled out
```

# Upload New NCN Images

```bash
ncn-m001# export artdir=./${CSM_RELEASE}/images
ncn-m001# csi handoff ncn-images \
          --kubeconfig /etc/kubernetes/admin.conf \
          --k8s-kernel-path $artdir/kubernetes/*.kernel \
          --k8s-initrd-path $artdir/kubernetes/initrd.img*.xz \
          --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
          --ceph-kernel-path $artdir/storage-ceph/*.kernel \
          --ceph-initrd-path $artdir/storage-ceph/initrd.img*.xz \
          --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs
```

Running this command will output a block that looks like this at the end:
```text
You should run the following commands so the versions you just uploaded can be used in other steps:
export KUBERNETES_VERSION=x.y.z
export CEPH_VERSION=x.y.z
```
Be sure to perform this action so subsequent steps are successful.

[Back to Main Page](../../README.md)
