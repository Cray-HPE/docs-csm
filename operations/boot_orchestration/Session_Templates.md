## BOS Session Templates

Describes the contents of a BOS session template.

A session template can be created by specifying parameters as part of the call to the Boot Orchestration Service \(BOS\). When calling BOS directly, JSON is passed as part of the call.

Session templates can be used to boot images that are customized with the Image Management Service \(IMS\). A session template has a collection of one or more boot set objects. A boot set defines a collection of nodes and the information about the boot artifacts and kernel parameters used to boot them. This information is written to the Boot Script Service \(BSS\) and sent to each node over the specified network, enabling these nodes to boot.

The Simple Storage Service \(S3\) is used to store the manifest.json file that is created by IMS. This file contains links to all of the boot artifacts. The following S3 parameters are used in a BOS session template:

- type: This is the type of storage used. Currently, the only allowable value is `s3`.
- path: This is the path to the manifest.json file in S3. The path will follow the s3://<BUCKET\_NAME\>/<KEY\_NAME\> format.
- etag: This entity tag helps identify the version of the manifest.json file. Currently not used but cannot be left blank.

The following is an example BOS session template:

```bash
{
 "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git", <<-- Configuration manifest API endpoint
 "enable_cfs": true, <<-- Invokes CFS
 "name": "session-template-example",
 "boot_sets": {
   "boot_set1": {
     "network": "nmn",
     "boot_ordinal": 1,
     "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
     "rootfs_provider": "cpss3",
     "node_list": [   <<-- List of individual nodes
       "x3000c0s19b1n0"
     ],
     "etag": "foo", <<-- Used to identify the version of the manifest.json file
     "path": "s3://boot-images/e06530f1-fde2-4ca5-9148-7e84f4857d17/manifest_sans_boot_parameters.json", <<-- The path to the manifest.json file in S3
     "rootfs_provider_passthrough": "66666666:dvs:api-gw-service-nmn.local:300:eth0",
     "type": "s3" <<-- Type of storage
   },
   "boot_set2": {
     ...
   }
 },
```

When multiple boot sets are used in a session template, the boot\_ordinal and shutdown\_ordinal values indicate the order in which boot sets need to be acted upon. Boot sets sharing the same ordinal number will be addressed at the same time.

Each boot set needs its own set of S3 parameters \(path, type, and optionally etag\).

### Specify Nodes in a BOS Session Template

There are three different ways to specify the nodes inside a boot set in a BOS session template. The node list, node groups, or node role groups values can be used. Each can be specified as a comma separated list.

-   **Node list**

    The `"node_list"` value is a list of nodes identified by xnames.

    For example:

    ```bash
    "node_list": ["x3000c0s19b1n0", "x3000c0s19b1n1", "x3000c0s19b2n0"]
    ```


-   **Node groups**

    The `"node_groups"` value is a list of groups defined by the Hardware State Manager \(HSM\). Each group may contain zero or more nodes. Groups can be arbitrarily defined.

    For example:

    ```bash
    "node_groups": ["green", "white", "pink"]
    ```

-   **Node roles groups**

    The node role groups is a list of groups based on a node's designated role. Each node's role is specified in the HSM database. For example, to target all of the nodes with a "Compute" role, "Compute" would need to be specified in the `"node_role_groups"` value.

    For example:

    ```bash
    "node_roles_groups": ["Compute"]
    ```

    The following roles are defined in the HSM database:

    -   Compute
    -   Service
    -   System
    -   Application
    -   Storage
    -   Management


