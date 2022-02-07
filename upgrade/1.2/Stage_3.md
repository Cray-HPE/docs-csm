# Stage 3 - CSM Service Upgrades

**IMPORTANT:**

>During this stage there will be a brief approximately 5 minute window where pods with PVCs will not be able to migrate between nodes.  This is due to a redeployment of the ceph csi provisioners into namespaces to accomodate the newer charts and a better upgrade strategy.

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-service-upgrade.sh
```

Once `Stage 3` service upgrade is complete, proceed to [Stage 4](Stage_4.md)
