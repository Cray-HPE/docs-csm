## Preparation steps

1. [Start typescript](#1-start-typescript)
1. [Ensure latest documentation installed](#2-ensure-latest-documentation-is-installed)
1. [Health validation](#3-health-validation)
1. [Prepare for the install](#4-prepare-for-the-install)
1. [Upload Product Media](#5-upload-product-media)
1. [Next Steps](#7-next-steps)

### 1. Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with
   the `exit` command.

1. (`ncn-m001#`) Start a typescript.

   ```bash
   script -af /root/rru.$(date +%Y%m%d_%H%M%S).prepare_for_upgrade.txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

If additional shells are opened during this procedure, then record those with typescripts as well.
When resuming a procedure after a break, always be sure that a typescript is running before proceeding.

### 2. Ensure latest documentation is installed

Before following the steps to prepare for the install of RRU, make sure that the latest CSM documentation RPMs are
installed on any NCNs where preparation procedures are being performed. These should be for the **CURRENT**
CSM version on the system -- not the target version of the upgrade.

See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation) for instructions.

### 3. Health validation

1. Validate CSM health.

   Run the CSM health checks to ensure that everything is working properly before the installing RRU starts. After the upgrade is completed, another health check is performed, and it is important to know if any problems observed at that time existed prior to the install.

   Reference [Validate CSM Health](../validate_csm_health.md) for details.

1. Validate Lustre health.

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how
   to validate Lustre health.

### 4. Prepare for the install

1. An operational CSM system at a base version supported by the selected RRU
   (see the [supported CSM baselines](csm-security-rru-overview.md#supported-csm-base-versions)).
1. IUF CLI available on `ncn-m001` (`iuf list-stages`)
1. `sat` CLI available (`sat --version`)
1. A published `csm-security` RRU and its checksum file, qualified for the
   installed CSM and SLE versions.
1. `product_vars.yaml`, `site_vars.yaml`, and the active bootprep file are
   current for the installed recipe and site (see below).

> **IMPORTANT:** IUF resolves template variables in the bootprep file (e.g.,
> `{{csm.version}}`, `{{slingshot_host_software.version}}`) using a
> `session_vars.yaml` that it generates by merging:
>
> 1. The **product catalog** (versions installed on the system)
> 2. Your **`product_vars.yaml`** (recipe variable overrides)
> 3. Your **`site_vars.yaml`** (site-specific settings like naming conventions)
>
> If `product_vars.yaml` contains **stale versions** from a previous recipe
> (e.g., leftover from an earlier CSM install or upgrade), IUF will generate
> CFS configurations with incorrect product versions.
>
> **Before proceeding, verify that your `product_vars.yaml` matches the
> versions actually installed on the system.** The authoritative source is
> your installed recipe's `product_vars.yaml.in` in the
> `hpc-csm-software-recipe` gitea repository (branch matching your recipe
> version). If your system was freshly installed with the current recipe, these
> files should already be correct.

1. (`ncn-m001#`) Set environment variables used throughout this procedure:
   Adjust `BOOTPREP_FILE`, `SITE_VARS`, and `RECIPE_VARS` if your site uses different paths.

```bash
export CSM_SEC_VERSION=@@security_patch_version@@
export VERSION=$(echo $CSM_SEC_VERSION | cut -f6 -d-)
export ACTIVITY_NAME="csm-sec-$VERSION"
export MEDIA_DIR="/etc/cray/upgrade/csm/media/csm-security/${CSM_SEC_VERSION}"
export ADMIN_DIR="/etc/cray/upgrade/csm/admin"
export BOOTPREP_FILE="$ADMIN_DIR/bootprep/management-bootprep.yaml"
export SITE_VARS="$ADMIN_DIR/site_vars.yaml"
export RECIPE_VARS="$ADMIN_DIR/product_vars.yaml"
```

### 5. Upload Product Media

1. (`ncn-m001#`) Create the media directory.

   ```bash
   mkdir -p ${MEDIA_DIR}
   ```

2. Copy the tarball to `ncn-m001`. If the tarball is on a workstation:

   (`workstation#`) Set the required variables and copy the tarball:

   ```bash
   CSM_SEC_VERSION=@@security_patch_version@@
   MEDIA_DIR="/etc/cray/upgrade/csm/media/csm-security/${CSM_SEC_VERSION}"
   scp -p csm-security-${CSM_SEC_VERSION}.tar.gz <ncn-m001>:${MEDIA_DIR}/
   ```

3. (`ncn-m001#`) Create an IUF activity on the master node.

   ```bash
   iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} activity --create in_progress
   ```

Once the above steps are completed:

 - Environment variables have been set and required IUF directories have been created

### 6. Next steps

- Return to the
  [Install Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.