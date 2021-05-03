# Download and Expand the CSM Release

Fetch the base installation CSM tarball and extract it, installing the contained CSI tool.

1. Start a typescript to capture the commands and output from this installation.
   ```bash
   ncn-m001# script -af csm-1.5-upgrade.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```
2. Download the CSM software release to ncn-m001 -- choose either stable or prerelease depending on your intent:

   a. Preferred method (stable):

      ```bash
      ncn-m001# cd ~
      ncn-m001# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm/
      ncn-m001# export CSM_RELEASE=csm-x.y.z
      ncn-m001# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
      ```

   b. Prerelease/internal use (only):

      > **`INTERNAL USE`** The `ENDPOINT` URL below are for internal use. Customers do not need to download any additional 
      > artifacts, the CSM tarball is included along with the Shasta release.
     
      ```bash
      ncn-m001# cd ~
      ncn-m001# export ENDPOINT=http://arti.dev.cray.com/artifactory/shasta-distribution-unstable-local/csm/
      ncn-m001# export CSM_RELEASE=csm-1.0.0-alpha.x # (whichever version is latest from above)
      ncn-m001# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
      ``` 

3. Expand the CSM software release:
   ```bash
   ncn-m001# tar -zxvf ${CSM_RELEASE}.tar.gz
   ncn-m001# ls -l ${CSM_RELEASE}
   ```
   The ISO and other files are now available in the extracted CSM tar.

4. Install/upgrade the CSI RPM.
   ```bash
   ncn-m001# rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
   ```

5. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet 
   access these RPMs will need to be externally downloaded and then copied to be installed.
   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

6. Show the version of CSI installed.
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
