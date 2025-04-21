# To define the k8s and ceph zone prefixes

User/ Admin can specify the prefixes for the k8s and ceph zones to be created. This will help them to created and visualize a each racks as a separate zones with their own specified labels.

**Warning:** The k8s and ceph zones prefixes has to be specified before the CSM installation or upgrade is performed.
Specifying these prefixes will create the zones for k8s and ceph accordingly with the prefixes added to the zone labels.

## Procedure

1. Update the `customizations.yaml` file before commencing the CSM installation or upgrade.

   `k8s zone prefix updation`: Update the `spec.services.k8s_zone_prefix` section in the `customizations.yaml` file with the required k8s zone prefix. This `customizations.yaml` file will be present in the root directory of the CSM tarball.

   `ceph zone prefix updation`: Update the `spec.services.ceph_zone_prefix` section in the `customizations.yaml` file with the required ceph zone prefix. This `customizations.yaml` file will be present in the root directory of the CSM tarball.  

   During the CSM installation or upgrade, a k8s secret named `site-init` under `loftsman` will be created with the prefixes updated in the fields `spec.services.k8s_zone_prefix` and `spec.services.ceph_zone_prefix`. Further, the same secret will be checked for zone label prefixes during the k8s and ceph zone creation for Master, Worker and Storage nodes. If the prefixes is defined, then the zones will be created in the format of `k8s_zone_prefix + rack_id` and `ceph_zone_prefix + rack_id`.

   Sample Output:

   If the `spec.services.k8s_zone_prefix` has a value of `test-system` and the rack-id is `x3000`, then the k8s zones will be created with the labels of value `test-system-x3000`

   If the `spec.services.ceph_zone_prefix` has a value of `test-storage-system` and the rack-id is `x3000`, then the ceph zones will be created with the labels of value `test-storage-system-x3000`

   If the `spec.services.k8s_zone_prefix` has no value defined and the rack-id is `x3000`, then the k8s zones will be created with the labels of value `x3000`

   If the `spec.services.ceph_zone_prefix` has no value defined and the rack-id is `x3000`, then the ceph zones will be created with the labels of value `x3000`
