# SAT Uninstall and Downgrade

## Uninstall: Remove a Version of SAT

This procedure can be used to uninstall a version of SAT installed as a separate product stream.
This is an optional procedure. Its main benefits are that it will free up a small amount of space in
Nexus, and it may reduce confusion by removing additional outdated SAT versions from the
`cray-product-catalog` Kubernetes ConfigMap.

This procedure cannot be used to uninstall the version of SAT included in the CSM release. SAT 2.6
releases are the last releases of SAT as a separate product stream.

### Prerequisites

- Only versions 2.2 or newer of SAT can be uninstalled with `prodmgr`.
- CSM version 1.2 or newer must be installed, so that the `prodmgr` command is available.

### Uninstall Procedure

1. (`ncn-m001#`) Use `sat showrev` to list versions of SAT which have been installed as a separate
   product.

   ```bash
   sat showrev --products --filter product_name=sat
   ```

   Example output:

   ```text
   ###############################################################################
   Product Revision Information
   ###############################################################################
   +--------------+-----------------+-------------------+-----------------------+
   | product_name | product_version | images            | image_recipes         |
   +--------------+-----------------+-------------------+-----------------------+
   | sat          | 2.3.3           | -                 | -                     |
   | sat          | 2.2.10          | -                 | -                     |
   +--------------+-----------------+-------------------+-----------------------+
   ```

   Note that starting in CSM v1.6.0, SAT is no longer separately installed, and CSM installation
   does not add rows with `sat` as the `product_name`.

1. (`ncn-m001#`) Use `prodmgr` to uninstall a version of SAT.

   This command will do three things:

   - Remove all hosted-type package repositories associated with the given version of SAT. Group-type
     repositories are not removed.
   - Remove all container images associated with the given version of SAT.
   - Remove SAT from the `cray-product-catalog` Kubernetes ConfigMap, so that it will no longer show up
     in the output of `sat showrev`.

   ```bash
   prodmgr uninstall sat 2.2.10
   ```

   Example output:

   ```text
   Repository sat-2.2.10-sle-15sp2 has been removed.
   Removed Docker image cray/cray-sat:3.9.0
   Removed Docker image cray/sat-cfs-install:1.0.2
   Removed Docker image cray/sat-install-utility:1.4.0
   Deleted sat-2.2.10 from product catalog.
   ```

## Downgrade: Switch Between SAT Versions

Starting in CSM v1.6.0, it is no longer recommended to use `prodmgr activate` to switch between SAT
versions.

Instead, if it is necessary to switch to an alternate version of SAT, it is recommended to set the
environment variable `SAT_IMAGE` as described in the procedure below. This will change the version
of the `cray-sat` container image run by Podman when the `sat` command is executed.

### Downgrade Procedure

1. (`ncn-mw#`) First, determine the versions of the `cray-sat` container image which are available
   in the container image registry in Nexus. There are multiple ways to do so. One easy way is to
   use `podman search`.

   Versions of SAT which were available as a separate product stream uploaded the `cray-sat`
   container image to the path `cray/cray-sat` in the Nexus container image registry.

   CSM v1.3, v1.4, and v1.5 releases additionally began including the `cray-sat` container image
   and uploaded it to the path `artifactory.algol60.net/sat-docker/stable/cray-sat`.

   Finally, CSM v1.6.0 and beyond include the `cray-sat` container image and upload it to the path
   `artifactory.algol60.net/csm-docker/stable/cray-sat`.

   The following `bash` for loop shows all tags of the `cray-sat` container image across all three
   of these locations, ignoring errors if the `cray-sat` image does not exist at any of these paths:

   ```bash
   for image in cray/cray-sat \
                artifactory.algol60.net/{sat,csm}-docker/stable/cray-sat; do
     podman search --list-tags "registry.local/$image" 2>/dev/null \
       | awk '{ OFS=":" } { if ($1 ~ /cray-sat/) { print $1, $2; } }'
   done
   ```

   The output will look similar to the following:

   ```text
   registry.local/cray/cray-sat:3.15.5
   registry.local/cray/cray-sat:3.19.3
   registry.local/cray/cray-sat:3.21.7
   registry.local/cray/cray-sat:3.25.6
   registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:3.19.3
   registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:3.21.7
   registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:3.25.6
   registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:csm-latest
   ```

   Note that the same tag of the `cray-sat` image is uploaded to two locations starting in CSM
   v1.3.0, which means it will show up under two different names.

1. (`ncn-mw#`) Choose the desired `cray-sat` image version from the output of the previous step, and
   set the environment variable `SAT_IMAGE`. For example:

   ```bash
   export SAT_IMAGE="registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:3.21.7"
   ```

1. (`ncn-mw#`) Run `sat --version` to confirm the new version is being used. Note that the first
   time this command is executed with the `SAT_IMAGE` variable set, `podman` may need to download
   the image from the Nexus container image registry.

   ```bash
   sat --version
   ```

   The output should be just the semantic version of the `sat` command, which will match the tag of
   the container image. For example:

   ```text
   3.21.7
   ```

1. If this change must be persisted across multiple sessions on the system, the `export
   SAT_IMAGE="..."` can be added to the user's `~/.bash_profile` or `~/.bashrc` file.
