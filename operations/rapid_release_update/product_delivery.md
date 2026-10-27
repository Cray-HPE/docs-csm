# Product Delivery and Update CFS Configuration

1. [Execute the IUF `process-media` through `deliver-product` stages](#1-execute-the-iuf-process-media-through-deliver-product-stages)
1. [Update CFS Configuration](#2-update-cfs-configuration)
1. [Next steps](#3-next-steps)

## 1. Execute the IUF `process-media` through `deliver-product` stages

This stage extracts the tarball, validates the product manifest, uploads RPMs to
Nexus, pushes CFS content to gitea, and registers the product in the product
catalog.

1. (`ncn-m001#`) Run from `process-media` through `deliver-product`.

   > **Note:** For csm-security, there are no required manual actions between
   > `pre-install-check` and `deliver-product`, so these stages can be run in a
   > single command.

   ```bash
   iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} run -b process-media -e deliver-product
   ```

   **What happens automatically:**

   - Pre-install-check hook validates prerequisites (CSM version, API health)
   - RPMs are uploaded to a Nexus yum-hosted repository
     (`csm-security-SUSE-<sle-version>`)
   - CFS Ansible content is pushed to a `csm-security` gitea repository
     with a versioned branch
   - Product csm-security is registered in the Cray product catalog

   **Confirm content is loaded:**

   Confirm the new repository has been created in Nexus

   ```bash
   curl -sSk https://packages.local/service/rest/v1/repositories | jq -r '.[] | .name' | grep security
   ```

   Example output:

   ```bash
   csm-security-SUSE-15.7
   ```

## 2. Update CFS Configuration

(`ncn-m001#`) Run the `update-cfs-config` stage with your bootprep configuration.

```bash
iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} run \
   -bm ${BOOTPREP_FILE} -sv ${SITE_VARS} -rv ${RECIPE_VARS} \
   -r update-cfs-config
```

## 3. Next steps

- Return to the
  [Deploying Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
