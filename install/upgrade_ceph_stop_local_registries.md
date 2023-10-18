# Upgrade Ceph and stop local Docker registries

> **IMPORTANT** If performing a fresh install of CSM 1.3.0, 1.3.1, 1.3.2, 1.3.3, or 1.3.4, then skip this procedure.
> This procedure should only be done during installs of CSM 1.3 patch version 1.3.5 or later.

This procedure upgrades the Ceph version on storage nodes from `v16.2.9` to `v16.2.13`.
The `v16.2.13` image is in Nexus and after Ceph has been upgraded, all Ceph daemons, except for the
monitoring stack, will be using the image in Nexus. The next step uploads the Ceph monitoring container images
to Nexus and redeploys the Ceph monitoring stack so that they use the images in Nexus. Then the local Docker
registries on storage nodes will be stopped.

## Steps

1. (`ncn-m001#`) Run Ceph upgrade to `v16.2.13`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/ceph/ceph-upgrade-tool.py --version "v16.2.13"
   ```

1. (`ncn-m001#`) Redeploy Ceph monitoring daemons so they are using images in Nexus.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/redeploy_monitoring_stack_to_nexus.sh ncn-s001:/srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh
   ssh ncn-s001 "/srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh"
   ```

1. (`ncn-m001#`) Stop the local Docker registries on all storage nodes.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/disable_local_registry.sh ncn-s001:/srv/cray/scripts/common/disable_local_registry.sh
   ssh ncn-s001 "/srv/cray/scripts/common/disable_local_registry.sh"
   ```
