# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, late-breaking workarounds and documentation
updates, or hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the `docs-csm` RPM.
After it has been installed, the documentation will be available at `/usr/share/doc/csm`.

- [Download and extract CSM product release](#download-and-extract-csm-product-release)
- [Apply patch to CSM release](#apply-patch-to-csm-release)
  - [Prerequisites](#apply-patch-to-csm-release-prerequisites)
  - [Procedure](#apply-patch-to-csm-release-procedure)
- [Check for latest workarounds and documentation updates](#check-for-latest-workarounds-and-documentation-updates)
- [Check for and apply workarounds](#check-for-and-apply-workarounds)
- [Check for field notices about hotfixes](#check-for-field-notices-about-hotfixes)

<a name="download-and-extract"></a>

## Download and extract CSM product release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

The following procedure should work on any Linux system. If directed here from another procedure, then that source procedure should indicate on which system the CSM release should
be downloaded and extracted.

1. Set the `ENDPOINT` variable to the URL of the server hosting the CSM tarball.

    ```bash
    linux# ENDPOINT=URL_SERVER_Hosting_tarball
    ```

1. Set the `CSM_RELEASE` variable to the version of CSM software to be downloaded.

    ```bash
    linux# CSM_RELEASE=x.y.z
    ```

1. Download the CSM software release tarball.

   ```bash
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

1. Extract the release distribution.

   > **NOTE:** Use `--no-same-owner` and `--no-same-permissions` options to `tar` when extracting a CSM release
   > distribution as `root` to ensure the current `umask` value.

   ```bash
   linux# tar --no-same-owner --no-same-permissions -xzvf "${CSM_RELEASE}.tar.gz"
   ```

1. Before using this software release, check for any patches available for it.

   If patches are available, see [Apply patch to CSM release](#apply-patch-to-csm-release).

<a name="patch"></a>

## Apply patch to CSM release

Apply a CSM update patch to the expanded CSM release tarball, and then create a new tarball which contains the patched release.
This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

### Apply patch to CSM release: Prerequisites

The following requirements must be met on the system where the procedure is being followed.

- The expanded CSM release tarball is present.

   Because the patch is applied to the expanded CSM release tarball, it is simplest to perform this
   procedure on the same system where the [Download and extract CSM product release](#download-and-extract-csm-product-release)
   procedure was followed.

- Git version `2.16.5` or higher must be installed.

   ```bash
   linux# git version
   ```

   Example output:

   ```text
   git version 2.26.2
   ```

   If the Git version is less than `2.16.15`, then update Git to at least that version.

### Apply patch to CSM release: Procedure

1. Set the `ENDPOINT` variable to the URL of the server hosting the CSM patch file.

   ```bash
   linux# ENDPOINT=URL_SERVER_Hosting_patch
   ```

1. Set the `CSM_RELEASE` variable to the version of CSM software to be patched.

   ```bash
   linux# CSM_RELEASE=x.y.z
   ```

1. Set the `PATCH_RELEASE` variable to the version of CSM patch.

   ```bash
   linux# PATCH_RELEASE=x.z.a
   ```

1. Download the compressed CSM software package patch file.

   The file name will be of the form `csm-x.y.z-x.z.a.patch.gz`.
   Be sure to modify the following example with the appropriate values.

   ```bash
   linux# wget "${ENDPOINT}/${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
   ```

1. Uncompress the patch.

   ```bash
   linux# gunzip -v "${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
   ```

1. Apply the patch.

   ```bash
   linux# git apply -p2 --whitespace=nowarn \
                        --directory="${CSM_RELEASE}" \
                        "${CSM_RELEASE}-${PATCH_RELEASE}.patch"
   ```

1. Set a variable to reflect the new version.

   ```bash
   linux# NEW_CSM_RELEASE="$(./${CSM_RELEASE}/lib/version.sh)"
   ```

1. Update the name of the CSM release distribution directory.

   ```bash
   linux# mv -v "${CSM_RELEASE}" "${NEW_CSM_RELEASE}"
   ```

1. Create a tarball from the patched release distribution.

   ```bash
   linux# tar -cvzf "${NEW_CSM_RELEASE}.tar.gz" "${NEW_CSM_RELEASE}/"
   ```

This tarball can now be used in place of the original CSM software release tarball.

<a name="workarounds"></a>

## Check for latest workarounds and documentation updates

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
   linux# scp -p docs-csm-latest.noarch.rpm csm-install-workarounds-latest.noarch.rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm /root/csm-install-workarounds-latest.noarch.rpm
   ```

1. Check the version of the newly installed workarounds and documentation.

   ```bash
   linux# rpm -q csm-install-workarounds docs-csm
   ```

<a name="apply-workarounds"></a>

## Check for and apply workarounds

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

## Check for field notices about hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.
