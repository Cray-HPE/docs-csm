# Zones

- [Overview](#overview)
- [Zone names](#zone-names)
    - [Zone name prefix reasons](#zone-name-prefix-reasons)
    - [Zone name prefix restrictions](#zone-name-prefix-restrictions)
- [Kubernetes zones](#kubernetes-zones)
    - [Viewing Kubernetes zones](#viewing-kubernetes-zones)
- [Ceph zones](#ceph-zones)
    - [Ceph service zoning](#ceph-service-zoning)
    - [Viewing Ceph zones](#viewing-ceph-zones)
- [Managing zones](#managing-zones)
    - [Listing zones](#listing-zones)
    - [Describing a zone](#describing-a-zone)

## Overview

A **zone** in the Rack Resiliency solution is [Failure domain](README.md#failure-domain). Specifically, it is
a representation of a Management Plane Failure Domain (MPFD). In general for CSM, a MPFD constitutes one or more
racks that contain CSM management nodes. Managed nodes are not considered in MPFDs.

In Rack Resiliency, if placement validation is successful, then a MPFD will always consist of a single rack. That
rack will contain, at minimum, 1 Kubernetes master NCN, 1 Kubernetes worker NCN, and 1 Ceph storage NCN.

Rack Resiliency maps its zones into both the Kubernetes cluster and Ceph cluster.

## Zone names

By default, Rack Resiliency zone names will be the component name ([xname](../../glossary.md#xname)) of
the associated [physical rack](README.md#physical-racks) (which will be the same as the first 5 characters
of the xnames of the associated NCNs. For example, `x3000` or `x3001`.

When first [Enabling and configuring](README.md#enable-and-configure) Rack Resiliency, administrators can
optionally specify prefixes to be used for Kubernetes zone names, Ceph zone names, or both. These prefixes
will be prepended to the default zone names described above, separated by a dash (`-`) character
(e.g. `myprefix-x3002`).

**NOTE:** Prefixes can only be specified during the initial enablement process. They cannot be
changed, removed, or set later.

### Zone name prefix reasons

One reason an administrator may wish to do this is because xnames are not unique across different CSM
systems. Because of this, an administrator may wish to use a system-specific identifier as a zone prefix,
to differentiate between zones on different systems.

For Ceph zones specifically, an administrator may need to do this if their Ceph cluster already has
any bucket whose name would collide with the default zone names (Ceph bucket names are required to
be unique, and as part of zoning, Ceph buckets are created for each zone).

### Zone name prefix restrictions

Zone name prefixes are not required. If a non-empty zone name prefix is specified, then it must
conform to some restrictions.

Zone names overall are required to be between no longer than 63 characters. Because the base zone names
are always 5 characters long, and accounting for the `-` separator, this means that zone prefix names
must be no more than 57 characters long.

In addition, zone prefixes must obey the following restrictions:

- Minimum of 1 character long
- Must begin and end with a lowercase alphanumeric character (i.e. `a-z0-9`)
- Only other legal characters are dash (`-`) and dot (`.`)
- The resulting zone name must be valid both as a Ceph bucket name and as a Kubernetes label value
    - See [Bucket Operations](https://docs.ceph.com/en/latest/radosgw/s3/bucketops/)
      for details on legal Ceph bucket names.
    - See [Syntax and character set](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set)
      for details on legal Kubernetes label values.

**NOTE**: These restrictions are not checked or enforced. If they are not followed, then any
failures are most likely to be encountered during
[Setup of Rack Resiliency](Setup_of_Rack_Resiliency.md).

## Kubernetes zones

For Kubernetes, Rack Resiliency uses the concept of
[topology spread constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
to implement zoning of master and worker NCNs.

The Kubernetes topology spread constraints are used to apply labels to nodes, in order to create Kubernetes zones.

Each node in every zone is labeled with the key `topology.kubernetes.io/zone` and value `<zone-id>`, where
`<zone-id>` is the Kubernetes [zone name](#zone-names). These labels can be used to identify all the management
nodes which belong to the same Kubernetes zone, and are used to schedule the critical services across the zones.

### Viewing Kubernetes zones

`(ncn-mw#)` View Kubernetes zones.

```bash
kubectl get nodes -L topology.kubernetes.io/zone
```

Example output:

```text
NAME       STATUS   ROLES           AGE   VERSION   ZONE
ncn-m001   Ready    control-plane   21d   v1.32.5   x3000
ncn-m002   Ready    control-plane   20d   v1.32.5   x3001
ncn-m003   Ready    control-plane   20d   v1.32.5   x3002
ncn-w001   Ready    <none>          20d   v1.32.5   x3000
ncn-w002   Ready    <none>          20d   v1.32.5   x3001
ncn-w003   Ready    <none>          20d   v1.32.5   x3002
ncn-w004   Ready    <none>          20d   v1.32.5   x3000
```

## Ceph zones

Ceph is the utility storage platform that is used to enable pods to store persistent data. It is
deployed to provide block, object, and file storage to the management services running on Kubernetes,
as well as for telemetry data coming from the compute nodes.

For Ceph, Rack Resiliency uses the [concept of buckets](https://docs.ceph.com/en/reef/architecture/)
built with the [CRUSH](https://docs.ceph.com/en/latest/rados/operations/crush-map/) algorithm to
implement zoning for storage nodes.

The objective of Ceph zoning is to make sure Ceph data gets replicated at the zone level across
storage nodes, so that there is no data loss in case of a rack failure. Ceph provides the CRUSH map
algorithm, which helps to segregate the data across zones. Using a combination of CRUSH rules and
bucket types (`host`, `rack`, `row`, etc.), the data is replicated across zones.

![Hierarchy of CRUSH buckets (`rack`, `host`, `osd`) before and after Ceph zoning](../../img/Ceph-Zone.png)

In the absence of Rack Resiliency, CSM has `host` as the top of the hierarchy of Ceph buckets.
To implement Ceph zones for storage nodes, the new bucket `rack` is introduced on top of the hierarchy.
As shown in the above diagram, storage nodes get added to a `rack` bucket based on their physical
location. The name of the `rack` buckets is its Ceph [zone name](#zone-names).

See [Placement discovery](Setup_of_Rack_Resiliency.md#placement-discovery) for details on how physical
placement of storage nodes is discovered.

More than one storage node can be added to the same bucket.

Rack Resiliency preconfigures `rack` buckets and adds the storage nodes to them.
During [Ceph zoning](Setup_of_Rack_Resiliency.md#ceph-zoning), the nodes discovered
during placement discovery are grouped in `rack` buckets.

### Ceph service zoning

The current Ceph setup on CSM deploys three sets of Ceph services (Monitors, Managers, and MDS) on the
nodes `ncn-s001`, `ncn-s002`, and `ncn-s003` in a hard-coded configuration.
This approach, however, does not support Rack Resiliency, as the services are statically assigned to
specific nodes.

The Rack Resiliency solution distributes the Ceph services across multiple zones.
The storage nodes assigned to each service are selected using a round-robin distribution strategy across
the zones (i.e. `rack` buckets), ensuring a balanced and fault-tolerant configuration.

The number of Ceph Monitor services deployed will be either 3 or 5, depending on the total number of storage
nodes and their distribution across `rack` buckets.

The above process ensures that the Ceph cluster remains operational in the event of a
[physical rack](README.md#physical-racks) failure.

The Ceph services are zoned during [Ceph zoning](Setup_of_Rack_Resiliency.md#ceph-zoning).

### Viewing Ceph zones

(`ncn-msw#`) View Ceph zones.

```bash
ceph osd tree | grep rack
```

Example output:

```text
 -9         13.97278      rack x3000
-11         13.97278      rack x3001
-13         13.97278      rack x3002
```

## Managing zones

### Listing zones

(`ncn-mw#`) List all configured zones.

```bash
cray rrs zones list --format toml
```

Example output:

```toml
[[Zones]]
Zone_Name = "x3000"

[Zones.Kubernetes_Topology_Zone]
Management_Master_Nodes = [ "ncn-m001",]
Management_Worker_Nodes = [ "ncn-w001", "ncn-w004",]
[Zones.CEPH_Zone]
Management_Storage_Nodes = [ "ncn-s001",]
[[Zones]]
Zone_Name = "x3001"

[Zones.Kubernetes_Topology_Zone]
Management_Master_Nodes = [ "ncn-m002",]
Management_Worker_Nodes = [ "ncn-w002",]
[Zones.CEPH_Zone]
Management_Storage_Nodes = [ "ncn-s003",]
[[Zones]]
Zone_Name = "x3002"

[Zones.Kubernetes_Topology_Zone]
Management_Master_Nodes = [ "ncn-m003",]
Management_Worker_Nodes = [ "ncn-w003",]
[Zones.CEPH_Zone]
Management_Storage_Nodes = [ "ncn-s002",]
```

### Describing a zone

(`ncn-mw#`) Get detailed information about a specific zone.

```bash
cray rrs zones describe <zone-id> --format toml
```

Example output:

```toml
Zone_Name = "x3000"

[Management_Master]
Count = 1
Type = "Kubernetes_Topology_Zone"
[[Management_Master.Nodes]]
name = "ncn-m001"
status = "Ready"

[Management_Worker]
Count = 2
Type = "Kubernetes_Topology_Zone"
[[Management_Worker.Nodes]]
name = "ncn-w001"
status = "Ready"

[[Management_Worker.Nodes]]
name = "ncn-w004"
status = "Ready"

[Management_Storage]
Count = 1
Type = "CEPH_Zone"
[[Management_Storage.Nodes]]
name = "ncn-s001"
status = "Ready"

[Management_Storage.Nodes.osds]
up = [ "osd.1", "osd.4", "osd.7", "osd.10", "osd.13", "osd.16", "osd.20", "osd.23",]
```

This command returns detailed information about the zone, including the Kubernetes and storage NCNs that
belong to it, along with their statuses.
