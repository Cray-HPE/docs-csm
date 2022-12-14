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

## Download and extract CSM product release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

The following procedure should work on any Linux system. If directed here from another procedure, then that source procedure should indicate on which system the CSM release should
be downloaded and extracted.

1. Download the CSM software release tarball.

   > ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
Using `http_proxy` or `https_proxy` in any way other than the following examples will cause many failures in subsequent steps.

   - Without proxy:

     ```bash
     ENDPOINT=URL_SERVER_Hosting_tarball
     CSM_RELEASE=x.y.z
     wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

   - With https proxy:

     ```bash
     ENDPOINT=URL_SERVER_Hosting_tarball
     CSM_RELEASE=x.y.z
     https_proxy=https://example.proxy.net:443 wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

   - With http proxy:

     ```bash
     ENDPOINT=URL_SERVER_Hosting_tarball
     CSM_RELEASE=x.y.z
     http_proxy=http://example.proxy.net:80 wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

1. Extract the release distribution.

   ```bash
   tar -xzvf "csm-${CSM_RELEASE}.tar.gz"
   ```

1. Before using this software release, check for any patches available for it.

   If patches are available, see [Apply patch to CSM release](#apply-patch-to-csm-release).

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
   git version
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
   ENDPOINT=URL_SERVER_Hosting_tarball
   CSM_RELEASE=x.y.z
   PATCH_RELEASE=x.z.a
   wget "${ENDPOINT}/csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
   ```

1. Uncompress the patch.

   ```bash
   gunzip -v "csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
   ```

1. Apply the patch.

   ```bash
   git apply -p2 --whitespace=nowarn \
                        --directory="csm-${CSM_RELEASE}" \
                        "csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch"
   ```

1. Set a variable to reflect the new version.

   ```bash
   NEW_CSM_RELEASE="$(./csm-${CSM_RELEASE}/lib/version.sh)"
   ```

1. Update the name of the CSM release distribution directory.

   ```bash
   mv -v "csm-${CSM_RELEASE}" "csm-${NEW_CSM_RELEASE}"
   ```

1. Create a tarball from the patched release distribution.

   ```bash
   tar -cvzf "csm-${NEW_CSM_RELEASE}.tar.gz" "csm-${NEW_CSM_RELEASE}/"
   ```

This tarball can now be used in place of the original CSM software release tarball.

## Check for latest documentation

Acquire the latest documentation RPM. This may include updates, corrections, and enhancements that were not available until after the software release.

> ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
Using http proxies in any way other than the following examples will cause many failures in subsequent steps.

1. Check the version of the currently installed CSM documentation.

   ```bash
   rpm -q docs-csm
   ```

1. Download and upgrade the latest documentation RPM.

   Without proxy:

   ```bash
   rpm -Uvh --force https://release.algol60.net/csm-1.4/docs-csm/docs-csm-latest.noarch.rpm
   ```

   With https proxy:

   ```bash
   rpm -Uvh --force --httpproxy https://example.proxy.net --httpport 443 https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.4/noarch/docs-csm-latest.noarch.rpm
   ```

   If this machine does not have direct internet access, then this RPM will need to be externally downloaded and copied to the system. This example copies it to `ncn-m001`.

   ```bash
   wget https://release.algol60.net/csm-1.4/docs-csm/docs-csm-latest.noarch.rpm -O docs-csm-latest.noarch.rpm
   scp docs-csm-latest.noarch.rpm ncn-m001:/root
   ssh ncn-m001
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. Repeat the first step in this procedure to display the version of the CSM documentation after the update.

## Check for field notices about hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.
