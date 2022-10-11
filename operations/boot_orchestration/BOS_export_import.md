# BOS - Exporting and Importing for System Recovery or in the case of a fresh install

## BOS Session Templates

The primary BOS data that should be saved is the BOS session template. BOS session templates can be exported and later imported.

### Automatically export/import BOS session templates

Product specified session templates can be re-installed using their associated Helm charts. This recreates the session template data within BOS.
Existing BOS session templates can be backed up and restored using the automated scripts. See scripts/operations/system_recovery/export_bos_sessiontemplates.sh and scripts/operations/system_recovery/import_bos_sessiontemplates.sh
To export BOS session templates, simply run the script scripts/operations/system_recovery/export_bos_sessiontemplates.sh. Copy the archive file it outputs to a safe location.
To import the BOS session templates, run the scripts/operations/system_recovery/import_bos_sessiontemplates.sh providing as input the archive file that was created by the export_bos_sessiontemplates.sh script.

BOS session templates can also be manually exported and imported onto a given system using the Cray CLI tool. For each session template that you wish to export, use `cray bos sessiontemplate describe` cli. For example:

### Manually export any session template as needed

```bash
cray bos sessiontemplate describe uan-sessiontemplate-2.0.27 --format json > ~/uan-sessiontemplate-2.0.27.json
cat ~/uan-sessiontemplate-2.0.27.json
{
  "boot_sets": {
    "uan": {
      "boot_ordinal": 2,
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "network": "nmn",
      "node_list": [
        "x3000c0s15b0n0"
      ],
      "path": "s3://boot-images/c23f3d5e-223a-4fb9-b305-0c2be8e63615/manifest.json",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "type": "s3"
    }
  },
  "boot_sets": {
    "uan": {
      "boot_ordinal": 2,
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "network": "nmn",
      "node_list": [
        "x3000c0s15b0n0"
      ],
      "path": "s3://boot-images/c23f3d5e-223a-4fb9-b305-0c2be8e63615/manifest.json",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "type": "s3"
    }
  },
  "cfs": {
    "configuration": "uan-config-2.0.0"
  },
  "enable_cfs": true,
  "name": "uan-sessiontemplate-2.0.27"
}
```

### Import/restore any session template as needed

```bash
cray bos sessiontemplate create --file ~/uan-sessiontemplate-2.0.27.json --name uan-sessiontemplate-2.0.27
```

## BOS Database PVCs

Since the release BOS V2, it is not recommended that the BOS redis database be saved and restored. This database contains the desired state of components. If a system is in recovery and all of the compute nodes shut down, restoring the database will restore BOS' desired state for the components. BOS will attempt to move these compute nodes into that desired state. This may mean attempting to boot compute nodes to the previous desired state, which may contain old, stale state, such as stale compute images. It is better to let BOS recreate the databases from scratch. Then, apply the desired state to the components with the latest up to date state.
