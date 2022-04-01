# Stage 3 - CSM Service Upgrades

1. Install latest document RPM package and prepare assets:

   > The install scripts will look for the RPM in `/root`, so it is important that you copy it there.

   ```bash
    ncn-m002# CSM_RELEASE=csm-1.2.0
   ```

   - Internet Connected

     ```bash
     ncn-m002# wget https://storage.googleapis.com/csm-release-public/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm -P /root

     ncn-m002# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm

     ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
     ```

   - Air Gapped (replace the PATH_TO below with the location of the rpm)

     ```bash
     ncn-m002# cp [PATH_TO_docs-csm-*.noarch.rpm] /root

     ncn-m002# rpm -Uvh --force /root/docs-csm-*.noarch.rpm

     ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
     ```

1. Run `csm-upgrade.sh` to deploy upgraded CSM applications and services:
    **IMPORTANT:**

    > During this stage there will be a brief (approximately 5 minutes) window where pods with PVCs will not be able to migrate between nodes. This is due to a redeployment of the Ceph csi provisioners into namespaces to accommodate the newer charts and a better upgrade strategy.

    ```bash
    ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-upgrade.sh
    ```

Once `Stage 3` is completed, proceed to [Stage 4](Stage_4.md)
