# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, documentation updates, or hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the `docs-csm` RPM.
After the RPM has been installed, the documentation will be available at `/usr/share/doc/csm`.

## Topics:
   * [Download and Extract CSM Product Release](#download-and-extract)
   * [Apply Patch to CSM Release](#patch)
   * [Check for Latest Documentation](#documentation)
   * [Check for Field Notices about Hotfixes](#hotfixes)

<a name="download-and-extract"></a>
## Download and Extract CSM Product Release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

### Details

   1. Download the CSM software release tarball for the HPE Cray EX system to a Linux system.

      ```bash
      linux# export ENDPOINT=URL_SERVER_Hosting_tarball
      linux# export CSM_RELEASE=csm-x.y.z
      linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
      ```

   1. Extract the source release distribution.

      If doing a first time install, this can be done on a Linux system, but for an upgrade, it could be done on one of the NCNs, such as ncn-m001.

      ```bash
      linux# tar -xzvf ${CSM_RELEASE}.tar.gz
      ```

   1. Before using this software release, check for any patches available for it. If patches are available, see [Apply Patch to CSM Release](#patch).

<a name="patch"></a>
## Apply Patch to CSM Release

Apply a CSM update patch to the release tarball. This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

### Details

   1. Verify that the Git version is at least 2.16.5 on the Linux system which will apply the patch.

      The patch process is known to work with Git >= 2.16.5. Older versions of Git may not correctly apply the
      binary patch.

      ```bash
      linux# git version
      git version 2.26.2
      ```

      If the Git version is less than 2.16.15, update Git to at least that version.

   1. Download the compressed CSM software package patch csm-x.y.z-x.z.a.patch.gz for the HPE Cray EX system.

      ```bash
      linux# export ENDPOINT=URL_SERVER_Hosting_tarball
      linux# export CSM_RELEASE=csm-x.y.z
      linux# export PATCH_RELEASE=x.z.a
      linux# wget ${ENDPOINT}/${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
      ```

      The following steps should be run from the node to which the original $CSM_RELEASE release was downloaded and extracted.

   1. Uncompress the patch.

      ```bash
      linux# gunzip -v ${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
      ```

   1. Apply the patch.

      ```bash
      linux# git apply -p2 --whitespace=nowarn \
                           --directory=${CSM_RELEASE} \
                           ${CSM_RELEASE}-${PATCH_RELEASE}.patch
      ```

   1. Set a variable to reflect the new version.

      ```bash
      linux# export NEW_CSM_RELEASE="$(./${CSM_RELEASE/lib/version.sh)"
      ```

   1. Update the name of the CSM release distribution directory.

      ```bash
      linux# mv -v $CSM_RELEASE $NEW_CSM_RELEASE
      ```

   1. Create a tarball from the patched release distribution.

      ```bash
      linux# tar -cvzf ${NEW_CSM_RELEASE}.tar.gz "${NEW_CSM_RELEASE}/"
      ```

This tarball can now be used in place of the original CSM software release tarball.

<a name="documentation"></a>
## Check for Latest Documentation

Acquire the latest documentation RPM. This may include updates, corrections, and enhancements that were not available until after the software release.

### Details

1. Check the version of the currently installed CSM documentation.

   ```bash
   linux# rpm -q docs-csm
   ```

1. Download and upgrade the latest documentation RPM.

   ```bash
   linux# rpm -Uvh --force https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm
   ```

   If this machine does not have direct Internet access, this RPM will need to be externally downloaded and then copied to the system. This example copies it to `ncn-m001`.

   ```bash
   linux# wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm
   linux# scp -p docs-csm-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh --force docs-csm-latest.noarch.rpm
   ```

1. Repeat the first step in this procedure to display the version of the CSM documentation after the update.

<a name="hotfixes"></a>
## Check for Field Notices about Hotfixes

Collect all available Field Notices about Hotfixes which should be applied to this CSM software release.

### Details

Check with HPE Cray service for any Field Notices about Hotfixes which should be applied to this CSM software release.

