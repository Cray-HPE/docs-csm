# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way.  The initial product release may be augmented with patches, late-breaking workarounds and documentation updates, or hotfixes after the release.

### Topics:
   * [Download and Extract CSM Product Release](#download-and-extract)
   * [Apply Patch to CSM Release](#patch)
   * [Check for Latest Workarounds and Documentation Updates](#workarounds)
   * [Check for Field Notices about Hotfixes](#hotfixes)

The topics in thie chapter need to be done as part of an ordered procedure so are shown here with numbered topics.

## Details

<a name="download-and-extract"></a>
## Download and Extract CSM Product Release

### About this task

#### Role
System installer

#### Objective
Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

#### Limitations
None.

### Procedure

   1. Download the CSM software release tarball for the HPE Cray EX system to a Linux system.
 
   ```bash
   linux# cd ~
   linux# export ENDPOINT=URL_SERVER_Hosting_tarball
   linux# export CSM_RELEASE=csm-x.y.z
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

   1. Extract the source release distribution.

   If doing a first time install, this can be done on a Linux system, but for an upgrade, it could be done on one of the NCNs, such as ncn-m001.

   ```
   linux# tar -xzf ${CSM_RELEASE}.tar.gz
   ```

   1. Before using this software release, check for any patches available for it.  If patches are available, see [Apply Patch to CSM Release](#patch).

<a name="patch"></a>
## Apply Patch to CSM Release

### About this task

#### Role
System installer

#### Objective
Apply a CSM update patch to the release tarball.  This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

#### Limitations
None.

### Procedure

   1. Verify that the Git version is at least 2.16.5 on the Linus system which will apply the patch.

   The patch process is known to work with Git >= 2.16.5. Older versions of Git may not correctly apply the
   binary patch.

   ```
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
   These examples use ncn-m001.

   1. Uncompress the patch.

   ```
   ncn-m001# gunzip ${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
   ```

   1. Apply the patch.

   ```
   ncn-m001# git apply -p2 --whitespace=nowarn --directory=${CSM_RELEASE} \
   ${CSM_RELEASE}-${PATCH_RELEASE}.patch
   ```

   1. Set a variable to reflect the new version.

   ```
   ncn-m001# export NEW_CSM_RELEASE="$(./${CSM_RELEASE/lib/version.sh)"
   ```

   1. Update the name of the CSM release distribution directory.

   ```bash
   ncn-m001# mv $CSM_RELEASE $NEW_CSM_RELEASE
   ```

   1. Create a tarball from the patched release distribution.

   ```bash
   ncn-m001# tar -cvzf ${NEW_CSM_RELEASE}.tar.gz "${NEW_CSM_RELEASE}/"
   ```

   This tarball can now be used in place of the original CSM software release tarball.

<a name="workarounds"></a>
## Check for Latest Workarounds and Documentation Updates

### About this task

#### Role
System installer

#### Objective
Acquire the late-breaking CSM workarounds and documentation update rpms.  These fixes were not available until after the software release.  The software installation and upgrade processes have several breakpoints where you check and apply workarounds before or after a critical procedure.

#### Limitations
None.

### Procedure

   1. Download and upgrade the latest workaround and documentation RPMs.

   ```bash
   linux# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   linux# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

   If this machine does not have direct Internet access these RPMs will need to be externally downloaded and then copied to the system.  This example copies them to ncn-m001.

   ```bash
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   linux# scp -p docs-csm-install-*rpm csm-install-workarounds-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh csm-install-workarounds-latest.noarch.rpm
   ```

<a name="hotfixes"></a>
## Check for Field Notices about Hotfixes

### About this task

#### Role
System installer

#### Objective
Check with HPE Pointnext for any Field Notices about Hotfixes which should be applied to this CSM software release. 

#### Limitations
None.

### Procedure

   1. TODO
