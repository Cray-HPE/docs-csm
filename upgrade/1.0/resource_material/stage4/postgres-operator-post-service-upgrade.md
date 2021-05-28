# Post Service Upgrade

These steps should be run after running the upgrade.sh in Stage 4.

1. Run the post-service-upgrade.sh script to complete the cray-smd-postgres cluster PVCs for resize.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/postgres-operator/post-service-upgrade.sh
   ```
2. Verify the output from the above script returns 'Successful'.

3. [Back to Main Page](../../README.md) to proceed with Stage 4.
