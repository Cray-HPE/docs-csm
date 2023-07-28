# Upgrade Ceph and enable `Smartmon` metrics on storage NCNs

This procedure upgrades the Ceph version on storage nodes from `v16.2.9` to `v16.2.13`.
The `v16.2.13` image is in Nexus and after Ceph has been upgraded, all Ceph daemons, except for the
monitoring stack, will be using the image in Nexus. The next step uploads the Ceph monitoring container images
to Nexus and redeploys the Ceph monitoring stack so that they use the images in Nexus. Then the local Docker
registries on storage nodes will be stopped. Finally, `Smartmon` metrics will be enabled on Storage nodes.

## Steps

1. [Upgrade Ceph and stop local Docker registries](#1-upgrade-ceph-and-stop-local-docker-registries)
1. [Enable `Smartmon` Metrics on Storage NCNs](#2-enable-smartmon-metrics-on-storage-ncns)

## 1. Upgrade Ceph and stop local Docker registries

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

## 2. Enable `Smartmon` Metrics on Storage NCNs

This step will install the `smart-mon` rpm on storage nodes, and reconfigure the `node-exporter` to provide `smartmon` metrics.

1. (`ncn-m001#`) Execute the following script.

   ```bash
   /usr/share/doc/csm/scripts/operations/ceph/enable-smart-mon-storage-nodes.sh
   ```
