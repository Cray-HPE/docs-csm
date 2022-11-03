# Manage a Session Template

A session template must be created before starting a session with the Boot Orchestration Service \(BOS\). Session templates are managed via the Cray CLI with the cray bos sessiontemplate commands.


### Get the Framework for a Session Template

When creating a new BOS session template, it can be helpful to start with a framework and then edit it as needed. Use the following command to retrieve the BOS session template framework:

```bash
ncn-m001# cray bos sessiontemplatetemplate list --format json
{
  "boot_sets": {
    "name_your_boot_set": {
      "boot_ordinal": 1,
      "etag": "your_boot_image_etag",
      "kernel_parameters": "your-kernel-parameters",
      "network": "nmn",
      "node_list": [
        "xname1",
        "xname2",
        "xname3"
      ],
      "path": "your-boot-path",
      "rootfs_provider": "your-rootfs-provider",
      "rootfs_provider_passthrough": "your-rootfs-provider-passthrough",
      "type": "your-boot-type"
    }
  },
  "cfs": {
    "configuration": "desired-cfs-config"
  },
  "enable_cfs": true,
  "name": "name-your-template"
}
```

### Create a Session Template with the Cray CLI

The following command takes a JSON input file that contains the information required to create a new BOS session template. It reads it in and creates an actual BOS session template using the BOS API.

```bash
ncn-m001# cray bos sessiontemplate create --file INPUT_FILE --name NEW_TEMPLATE_NAME
```

The following is an example of an input file:

```bash
 {
  "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
  "enable_cfs": true,
  "name": "cle-1.2.0",
  "boot_sets": {
    "boot_set1": {
      "network": "nmn",
      "boot_ordinal": 1,
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gwservice-nmn.local quiet turbo_boost_limit=999",
      "rootfs_provider": "cpss3",
      "node_list": [
        "x3000c0s19b1n0"
      ],
      "etag": "90b2466ae8081c9a604fd6121f4c08b7",
      "path": "s3://boot-images/06901f40-f2a6-4a64-bc26-772a5cc9d321/manifest.json",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3"
      }
    },
  "partition": "",
  "cfs_branch": "master"
  }
```

### Create a Session Template with a Bash Script

A BOS session template can also be generated with a shell script, which directly uses the BOS API. The following is an example script for creating a session template. The `get_token` function retrieves a token that validates the request to the API gateway. The values in the body section of the script can be customized when creating a new session template.

```bash
#!/bin/bash
# Up to date as of 2020-02-05

ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
TOKEN=$(curl -s -d grant_type=client_credentials \
    -d client_id=admin-client \
    -d client_secret=$ADMIN_SECRET \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
    python -c 'import sys, json; print json.load(sys.stdin)["access_token"]')

kernel_parameters="console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g \
intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless \
numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y \
rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999"

body='{
    "name": "cle-1.2.0",
    "boot_sets": {
        "boot_set1": {
            "boot_ordinal": 1,
            "path": "s3://boot-images/06901f40-f2a6-4a64-bc26-772a5cc9d321/manifest.json",
            "type": "s3",
            "etag": "90b2466ae8081c9a604fd6121f4c08b7",
            "node_list": ["x3000c0s19b1n0"],
            "rootfs_provider": "cpss3",
            "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0",
            "kernel_parameters": "'"$kernel_parameters"'",
            "network": "nmn" }},
    "cfs_branch": "master",
    "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
    "enable_cfs": true,
    "partition": "" }'

curl -i -X POST -s https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$body"
```

Either script above will generate the following session template:

```bash
ncn-m001# cray bos sessiontemplate describe session_template1 --format json
{
  "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
  "enable_cfs": true,
  "name": "cle-1.2.0",
  "boot_sets": {
    "boot_set1": {
      "network": "nmn",
      "boot_ordinal": 1,
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchr
      "rootfs_provider": "cpss3",
      "node_list": [
        "x3000c0s19b1n0"
      ],
      "etag": "90b2466ae8081c9a604fd6121f4c08b7",
      "path": "s3://boot-images/06901f40-f2a6-4a64-bc26-772a5cc9d321/manifest.json",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3"
    }
  },
  "partition": "",
  "cfs_branch": "master"
}
```


### List All Session Templates

Use the following command to view all of the available session templates:

```bash
ncn-m001# cray bos sessiontemplate list --format json
[
  {
    "enable_cfs": true,
    "description": "Template for booting compute nodes, generated by the installation",
    "boot_sets": {
      "computes": {
        "network": "nmn",
        "rootfs_provider": "cpss3",
        "boot_ordinal": 1,
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
        "node_roles_groups": [
          "Compute"
        ],
        "etag": "b0ace28163302e18b68cf04dd64f2e01",
        "path": "s3://boot-images/ef97d3c4-6f10-4d58-b4aa-7b70fcaf41ba/manifest.json",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0",
        "type": "s3"
      }
    },
    "name": "cle-1.2.0",
    "cfs_branch": "master",
    "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
  }
]

...
```


### Show Details for a Session Template

View the details for a specific session template. In the following example, the session template name is cle-1.2.0.

```bash
ncn-m001# cray bos sessiontemplate describe SESSION_TEMPLATE_NAME --format json
{
  "cfs_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
  "enable_cfs": true,
  "description": "Template for booting compute nodes, generated by the installation",
  "boot_sets": {
    "computes": {
      "network": "nmn",
      "rootfs_provider": "cpss3",
      "boot_ordinal": 1,
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "node_roles_groups": [
        "Compute"
      ],
      "etag": "b0ace28163302e18b68cf04dd64f2e01",
      "path": "s3://boot-images/ef97d3c4-6f10-4d58-b4aa-7b70fcaf41ba/manifest.json",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3"
    }
  },
  "cfs_branch": "master",
  "name": "cle-1.2.0"
}
```

### Delete a Session Template

Remove an existing session template with the following command:

```bash
ncn-m001# cray bos sessiontemplate delete SESSIONTEMPLATE_NAME
```

