
## User Access Service \(UAS\)

The User Access Service \(UAS\) is a containerized service managed by Kubernetes that enables application developers to create and run user applications. UAS runs on a non-compute node \(NCN\) that is acting as a Kubernetes worker node.

Users launch a User Access Instance \(UAI\) using the cray command. Users can also transfer data between the Cray system and external systems using the UAI.

When a user requests a new UAI, the UAS service returns status and connection information to the newly created UAI. External access to UAS is routed through a node that hosts gateway services.

The timezone inside the UAI container matches the timezone on the host on which it is running, For example, if the timezone on the host is set to CDT, the UAIs on that host will also be set to CDT.

|Component|Function/Description|
|---------|--------------------|
|User Access Instance \(UAI\)|An instance of UAS container.|
|`uas-mgr`|Manages UAI life cycles.|

|Container Element|Components|
|-----------------|----------|
|Operating system|SLES15 SP1|
|kubectl command|Utility to interact with Kubernetes.|
|cray command|Command that allows users to create, describe, and delete UAIs.|

Use `cray uas list` to list the following parameters for a UAI.

**Note:** The example values below are used throughout the UAS procedures. They are used as examples only. Users should substitute with site-specific values.

|Parameter|Description|Example value|
|---------|-----------|-------------|
|`uai_connect_string`|The UAI connection string|`ssh user@203.0.113.0 -i ~/.ssh/id\_rsa`|
|`uai_img`|The UAI image ID|`registry.local/cray/cray-uas-sles15sp1-slurm:latest`|
|`uai_name`|The UAI name|`uai-user-be3a6770`|
|`uai_status`|The state of the UAI.|`Running: Ready`|
|`username`|The user who created the UAI.|`user`|
|`uai_age`|The age of the UAI.|`11m`|
|`uai_host`|The node hosting the UAI.|`ncn-w001`|

### Getting started

UAS is highly configurable and it is recommended that administrators familiarize themselves with the service by reading this topic before allowing users to use UAIs.

Once administrators are familiar with the configurable options of UAS, they may want to create a UAI image that matches the booted compute nodes by following the procedure [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).
