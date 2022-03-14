# Stage 3 - CSM Service Upgrades

## Upgrade CSM Services

**IMPORTANT:**

> During this stage there will be a brief (approximately 5 minutes) window where pods with PVCs will not be able to migrate between nodes. This is due to a redeployment of the Ceph csi provisioners into namespaces to accommodate the newer charts and a better upgrade strategy.

Run `csm-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-upgrade.sh
```
## Update the CSM Configuration Management Repository

1. Obtain the VCS login credentials.

   ```bash
   ncn-m002# VCS_USER=$(kubectl -n services get secret vcs-user-credentials -o jsonpath='{.data.vcs_username}' | base64 --decode)
   ncn-m002# VCS_PASSWORD=$(kubectl -n services get secret vcs-user-credentials -o jsonpath='{.data.vcs_password}' | base64 --decode)
   ```

1. Clone the CSM configuration management repository.

   ```bash
   ncn-m002# git clone https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git
   ```

1. Obtain import_branch of new release from the cray-product-catalog Kubernetes ConfigMap

   In the following example, the import branch is `cray/csm/1.9.21`.

   ```bash
   ncn-m002# kubectl -n services get cm cray-product-catalog -o json | jq -r '.data.csm'
   ...
   1.2.0:
     active: true
     configuration:
       clone_url: https://vcs.cmn.shasta.dev.cray.com/vcs/cray/csm-config-management.git
       commit: 5616de1ffd375ac94a0f9c51f65dee3063b6be6e
       import_branch: cray/csm/1.9.21
       import_date: 2022-03-10 13:47:56.929802
       ssh_url: git@vcs.cmn.shasta.dev.cray.com:cray/csm-config-management.git
     images:
       cray-shasta-csm-sles15sp3-barebones.x86_64-csm-1.2:
         id: 4d82f5fc-006b-4390-9d7f-b2f488635e66
     recipes:
       cray-shasta-csm-sles15sp3-barebones.x86_64-csm-1.2:
         id: 9f6d9a43-148a-48f9-bec1-b3dbc4ec25d6
   ```

1. Ensure content is up to date.

   ```bash
   ncn-m002# cd csm-config-management && git checkout cray/csm/PRODUCT_VERSION && git pull
   Branch 'cray/csm/PRODUCT_VERSION' set up to track remote branch 'cray/csm/PRODUCT_VERSION' from 'origin'.
   Switched to a new branch 'cray/csm/PRODUCT_VERSION'
   Already up to date.
   ```

1. Create or update a working branch using the updated content installed during the upgrade.

   ```bash
   ncn-m002# git checkout -b integration && git merge cray/csm/PRODUCT_VERSION
   Switched to a new branch 'integration'
   Already up to date.
   ```

   Resolve any merge conflicts as necessary.

1. Push the changes to the repository.

   ```bash
   ncn-m002# git push --set-upstream origin integration
   ```

1. Capture most recent commit to use to update the CFS configuration and perform NCN Personalization.

   ```bash
   ncn-m002# git rev-parse --verify HEAD
   5616de1ffd375ac94a0f9c51f65dee3063b6be6e
   ```

1. Update the CFS configuration and perform NCN personalization.

   Refer to the [Perform NCN Personalization](../../operations/CSM_product_management/Perform_NCN_Personalization.md) procedure to update the CFS configuration and run NCN Personalization.

   If multiple products are being upgraded then it may be desirable to delay running NCN personalization until all products are installed and have had their CFS layers updated.

Once `Stage 3` is completed, proceed to [Stage 4](Stage_4.md)
