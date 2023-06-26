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

1. (`linux#`) Set the `ENDPOINT` variable to the URL of the server hosting the CSM tarball.

    ```bash
    ENDPOINT=URL_SERVER_Hosting_tarball
    ```

1. (`linux#`) Set the `CSM_RELEASE` variable to the version of CSM software to be downloaded.

    ```bash
    CSM_RELEASE=x.y.z
    ```

1. (`linux#`) Download the CSM software release tarball.

   > ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
   > Using `http_proxy` or `https_proxy` in any way other than the following examples will cause many failures in subsequent steps.

   - Without proxy:

     ```bash
     wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

   - With HTTPS proxy:

     ```bash
     https_proxy=https://example.proxy.net:443 wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

   - With HTTP proxy:

     ```bash
     http_proxy=http://example.proxy.net:80 wget "${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz"
     ```

1. (`linux#`) Extract the release distribution.

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

- (`linux#`) Git version `2.16.5` or higher must be installed.

   ```bash
   git version
   ```

   Example output:

   ```text
   git version 2.26.2
   ```

   If the Git version is less than `2.16.15`, then update Git to at least that version.

### Apply patch to CSM release: Procedure

1. (`linux#`) Set the `ENDPOINT` variable to the URL of the server hosting the CSM patch file.

    ```bash
    ENDPOINT=URL_SERVER_Hosting_patch
    ```

1. (`linux#`) Set the `CSM_RELEASE` variable to the version of CSM software to be patched.

    ```bash
    CSM_RELEASE=x.y.z
    ```

1. (`linux#`) Set the `PATCH_RELEASE` variable to the version of CSM patch.

    ```bash
    PATCH_RELEASE=x.z.a
    ```

1. (`linux#`) Download the compressed CSM software package patch file.

    The file name will be of the form `csm-x.y.z-x.z.a.patch.gz`.
    Be sure to modify the following example with the appropriate values.

   > ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
   > Using `http_proxy` or `https_proxy` in any way other than the following examples will cause many failures in subsequent steps.

   - Without proxy:

     ```bash
     wget "${ENDPOINT}/csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
     ```

   - With HTTPS proxy:

     ```bash
     https_proxy=https://example.proxy.net:443 wget "${ENDPOINT}/csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
     ```

   - With HTTP proxy:

     ```bash
     http_proxy=http://example.proxy.net:80 wget "${ENDPOINT}/csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
     ```

1. (`linux#`) Uncompress the patch.

   ```bash
   gunzip -v "csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz"
   ```

1. (`linux#`) Apply the patch.

   ```bash
   git apply -p2 --whitespace=nowarn --directory="csm-${CSM_RELEASE}" "csm-${CSM_RELEASE}-${PATCH_RELEASE}.patch"
   ```

1. (`linux#`) Set a variable to reflect the new version.

   ```bash
   NEW_CSM_RELEASE="$(./csm-${CSM_RELEASE}/lib/version.sh)"
   ```

1. (`linux#`) Update the name of the CSM release distribution directory.

   ```bash
   mv -v "csm-${CSM_RELEASE}" "csm-${NEW_CSM_RELEASE}"
   ```

1. (`linux#`) Create a tarball from the patched release distribution.

   ```bash
   tar -cvzf "csm-${NEW_CSM_RELEASE}.tar.gz" "csm-${NEW_CSM_RELEASE}/"
   ```

This tarball can now be used in place of the original CSM software release tarball.

## Check for latest documentation

Acquire the latest documentation RPM. This may include updates, corrections, and enhancements that were not available until after the software release.

> ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
> Using http proxies in any way other than the following examples will cause many failures in subsequent steps.

1. (`linux#`) Check the version of the currently installed CSM documentation and CSM library.

   ```bash
   rpm -q docs-csm libcsm
   ```

1. (`linux#`) Set the `CSM_RELEASE` variable to the installed version of CSM.

    ```bash
    CSM_RELEASE=x.y.z
    ```

1. (`linux#`) Download and upgrade the latest documentation RPM and CSM library.

    - Without proxy:

        ```bash
        wget "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/docs-csm/docs-csm-latest.noarch.rpm" -O /root/docs-csm-latest.noarch.rpm
        wget "https://release.algol60.net/lib/sle-$(awk -F= '/VERSION=/{gsub(/["-]/, "") ; print tolower($NF)}' /etc/os-release)/libcsm-latest.noarch.rpm" -O /root/libcsm-latest.noarch.rpm 
        ```

    - With HTTPS proxy:

        ```bash
        https_proxy=https://example.proxy.net:443 wget "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/docs-csm/docs-csm-latest.noarch.rpm" \
            -O /root/docs-csm-latest.noarch.rpm
        https_proxy=https://example.proxy.net:443 wget "https://release.algol60.net/lib/sle-$(awk -F= '/VERSION=/{gsub(/["-]/, "") ; print tolower($NF)}' /etc/os-release)/libcsm-latest.noarch.rpm" \
            -O /root/libcsm-latest.noarch.rpm
        ```

    - If this machine does not have direct internet access, then this RPM will need to be externally downloaded and
      copied to the system.

        - If the node receiving `libcsm` is reachable, use this to resolve the SLES version:

            ```bash
            SLES_VERSION=$(ssh ncn-m001 'awk -F= '\''/VERSION=/{gsub(/["-]/, "") ; print tolower($NF)}'\'' /etc/os-release')
            ```

        - If the node receiving `libcsm` is unreachable, set the SLES version of that node by hand:

            ```bash
            SLES_VERSION=15sp4
            ```

        ```bash
        curl -O "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/docs-csm/docs-csm-latest.noarch.rpm"
        curl -O "https://release.algol60.net/lib/sle-${SLES_VERSION}/libcsm-latest.noarch.rpm"
        scp docs-csm-latest.noarch.rpm libcsm-latest.noarch.rpm ncn-m001:/root
        ssh ncn-m001
        ```

1. (`linux#`) Install the documentation RPM and CSM library.

   ```bash
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm /root/libcsm-latest.noarch.rpm
   ```

1. Repeat the first step in this procedure to display the version of the CSM documentation after the update.

## Check for field notices about hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.
