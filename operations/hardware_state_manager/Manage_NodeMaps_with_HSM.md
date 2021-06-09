## Manage NodeMaps with HSM

The Hardware State Manager \(HSM\) allows NodeMap files to be uploaded that map node xnames to default parameters, which are used when discovering nodes for the first time. The NodeMaps collection is uploaded to HSM automatically at install time by specifying it as a JSON file. As a result, the endpoints are then automatically discovered by REDS, and an inventory discovery is performed by HSM. The desired NID numbers will be set as soon as the nodes are created using the NodeMaps collection.

The format of individual NodeMap entries is as follows:

|Field Name|Valid Values|Description|
|----------|------------|-----------|
|**ID\*** \(key\)|Node xname: xXcCsSbBnN|Node xname ID|
|**NID\*** \(required\)|Positive integers greater than or equal to 1|Default Node ID \(NID\) for the given system location|
|**Role** \(optional\)|"Compute", "Service", "System", "Application", "Storage", "Management"|Optional node Role|

To view the current NodeMaps collection:

```screen
ncn-m# cray hsm defaults nodeMaps list
[[NodeMaps]]
ID = "x3000c0s11b4n0"
NID = 8

[[NodeMaps]]
ID = "x3000c0s11b3n0"
NID = 7

[[NodeMaps]]
ID = "x3000c0s11b2n0"
NID = 6

[[NodeMaps]]
ID = "x3000c0s11b1n0"
NID = 5

[[NodeMaps]]
ID = "x3000c0s9b4n0"
NID = 4

[[NodeMaps]]
ID = "x3000c0s9b3n0"
NID = 3

[[NodeMaps]]
ID = "x3000c0s9b2n0"
NID = 2

[[NodeMaps]]
ID = "x3000c0s9b1n0"
Role = "Compute"
NID = 1
```

Every node that will potentially be discovered by REDS should be given an entry with a default NID in the NodeMaps file. The NodeMap entries are a mapping of one xname ID to a NID. The NID field is required. NodeMaps can also be used to set a default Role, but this is optional and if the field is omitted the standard default is required.

The mapping for a specific xname can also be viewed if an entry has been created for it:

```screen
ncn-m# cray hsm defaults nodeMaps describe XNAME
ID = "x3000c0s9b1n0"
NID = 1
```

### Create a NodeMap

The node mapping can be uploaded as a single file containing all entries for the system. Performing this step manually is not the preferred way of uploading the mapping information. The mapping must be in place when nodes are powered on for REDS auto-discovery or they will not be used.

To manually create multiple node maps:

```screen
ncn-m# cray hsm defaults nodeMaps create --node-maps--id XNAME1,XNAME2,... \
--node-maps--nid NID1,NID2,... \
--node-maps–role ROLE1,ROLE2,...
```

### Update a NodeMap

To update an existing node map:

```screen
ncn-m# cray hsm defaults nodeMaps update --nid NID --role ROLE XNAME
```

### Delete a NodeMap

To delete a single entry from the node maps collection:

```screen
ncn-m# cray hsm defaults nodeMaps delete XNAME
```



