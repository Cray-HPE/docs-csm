# To enable the Rack Resiliency feature

By default the Rack Resiliency feature will be disabled and the user/admin can enable the Rack Resiliency feature by 
following the below steps.

**Warning:** The Rack Resiliency feature flag has to be enabled before the CSM installation or upgrade is performed.
Enabling this feature will create zones for the master, worker and storage management nodes.

## Procedure

1. Update the `customizations.yaml` file before commencing the CSM installation or upgrade.

   Update the `spec.services.rack-resiliency.enabled` flag from `false` to `true` in the `customizations.yaml` file. This `customizations.yaml` file will be present in the root directory of the CSM tarball.

   During the CSM installation or upgrade, a k8s secret named `site-init` under `loftsman` will be created with the `spec.services.rack-resiliency.enabled` flag enabled. Further, the same secret will be checked for zone creation for Master, Worker and Storage nodes. If the flag is in enabled state, zones will be created else the zones will not be created for Master, Worker and Storage nodes.
