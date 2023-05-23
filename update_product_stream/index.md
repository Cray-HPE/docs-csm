# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, documentation updates, or
hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the `docs-csm` RPM.
After the RPM has been installed, the documentation will be available at `/usr/share/doc/csm`.

- [Download and extract CSM product release](#download-and-extract-csm-product-release)
- [Apply patch to CSM release](#apply-patch-to-csm-release)
  - [Prerequisites](#apply-patch-to-csm-release-prerequisites)
  - [Procedure](#apply-patch-to-csm-release-procedure)
- [Check for latest documentation](#check-for-latest-documentation)
- [Check for field notices about hotfixes](#check-for-field-notices-about-hotfixes)

<a name="download-and-extract"></a>

## Download and extract CSM product release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

The following procedure should work on any Linux system. If directed here from another procedure, then that source procedure should indicate on which system the CSM release should
be downloaded and extracted.

1. Download the CSM software release tarball.

   ```bash
   linux# export ENDPOINT=URL_SERVER_Hosting_tarball
   linux# export CSM_RELEASE=csm-x.y.z
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

1. Extract the release distribution.

   ```bash
   linux# tar -xzvf "${CSM_RELEASE}.tar.gz"
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

1. Download the compressed CSM software package patch file.

   The file name will be of the form `csm-x.y.z-x.z.a.patch.gz`.
   Be sure to modify the following example with the appropriate values.

   ```bash
   linux# ENDPOINT=URL_SERVER_Hosting_tarball
   linux# CSM_RELEASE=csm-x.y.z
   linux# PATCH_RELEASE=x.z.a
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

<a name="documentation"></a>

## Check for latest documentation

Acquire the latest documentation RPM. This may include updates, corrections, and enhancements that were not available until after the software release.

1. Check the version of the currently installed CSM documentation.

   ```bash
   linux# rpm -q docs-csm
   ```

1. Download and upgrade the latest documentation RPM.

   ```bash
   linux# rpm -Uvh --force https://release.algol60.net/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm
   ```

   If this machine does not have direct internet access, then this RPM will need to be externally downloaded and copied to the system. This example copies it to `ncn-m001`.

   ```bash
   linux# wget https://release.algol60.net/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm -O docs-csm-latest.noarch.rpm
   linux# scp docs-csm-latest.noarch.rpm ncn-m001:/root
   linux# ssh ncn-m001
   ncn-m001# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. Repeat the first step in this procedure to display the version of the CSM documentation after the update.

<a name="hotfixes"></a>

## Check for field notices about hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.