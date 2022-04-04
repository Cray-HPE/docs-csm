# Stage 3 - CSM Service Upgrades

1. Prepare assets:


   ```bash
    ncn-m002# CSM_RELEASE=csm-1.2.0
   ```

   - Internet connected:

     ```bash
     ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint [ENDPOINT]
     ```

   - Air Gapped (replace the PATH_TO below with the location of the rpm)

     ```bash
     ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file [PATH_TO_CSM_TARBALL_FILE]
     ```

1. Run `csm-upgrade.sh` to deploy upgraded CSM applications and services:
    **IMPORTANT:**

    > During this stage there will be a brief (approximately 5 minutes) window where pods with PVCs will not be able to migrate between nodes. This is due to a redeployment of the Ceph csi provisioners into namespaces to accommodate the newer charts and a better upgrade strategy.

    > Set the `SW_ADMIN_PASSWORD` environment variable to the admin password for the switches. This is needed for post upgrade tests.

    ```bash
    ncn-m002# export SW_ADMIN_PASSWORD=sw1tCH@DM1Np4s5w0rd
    ```

    ```bash
    ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-upgrade.sh
    ```

Once `Stage 3` is completed, proceed to [Stage 4](Stage_4.md)
