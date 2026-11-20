# Configure SAT bootprep CFS Layers

Before running any IUF stages that use `sat bootprep`, you must add the
`csm-security` layer to your bootprep input file.

1. (`ncn-m001#`) Locate your management node bootprep configuration.

   If a previous CSM install or upgrade has been performed, the bootprep
   file is typically already in your admin directory (e.g.,
   `/etc/cray/upgrade/csm/admin/`). This may be a site-customized
   version of the default recipe bootprep, or a completely custom file.
   Identify whichever bootprep file is actively used for your
   management node CFS configurations.

   If no bootprep file exists yet, clone the recipe repo from Gitea:

   > **WARNING:** The recipe repo contains the default bootprep file.
   > If any customizations were made to your bootprep configuration
   > previously, using this default file will lose those customizations.

   ```bash
   VCS_USERNAME=$(kubectl get secret -n services vcs-user-credentials   -o jsonpath={.data.vcs_username} |  base64 -d)
   VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials \
     -o jsonpath={.data.vcs_password} | base64 -d)
   git clone "https://${VCS_USERNAME}:${VCS_PASSWORD}@api-gw-service-nmn.local/vcs/cray/hpc-csm-software-recipe.git"
   cd hpc-csm-software-recipe
   git branch -r  # list available recipe versions
   git checkout cray/hpc-csm-software-recipe/<recipe-version>
   cd bootprep 
   ```

   The recipe version branch corresponds to the software recipe
   release delivered with your CSM install.

2. (`ncn-m001#`) Edit the bootprep file to add the `csm-security` layer to
   **every** configuration whose images should receive security patches —
   typically both the management configuration (master/worker images) and
   the storage configuration (storage images).

   > **Important:** Place the `csm-security` layer immediately **after** the
   > CSM base layer (`ncn_nodes.yml`) and **before** all other product layers
   > and `ncn-initrd.yml`. Security patches must be applied first so
   > subsequent layers build on the patched base. The `ncn-initrd.yml` layer
   > must always remain last because it regenerates the initrd.

   Example for master/worker nodes:

   ```yaml
   configurations:
   - name: "{{default.note}}management-{{recipe.version}}{{default.suffix}}"
     layers:
     - name: csm-ncn-nodes-{{csm.version}}
       playbook: ncn_nodes.yml
       product:
         name: csm
         version: "{{csm.version}}"
     # Add this layer immediately after the CSM base layer:
     - name: csm-security
       playbook: pb_cfs_security_install.yml
       product:
         name: csm-security
         version: "{{csm_security.version}}"
     # ... remaining product layers (SHS, USS, CSM-Diags, SMA, etc.)
     # ncn-initrd.yml must remain last
     - name: csm-ncn-initrd-{{csm.version}}
       playbook: ncn-initrd.yml
       product:
         name: csm
         version: "{{csm.version}}"
   ```

   Example for storage nodes:

   ```yaml
   # this configuration can be used to personalize the storage nodes with SMA and Diags
   - name: "{{default.note}}storage-{{recipe.version}}{{default.suffix}}"
     layers:
     - name: csm-ncn-nodes-{{csm.version}}
       playbook: ncn_nodes.yml
       product:
         name: csm
         version: "{{csm.version}}"
     # Add this layer immediately after the CSM base layer:
     - name: csm-security
       playbook: pb_cfs_security_install.yml
       product:
         name: csm-security
         version: "{{csm_security.version}}"
     # ... remaining product layers (CSM-Diags, SMA, etc.)
     # ncn-initrd.yml must remain last
     - name: csm-ncn-initrd-{{csm.version}}
       playbook: ncn-initrd.yml
       product:
         name: csm
         version: "{{csm.version}}"
   ```

   Example for minimal-management (if present in your bootprep):

   ```yaml
   - name: "{{default.note}}minimal-management-{{recipe.version}}{{default.suffix}}"
    layers:
    - name: csm-ncn-nodes-{{csm.version}}
      playbook: ncn_nodes.yml
      product:
        name: csm
        version: "{{csm.version}}"
    # Add this layer immediately after the CSM base layer:
    - name: csm-security
      playbook: pb_cfs_security_install.yml
      product:
        name: csm-security
        version: "{{csm_security.version}}"
    # ... remaining product layers (if any)
    # ncn-initrd.yml must remain last
    - name: csm-ncn-initrd-{{csm.version}}
      playbook: ncn-initrd.yml
      product:
        name: csm
        version: "{{csm.version}}"
   ```

   > **Note:** Your bootprep file may contain additional configurations
   > beyond the three shown above. Add the `csm-security` layer to
   > **every** configuration that produces images for management nodes —
   > any node booting from these images requires the patched kernel.

   The `{{csm_security.version}}` template variable resolves automatically
   from the product catalog after `IUF deliver-product` registers the product —
   no bootprep edit is needed between future `csm-security` updates.

## Next steps

- Return to the
  [Install Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
