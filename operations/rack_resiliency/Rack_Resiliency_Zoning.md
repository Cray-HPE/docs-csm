# Resiliency Testing Procedure

This document and the procedures contained within it are for the purposes of creating zones for Master, Worker and Storage nodes.
Master and Worker nodes are zoned using k8s I/O topology zoning labels and the storage nodes are zoned using CRUSH map algorithm configurations.


## Prerequisites

Rack to Node mapping script `rack_to_node_mapping.py` should have been executed and the rack to node mapping info should be present in the file 
`/tmp/rack_info.txt` which will be consumed by the zoning scripts to create respective zones. 


## K8S Zoning for Master and Worker Nodes

1. Execute the script `create_k8s_zones.py` to create k8s zoning for master and worker nodes.

   ```
   python create_k8s_zones.py
   ```

   This script will initially try to get any k8s zones label prefix defined by the admin in the `customizations.yaml` file. If nothing is defined in the `customizations.yaml` file it will create a k8s zone label with just the rack-id. Once the prefix is identified, this script will get the placement discovery of the Master and Worker nodes using the `rack_to_node_mapping.py` scripts output and will create the k8s zones accordingly.

   Example Output:

   Here the admin/ user has defined the k8s zone label prefix as lab1 and 3 racks (x3000, x3001 and x3002) are present.

   The rack to node mappings are as below:

   Rack x3000 : ncn-m001, ncn-w001, ncn-w003, ncn-w005

   Rack x3001 : ncn-w004

   Rack x3002 : ncn-m003, ncn-m002

   ```text
   Node ncn-m001 is going to be placed on lab1-x3000
   Node ncn-w001 is going to be placed on lab1-x3000
   Node ncn-w003 is going to be placed on lab1-x3000
   Node ncn-w005 is going to be placed on lab1-x3000
   Node ncn-w002 is going to be placed on lab1-x3000
   Node ncn-w004 is going to be placed on lab1-x3001
   Node ncn-m003 is going to be placed on lab1-x3002
   Node ncn-m002 is going to be placed on lab1-x3002
   ```

