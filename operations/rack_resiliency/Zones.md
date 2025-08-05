# Zones

Rack Resiliency defines a logical grouping of master, worker and storage nodes(NCNs) in a single rack as a zone. The racks which supports only non-NCNs, do not fall in the category of Rack Resiliency zones. During the setup of Rack Resiliency, it is validated that any zone should include the following minimal hardware:
* 1 Kubernetes Master node
* 1 Kubernetes Worker node
* 1 Ceph Storage node

The above minimal hardware constitutes management failure domains(`MFDs`). The zoning is done to ensure `MFDs` are configured based on their physical placement in the racks.

Rack Resiliency supports two type of zones:
* Kubernetes Zone, which helps to split replicas of critical services across racks.
* Ceph Zone, which helps to split utility storage across racks (Ceph uses the concept of buckets to isolate storage. However, rack resiliency uses the term zone to refer to the buckets spread across racks for consistency)

For knowing more about kubernetes zoning, refer to [k8s documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) and for knowing more about ceph zoning, refer to [ceph documentaion](https://docs.ceph.com/en/reef/architecture/)

## Zoning Kubernetes NCNs

The Kubernetes topology zoning can be used to apply labels to the racks and nodes in order to create management failure domains (`MFDs`).

The node is labeled with the key `topology.kubernetes.io/zone=<zone-id>`, where `<zone-id>` is of the form `Rack-1`, `Rack-2`, and so on. These labels can be used to identify all the management nodes which belong to the same zone and is used to schedule the critical services across the zones.

### Command to view kubernetes zones

To view kubernetes zones use the below command:
```bash
(ncn-mw#) kubectl get nodes -L topology.kubernetes.io/zone
```

## Zoning Ceph NCNs

Similar to Kubernetes topology zoning (for Master and Worker), Ceph zoning is required on Storage nodes (Utility storage nodes) for creating management failure domains (`MFDs`). 
The objective of Ceph zoning is to make sure Ceph data gets replicated at rack level across Storage nodes, so that there is no data loss in case of a rack failure.

Ceph provides the CRUSH map algorithm which can help segregate the storage nodes across zones. Using a combination of CRUSH rules and bucket types (hosts, racks, rows, etc.), 
the data can be replicated across zones. 

## 1 Creating Ceph zones with CRUSH

* Create Ceph zones (i.e.,ceph bucket of type `rack`) and map storage nodes to these zones using
    * `ceph osd crush add-bucket <rack_name> rack`
    * `ceph osd crush move {rack_name} root=default`
    * `ceph osd crush move {storage_node} rack={rack_name}`
* Create a CRUSH rule with rack as a failure domain
* Map this CRUSH rule to replicated Ceph pools

## 2 Ceph service zoning

Along with Ceph data zoning, Ceph services also need to be zoned.

The current Ceph setup on CSM deploys three sets of Ceph services (Monitors, Managers, and MDS) on the nodes `ncn-s001`, `ncn-s002`, and `ncn-s003` in a hard-coded configuration. 
This approach, however, does not support Rack Resiliency, as the services are statically assigned to specific nodes.

To enhance Rack Resiliency, the new solution distributes the Ceph services across multiple racks. The storage nodes assigned to each service will be selected using a round-robin distribution strategy across the racks, ensuring a balanced and fault-tolerant configuration. Also, the number of Ceph Monitor services deployed will be either 3 or 5, depending on the total number of storage nodes and their distribution across racks. The above process ensures that the Ceph cluster remains operational in the event of a rack failure.

### Command to view ceph zones

To view ceph zones use the below command:
```bash
(ncn-mw#) ceph osd tree | grep rack
```

## Managing Zones

To view and get details about the rack resiliency zones use the below Cray CLI commands:

* List all configured zones:

    ```bash
    (`ncn-mw#`) cray rrs zones list
    ```

  Example Output:
    ```bash
    ncn-m001:~ # cray rrs zones list
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

* Get detailed information about a specific zone:

    ```bash
    (`ncn-mw#`) cray rrs zones describe <zone-id>
    ```

  Example Output:
    ```bash
    ncn-m001:~ # cray rrs zones describe x3000
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