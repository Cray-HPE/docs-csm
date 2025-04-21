# Procedure to identify the placement discovery of Master, Worker and Storage Management nodes

This document and the procedures contained within it are for the purposes of identifying the placement discovery (racks/ cabinets) of Master,
Worker and Storage nodes and to further use the placement discovery to perform k8s zoning for master and worker nodes and ceph zoning for
storage nodes.

This procedure internally uses HSM and SLS as the source to get the rack to node mapping. 

## Procedure

1. Execute the script `rack_to_node_mapping.py` to get the rack to node mapping info.


   ```
   python rack_to_node_mapping.py
   ```

   To read the data from SLS and HSM API endpoints, the keycloak token is mandatory. The above script will initially fetch the keycloak token, then tries to scrap the Master, Worker and Storage node's rack-info from the HSM endpoint. Once the rack and it's corresponding nodes info were mapped, then it will try to get the k8s node name for the corresponding nodes using the SLS endpoint. Finally, this script will project the result as the standard output.

2. Map the nodes (master, worker and storage) to the racks where they belong to by analysing the output of the above step.

   Example output:

   ```text
   {
    "x3000": [
        "ncn-w001",
        "ncn-w005",
        "ncn-w003",
        "ncn-m002",
        "ncn-w004",
        "ncn-m001",
        "ncn-s003",
        "ncn-s004",
        "ncn-s005",
        "ncn-s002"
    ]
    "x3001": [
        "ncn-w002",
        "ncn-m003",
        "ncn-s001"
    ]
   }
   ```

   The above example clearly depicts that there are two racks in the CSM system - x3000 and x3001 and the corresponding master, worker and storage nodes were mapped to the rack ID's.

3. The rack to node mapping info executed in the step-1 will be saved in the file `/tmp/rack_info.txt` which will be used in the further stages of Rack Resiliency including placement validation, zoning etc.,
