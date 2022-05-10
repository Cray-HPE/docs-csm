# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, late-breaking workarounds and documentation
updates, or hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the `docs-csm` RPM.
After it has been installed, the documentation will be available at `/usr/share/doc/csm`.

- [Download and Extract CSM Product Release](#download-and-extract)
- [Apply Patch to CSM Release](#patch)
- [Check for Latest Workarounds and Documentation Updates](#workarounds)
- [Check for and Apply Workarounds](#apply-workarounds)
- [Check for Field Notices about Hotfixes](#hotfixes)

<a name="download-and-extract"></a>

## Download and Extract CSM Product Release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

1. Download the CSM software release tarball for the HPE Cray EX system to a Linux system.

   ```bash
   linux# export ENDPOINT=URL_SERVER_Hosting_tarball
   linux# export CSM_RELEASE=csm-x.y.z
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

1. Extract the source release distribution.

   If doing a first time install, this can be done on any Linux system. For an upgrade, it may be done on one of the NCNs, such as `ncn-m001`.

   > **NOTE:** Use `--no-same-owner` and `--no-same-permissions` options to `tar` when extracting a CSM release
   > distribution as `root` to ensure the current `umask` value.

   ```bash
   linux# tar --no-same-owner --no-same-permissions -xzvf ${CSM_RELEASE}.tar.gz
   ```

1. Before using this software release, check for any patches available for it. If patches are available, see [Apply Patch to CSM Release](#patch).

<a name="patch"></a>

## Apply Patch to CSM Release

Apply a CSM update patch to the release tarball. This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

1. Verify that the Git version is at least `2.16.5` on the Linux system which will apply the patch.

   The patch process is known to work with Git version `2.16.5` or higher. Older versions of Git may not correctly apply the
   binary patch.

   ```bash
   linux# git version
   ```

   Example output:

   ```text
   git version 2.26.2
   ```

   If the Git version is less than `2.16.15`, update Git to at least that version.

1. Download the compressed CSM software package patch `csm-x.y.z-x.z.a.patch.gz` for the HPE Cray EX system.

   ```bash
   linux# export ENDPOINT=URL_SERVER_Hosting_tarball
   linux# export CSM_RELEASE=csm-x.y.z
   linux# export PATCH_RELEASE=x.z.a
   linux# wget ${ENDPOINT}/${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
   ```

   Run the remaining steps from the node to which the original `$CSM_RELEASE` release was downloaded and extracted.

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

Acquire the late-breaking CSM workarounds and documentation update RPMs. These fixes were not available until after the software release. The software installation and upgrade processes
have several breakpoints where you check and apply workarounds before or after a critical procedure.

1. Check the version of the currently installed CSM documentation and workarounds.

   ```bash
   ncn# rpm -q csm-install-workarounds docs-csm
   ```

1. Download and upgrade the latest workaround and documentation RPMs.

   ```bash
   linux# rpm -Uvh --force https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
   linux# rpm -Uvh --force https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

   If this machine does not have direct internet access, then these RPMs will need to be externally downloaded and copied to the system. This example copies them to `ncn-m001`.

   ```bash
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm -O docs-csm-latest.noarch.rpm
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm -O csm-install-workarounds-latest.noarch.rpm
   linux# scp -p docs-csm-*rpm csm-install-workarounds-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh --force docs-csm-latest.noarch.rpm
   ncn-m001# rpm -Uvh --force csm-install-workarounds-latest.noarch.rpm
   ```

1. Check the version of the newly installed documentation.

   ```bash
   ncn# rpm -q csm-install-workarounds docs-csm
   ```

<a name="apply-workarounds"></a>

## Check for and Apply Workarounds

The software installation and upgrade processes have several breakpoints before or after a critical procedure. At these breakpoints, workarounds
are applied, if any are available for that particular breakpoint.

Check to see if workarounds need to be applied at a particular point of the install process. If so, then apply those workarounds.

In order to carry out this procedure, the name of the workaround breakpoint (for example, `before-configuration-payload` or
`after-sysmgmt-manifest`) must be known.

1. Change to the directory containing the workarounds to be applied at this breakpoint.

   ```bash
   linux# pushd /opt/cray/csm/workarounds/<put-actual-breakpoint-name-here>
   ```

1. List all subdirectories of this directory.

   ```bash
   linux# find -maxdepth 1 -type d ! -name . | cut -c3-
   ```

   If there is nothing listed, then there are no workarounds to be applied at this breakpoint and the procedure is complete.

1. For each subdirectory which is listed, apply the workaround described within it.

   Perform the following steps for each subdirectory which was listed in the previous step.

   1. Change directory into the subdirectory.

      ```bash
      linux# pushd <put-subdirectory-name-here>
      ```

   1. View the `README.md` file in this directory and carefully follow its instructions.

   1. Return to the main directory for workarounds for this breakpoint.

      ```bash
      linux# popd
      ```

1. The procedure is complete. Return to the original directory.

   ```bash
   linux# popd
   ```

<a name="hotfixes"></a>

## Check for Field Notices about Hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.
