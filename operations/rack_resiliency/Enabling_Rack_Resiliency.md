# Enabling Rack Resiliency

As mentioned in the [Architecture overview](README.md#architecture-overview), enabling Rack Resiliency is the
first stage for setting up Rack Resiliency. By default the Rack Resiliency feature is disabled. Based on whether CSM
is getting freshly installed or upgraded to a new version, use the below steps to enable Rack Resiliency.

**NOTE:**

* Rack Resiliency can be enabled only during fresh install of CSM 1.7 or an upgrade from CSM 1.6 to CSM 1.7.
* Rack Resiliency cannot be disabled after it has been enabled during the install or upgrade.

## Case 1: Fresh install

Follow the steps in [Prepare Site Init](../../install/prepare_site_init.md#enable-rack-resiliency) to enable
Rack Resiliency and optionally add prefixes for Kubernetes and Ceph zones.

## Case 2: Upgrade

Follow the steps in [Management Rollout](../../operations/iuf/workflows/management_rollout.md#enabling-rack-resiliency-and-add-zone-prefixes) to enable
Rack Resiliency and optionally add prefixes for Kubernetes and Ceph zones.
