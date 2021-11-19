# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, late-breaking workarounds and documentation updates, or hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the docs-csm RPM.
After it has been installed, the documentation will be available at `/usr/share/doc/csm` as installed by
the docs-csm RPM.

### Topics:
   * [Download and Extract CSM Product Release](#download-and-extract)
   * [Apply Patch to CSM Release](#patch)
   * [Check for Latest Workarounds and Documentation Updates](#workarounds)
   * [Check for and Apply Workarounds](#apply-workarounds)
   * [Check for Field Notices about Hotfixes](#hotfixes)

The topics in this chapter need to be done as part of an ordered procedure so are shown here with numbered topics.

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

### About this task

#### Role
System installer

#### Objective
Apply a CSM update patch to the release tarball. This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

#### Limitations
None.

### Procedure

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

<a name="workarounds"></a>
## Check for Latest Workarounds and Documentation Updates

### About this task

#### Role
System installer

#### Objective
Acquire the late-breaking CSM workarounds and documentation update RPMs. These fixes were not available until after the software release. The software installation and upgrade processes have several breakpoints where you check and apply workarounds before or after a critical procedure.

This command will report the version of your installed documentation.

```bash
ncn# rpm -q docs-csm
```


#### Limitations
None.

### Procedure

1. Check the version of the currently installed CSM documentation.

   ```bash
   ncn# rpm -q docs-csm
   ```

1. Download and upgrade the latest workaround and documentation RPMs.

   ```bash
   linux# rpm -Uvh --force https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm
   linux# rpm -Uvh --force https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

   If this machine does not have direct Internet access these RPMs will need to be externally downloaded and then copied to the system. This example copies them to ncn-m001.

   ```bash
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   linux# scp -p docs-csm-*rpm csm-install-workarounds-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh --force docs-csm-latest.noarch.rpm
   ncn-m001# rpm -Uvh --force csm-install-workarounds-latest.noarch.rpm
   ```

1. Check the version of the newly installed documentation.

   ```bash
   ncn# rpm -q docs-csm
   ```

<a name="apply-workarounds"></a>
## Check for and Apply Workarounds

### About this task

#### Role
System installer

#### Objective
The software installation and upgrade processes have several breakpoints where you check and apply workarounds before or after a critical procedure. Check to see if workarounds need to be applied at a particular point of the install process. If there are, apply those workarounds.

#### Limitations
None.

#### Prerequisites

   * The [latest workaround RPM](#workarounds) is installed.
   * The name of the workaround breakpoint (e.g. `before-configuration-payload` or `after-sysmgmt-manifest`) is known.

### Procedure

   1. Change to the directory containing the workarounds to be applied at this breakpoint.

      ```bash
      linux# pushd /opt/cray/csm/workarounds/<put-actual-breakpoint-name-here>
      ```

   1. List all subdirectories of this directory.

      ```bash
      linux# find -maxdepth 1 -type d ! -name . | cut -c3-
      ```

      If there is nothing listed, there are no workarounds to be applied at this breakpoint, and you can skip the next step.

   1. For each subdirectory which is listed, apply the workaround described within it.

      Perform the following steps for each subdirectory which was listed in the previous step.

      1. Change directory into the subdirectory.

         ```bash
         linux# pushd <put-subdirectory-name-here>
         ```

      1. View the `README.md` file in this directory, and carefully follow its instructions.

      1. Return to the main directory for workarounds for this breakpoint.

         ```bash
         linux# popd
         ```

   1. The procedure is complete. Return to your original directory.

      ```bash
      linux# popd
      ```

<a name="hotfixes"></a>
## Check for Field Notices about Hotfixes

### About this task

#### Role
System installer

#### Objective
Collect all available Field Notices about Hotfixes which should be applied to this CSM software release.

#### Limitations
None.

### Procedure

Check with HPE Cray service for any Field Notices about Hotfixes which should be applied to this CSM software release.


