# Update CSM Product Stream

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with patches, documentation updates, or
hotfixes after the release.

The CSM documentation is included within the CSM product release tarball inside the `docs-csm` RPM.
After the RPM has been installed, the documentation will be available at `/usr/share/doc/csm`.

- [Download and Extract CSM Product Release](#download-and-extract-csm-product-release)
- [Apply Patch to CSM Release](#apply-patch-to-csm-release)
- [Check for Latest Documentation](#check-for-latest-documentation)
- [Check for Field Notices about Hotfixes](#check-for-field-notices-about-hotfixes)

## Download and Extract CSM Product Release

Acquire a CSM software release tarball for installation on the HPE Cray EX supercomputer.

1. Download the CSM software release tarball for the HPE Cray EX system to a Linux system.

   ```bash
   export ENDPOINT=URL_SERVER_Hosting_tarball
   export CSM_RELEASE=csm-x.y.z
   wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

1. Extract the source release distribution.

   If doing a first time install, this can be done on a Linux system, but for an upgrade, it may be done on one of the NCNs, such as `ncn-m001`.

   ```bash
   tar -xzvf ${CSM_RELEASE}.tar.gz
   ```

1. Before using this software release, check for any patches available for it. If patches are available, see [Apply Patch to CSM Release](#patch).

## Apply Patch to CSM Release

Apply a CSM update patch to the release tarball. This ensures that the latest CSM product artifacts are installed on the HPE Cray EX supercomputer.

1. Verify that the Git version is at least `2.16.5` on the Linux system which will apply the patch.

   The patch process is known to work with Git version `2.16.5` or higher. Older versions of Git may not correctly apply the
   binary patch.

   ```bash
   git version
   ```

   Example output:

   ```text
   git version 2.26.2
   ```

   If the Git version is less than `2.16.15`, update Git to at least that version.

1. Download the compressed CSM software package patch `csm-x.y.z-x.z.a.patch.gz` for the HPE Cray EX system.

   ```bash
   export ENDPOINT=URL_SERVER_Hosting_tarball
   export CSM_RELEASE=csm-x.y.z
   export PATCH_RELEASE=x.z.a
   wget ${ENDPOINT}/${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
   ```

   Run the remaining steps from the node to which the original `$CSM_RELEASE` release was downloaded and extracted.

1. Uncompress the patch.

   ```bash
   gunzip -v ${CSM_RELEASE}-${PATCH_RELEASE}.patch.gz
   ```

1. Apply the patch.

   ```bash
   git apply -p2 --whitespace=nowarn \
                        --directory=${CSM_RELEASE} \
                        ${CSM_RELEASE}-${PATCH_RELEASE}.patch
   ```

1. Set a variable to reflect the new version.

   ```bash
   export NEW_CSM_RELEASE="$(./${CSM_RELEASE/lib/version.sh)"
   ```

1. Update the name of the CSM release distribution directory.

   ```bash
   mv -v $CSM_RELEASE $NEW_CSM_RELEASE
   ```

1. Create a tarball from the patched release distribution.

   ```bash
   tar -cvzf ${NEW_CSM_RELEASE}.tar.gz "${NEW_CSM_RELEASE}/"
   ```

This tarball can now be used in place of the original CSM software release tarball.

## Check for Latest Documentation

Acquire the latest documentation RPM. This may include updates, corrections, and enhancements that were not available until after the software release.

1. Check the version of the currently installed CSM documentation.

   ```bash
   rpm -q docs-csm
   ```

1. Download and upgrade the latest documentation RPM.

   ```bash
   rpm -Uvh --force https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm
   ```

   If this machine does not have direct internet access, then this RPM will need to be externally downloaded and copied to the system. This example copies it to `ncn-m001`.

   ```bash
   wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm -O docs-csm-latest.noarch.rpm
   scp -p docs-csm-*rpm ncn-m001:/root
   ssh ncn-m001
   rpm -Uvh --force docs-csm-latest.noarch.rpm
   ```

1. Repeat the first step in this procedure to display the version of the CSM documentation after the update.

## Check for Field Notices about Hotfixes

## Check for Field Notices about Hotfixes

Collect all available field notices about hotfixes which should be applied to this CSM software release. Check with HPE Cray service for more information.
