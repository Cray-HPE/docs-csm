# Pre Service Upgrade

These steps should be run prior to running the upgrade.sh in Stage 4.

1. Run the pre-service-upgrade.sh script to prepare for resize of PVCs for cray-smd, keycloak and spire postgres clusters

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/postgres-operator/pre-service-upgrade.sh
   ```
2. Verify the output from the above script returns 'Completed'.

3. [Back to Main Page](../../README.md) to proceed with Stage 4. 