2. Check the zones created by executing the following command:

   ```bash
   kubectl get nodes -l topology.kubernetes.io/zone=<zonePrefix-rackId>
   ```

   Example Output:

   ```text
   ncn-m001:~ # kubectl get nodes -l topology.kubernetes.io/zone=lab1-x3000
   NAME       STATUS   ROLES           AGE   VERSION
   ncn-m001   Ready    control-plane   64d   v1.24.17
   ncn-w001   Ready    <none>          44h   v1.24.17
   ncn-w002   Ready    <none>          44h   v1.24.17
   ncn-w003   Ready    <none>          44h   v1.24.17
   ncn-w005   Ready    <none>          41h   v1.24.17

   ncn-m001:~ # kubectl get nodes -l topology.kubernetes.io/zone=lab1-x3001
   NAME       STATUS   ROLES           AGE   VERSION
   ncn-w004   Ready    <none>          42h   v1.24.17

   ncn-m001:~ # kubectl get nodes -l topology.kubernetes.io/zone=lab1-x3002
   NAME       STATUS   ROLES           AGE   VERSION
   ncn-m002   Ready    control-plane   65d   v1.24.17
   ncn-m003   Ready    control-plane   65d   v1.24.17

## Ceph Zoning for storage nodes

1. Execute the script `ceph_zoning.py` to create ceph zoning for storage nodes.

   ```
   python ceph_zoning.py <rack_placement_file>
   ```

   Here `rack_placement_file` is the output of the `rack_to_node_mapping.py` script. 

   This script will initially try to get any ceph zones label prefix defined by the admin in the `customizations.yaml` file. If nothing is defined in the `customizations.yaml` file it will create a ceph zone label with just the rack-id.

   Example Output:

   Rack to node mappings are as below:

   Rack x3000 : ncn-s001

   Rack x3001 : ncn-s003, ncn-s004

   Rack x3002 : ncn-s002

   ``` text
   2025-04-17 11:23:04,101 - INFO - Running command: kubectl -n loftsman get secret site-init -o json
   2025-04-17 11:23:04,274 - INFO - Running command: yq r /tmp/customizations.yaml spec.kubernetes.services.ceph_zone_prefix
   2025-04-17 11:23:04,294 - INFO - Creating bucket for rack: x3000
   2025-04-17 11:23:04,294 - INFO - Running command: ceph osd crush add-bucket x3000 rack
   2025-04-17 11:23:05,010 - INFO - Running command: ceph osd crush move x3000 root=default
   2025-04-17 11:23:05,727 - INFO - Moving storage node ncn-s001 to rack x3000
   2025-04-17 11:23:05,728 - INFO - Running command: ceph osd crush move ncn-s001 rack=x3000

   2025-04-17 11:23:06,450 - INFO - Running command: kubectl -n loftsman get secret site-init -o json
   2025-04-17 11:23:06,638 - INFO - Running command: yq r /tmp/customizations.yaml spec.kubernetes.services.ceph_zone_prefix
   2025-04-17 11:23:06,658 - INFO - Creating bucket for rack: x3001
   2025-04-17 11:23:06,658 - INFO - Running command: ceph osd crush add-bucket x3001 rack
   2025-04-17 11:23:07,389 - INFO - Running command: ceph osd crush move x3001 root=default
   2025-04-17 11:23:08,110 - INFO - Moving storage node ncn-s004 to rack x3001
   2025-04-17 11:23:08,111 - INFO - Running command: ceph osd crush move ncn-s004 rack=x3001
   2025-04-17 11:23:08,834 - INFO - Moving storage node ncn-s003 to rack x3001
   2025-04-17 11:23:08,835 - INFO - Running command: ceph osd crush move ncn-s003 rack=x3001

   2025-04-17 11:23:09,706 - INFO - Running command: yq r /tmp/customizations.yaml spec.kubernetes.services.ceph_zone_prefix
   2025-04-17 11:23:09,726 - INFO - Creating bucket for rack: x3002
   2025-04-17 11:23:09,726 - INFO - Running command: ceph osd crush add-bucket x3002 rack
   2025-04-17 11:23:10,438 - INFO - Running command: ceph osd crush move x3002 root=default
   2025-04-17 11:23:11,166 - INFO - Moving storage node ncn-s005 to rack x3002
   2025-04-17 11:23:11,167 - INFO - Running command: ceph osd crush move ncn-s005 rack=x3002
   2025-04-17 11:23:11,888 - INFO - Moving storage node ncn-s002 to rack x3002
   2025-04-17 11:23:11,889 - INFO - Running command: ceph osd crush move ncn-s002 rack=x3002

   ...
   ...
   ...
   ```

2. Check the ceph zones created by executing the following command:

   ```bash
   ceph osd tree
   ```

   Example Output:

   The below output sample show, three racks configuration and theie storage node distributions within the three racks.

   Rack x3000 : ncn-s001

   Rack x3001 : ncn-s003, ncn-s004

   Rack x3002 : ncn-s002

   ```text

   ncn-m001:~ # ceph osd tree
   ID   CLASS  WEIGHT    TYPE NAME                 STATUS  REWEIGHT  PRI-AFF
   -1         48.90472  root default
   -13                0      rack cscs-rack-x3000
   -15                0      rack cscs-rack-x3001
   -17                0      rack cscs-rack-x3002
   -19         13.97278      rack x3000
    -7         13.97278          host ncn-s001
    3    ssd   1.74660              osd.3             up   1.00000  1.00000
    7    ssd   1.74660              osd.7             up   1.00000  1.00000
   11    ssd   1.74660              osd.11            up   1.00000  1.00000
   14    ssd   1.74660              osd.14            up   1.00000  1.00000
   17    ssd   1.74660              osd.17            up   1.00000  1.00000
   20    ssd   1.74660              osd.20            up   1.00000  1.00000
   22    ssd   1.74660              osd.22            up   1.00000  1.00000
   25    ssd   1.74660              osd.25            up   1.00000  1.00000
   -21         17.46597      rack x3001
   -11         13.97278          host ncn-s003
    4    ssd   1.74660              osd.4             up   1.00000  1.00000
    9    ssd   1.74660              osd.9             up   1.00000  1.00000
   12    ssd   1.74660              osd.12            up   1.00000  1.00000
   15    ssd   1.74660              osd.15            up   1.00000  1.00000
   18    ssd   1.74660              osd.18            up   1.00000  1.00000
   21    ssd   1.74660              osd.21            up   1.00000  1.00000
   24    ssd   1.74660              osd.24            up   1.00000  1.00000
   27    ssd   1.74660              osd.27            up   1.00000  1.00000
   -3          3.49319          host ncn-s004
   0    ssd   1.74660              osd.0             up   1.00000  1.00000
    5    ssd   1.74660              osd.5             up   1.00000  1.00000
   -23         17.46597      rack x3002
   -9         13.97278          host ncn-s002
   2    ssd   1.74660              osd.2             up   1.00000  1.00000
   8    ssd   1.74660              osd.8             up   1.00000  1.00000
   10    ssd   1.74660              osd.10            up   1.00000  1.00000
   13    ssd   1.74660              osd.13            up   1.00000  1.00000
   16    ssd   1.74660              osd.16            up   1.00000  1.00000
   19    ssd   1.74660              osd.19            up   1.00000  1.00000
   23    ssd   1.74660              osd.23            up   1.00000  1.00000
   26    ssd   1.74660              osd.26            up   1.00000  1.00000
   -5          3.49319          host ncn-s005
    1    ssd   1.74660              osd.1             up   1.00000  1.00000
    6    ssd   1.74660              osd.6             up   1.00000  1.00000

   ```
