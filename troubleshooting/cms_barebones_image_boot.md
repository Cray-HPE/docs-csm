# Troubleshoot the CMS Barebones Image Boot Test

Verify that the CSM services needed to boot a node are available and working properly. This section
describes how the barebonesImageTest script works and how to interpret the results. If the script is
unavailable, the manual steps for reproducing the barebones image boot test are provided.

## Topics

- [Troubleshoot the CMS Barebones Image Boot Test](#troubleshoot-the-cms-barebones-image-boot-test)
  - [Topics](#topics)
  - [1. Steps the Script Performs](#1-steps-the-script-performs)
  - [2. Controlling Which Node Is Used](#2-controlling-which-node-is-used)
  - [3. Controlling Test Script Output Level](#3-controlling-test-script-output-level)
  - [4. Manual Steps To Reproduce This Script](#4-manual-steps-to-reproduce-this-script)
    - [4.1 Locate CSM Barebones Image in IMS](#41-locate-csm-barebones-image-in-ims)
    - [4.2 Create a BOS Session Template for the CSM Barebones Image](#42-create-a-bos-session-template-for-the-csm-barebones-image)
    - [4.3 Find an Available Compute Node](#43-find-an-available-compute-node)
    - [4.4 Reboot the Node Using a BOS Session Template](#44-reboot-the-node-using-a-bos-session-template)
    - [4.5 Connect to the Node's Console and Watch the Boot](#45-connect-to-the-nodes-console-and-watch-the-boot)

<a name="csm-boot-script-steps"></a>
## 1. Steps the Script Performs

The script file is: `/opt/cray/tests/integration/csm/barebonesImageTest`

This script automates the following steps.

1. Obtain the Kubernetes API gateway access token
2. Find the existing barebones boot image using IMS
3. Create a BOS session template for the barebones boot image
4. Find an enabled compute node using HSM
5. Watch the console log for the target compute node using console services
6. Create a BOS session to reboot the target compute node
7. Wait for the console output to show an error or successfully reach dracut

If the script fails, investigate the underlying service to ensure it is operating correctly
and examine the detailed log file to find information on the exact error and cause of failure.

The boot may take up to 10 or 15 minutes. The image being booted does not support a complete boot,
so the node will not boot fully into an operating system. This test is merely to verify that the
CSM services needed to boot a node are available and working properly. This boot test is considered
successful if the boot reaches the dracut stage.

<a name="csm-boot-compute-node"></a>
## 2. Controlling Which Node Is Used

By default, the script will gather all enabled compute nodes that are present in HSM and
choose one at random to perform the boot test. This may be overridden with a command line
option to choose which compute node is rebooted using the `--xname` option. The input
compute node must be enabled and present in HSM to be used. If the input compute node is
not available, a warning will be issued and the test will continue with a valid compute node
instead of the user selected node.

```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest --xname x3000c0s10b1n0
```

<a name="csm-boot-output-level"></a>
## 3. Controlling Test Script Output Level

Output is directed to both the console calling the script as well as a log file that will hold
more detailed information on the run and any potential problems found. The log file is written
to `/tmp/cray.barebones-boot-test.log` and will overwrite any existing file at that location on
each new run of the script.

The messages output to the console and the log file may be controlled separately through
environment variables. To control the information being sent to the console, set the variable
`CONSOLE_LOG_LEVEL`. To control the information being sent to the log file, set the variable
`FILE_LOG_LEVEL`. Valid values in increasing levels of detail are: `CRITICAL`, `ERROR`,
`WARNING`, `INFO`, `DEBUG`. The default for the console output is `INFO` and the default for
the log file is `DEBUG`.

Here is an example of running the script with more information displayed on the console
during the execution of the test:
```bash
ncn# CONSOLE_LOG_LEVEL=DEBUG /opt/cray/tests/integration/csm/barebonesImageTest
cray.barebones-boot-test: INFO     Barebones image boot test starting
cray.barebones-boot-test: INFO       For complete logs look in the file /tmp/cray.barebones-boot-test.log
cray.barebones-boot-test: DEBUG    Found boot image: cray-shasta-csm-sles15sp2-barebones.x86_64-shasta-1.5
cray.barebones-boot-test: DEBUG    Creating bos session template with etag:bc390772fbe67107cd58b3c7c08ed92d, path:s3://boot-images/e360fae1-7926-4dee-85bb-f2b4eb216d9c/manifest.json
```

<a name="csm-boot-manual-steps"></a>
## 4. Manual Steps To Reproduce This Script

The following manual steps may be performed to reproduce the actions of this script. The result should
be the same as running the script.

- [Troubleshoot the CMS Barebones Image Boot Test](#troubleshoot-the-cms-barebones-image-boot-test)
  - [Topics](#topics)
  - [1. Steps the Script Performs](#1-steps-the-script-performs)
  - [2. Controlling Which Node Is Used](#2-controlling-which-node-is-used)
  - [3. Controlling Test Script Output Level](#3-controlling-test-script-output-level)
  - [4. Manual Steps To Reproduce This Script](#4-manual-steps-to-reproduce-this-script)
    - [4.1 Locate CSM Barebones Image in IMS](#41-locate-csm-barebones-image-in-ims)
    - [4.2 Create a BOS Session Template for the CSM Barebones Image](#42-create-a-bos-session-template-for-the-csm-barebones-image)
    - [4.3 Find an Available Compute Node](#43-find-an-available-compute-node)
    - [4.4 Reboot the Node Using a BOS Session Template](#44-reboot-the-node-using-a-bos-session-template)
    - [4.5 Connect to the Node's Console and Watch the Boot](#45-connect-to-the-nodes-console-and-watch-the-boot)

<a name="csm-boot-steps-locate-barebones-image-in-ims"></a>
### 4.1 Locate CSM Barebones Image in IMS

Locate the CSM Barebones image and note the `etag` and `path` fields in the output.

```bash
ncn# cray ims images list --format json | jq '.[] | select(.name | contains("barebones"))'
```

Expected output is similar to the following:
```json
{
  "created": "2021-01-14T03:15:55.146962+00:00",
  "id": "293b1e9c-2bc4-4225-b235-147d1d611eef",
  "link": {
    "etag": "6d04c3a4546888ee740d7149eaecea68",
    "path": "s3://boot-images/293b1e9c-2bc4-4225-b235-147d1d611eef/manifest.json",
    "type": "s3"
  },
  "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4"
}
```

<a name="csm-boot-steps-bos-session-template"></a>
### 4.2 Create a BOS Session Template for the CSM Barebones Image

The session template below can be copied and used as the basis for the BOS session template. As noted below, make sure the S3 path for the manifest matches the S3 path shown in the Image Management Service (IMS).

1. Create the `sessiontemplate.json` file.
   
   ```bash
   ncn# vi sessiontemplate.json
   ```

   The session template should contain the following:
   
   ```json
   {
     "boot_sets": {
       "compute": {
         "boot_ordinal": 2,
         "etag": "etag_value_from_cray_ims_command",
         "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
         "network": "nmn",
         "node_roles_groups": [
           "Compute"
         ],
         "path": "path_value_from_cray_ims_command",
         "rootfs_provider": "cpss3",
         "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
         "type": "s3"
       }
     },
     "cfs": {
       "configuration": "cos-integ-config-1.4.0"
     },
     "enable_cfs": false,
     "name": "shasta-1.4-csm-bare-bones-image"
   }
   ```

   **NOTE**: Be sure to replace the values of the `etag` and `path` fields with the ones noted earlier in the `cray ims images list` command.


2. Create the BOS session template using the following file as input:
   
   ```bash
   ncn# cray bos sessiontemplate create --file sessiontemplate.json --name shasta-1.4-csm-bare-bones-image
   ```
   
   The expected output is:
   
   ```
   /sessionTemplate/shasta-1.4-csm-bare-bones-image
   ```

<a name="csm-boot-steps-node"></a>
### 4.3 Find an Available Compute Node
To list hte compute nodes managed by HSM:

```bash
ncn# cray hsm state components list --role Compute --enabled true
```

Example output:

```
[[Components]]
ID = "x3000c0s17b1n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Compute"
NID = 1
NetType = "Sling"
Arch = "X86"
Class = "River"

[[Components]]
ID = "x3000c0s17b2n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Compute"
NID = 2
NetType = "Sling"
Arch = "X86"
Class = "River"
```

> Troubleshooting: If any compute nodes are missing from HSM database, refer to [2.3.2 Known Issues](#hms-smd-discovery-validation-known-issues) to troubleshoot any Node BMCs that have not been discovered.

Choose a node from those listed and set `XNAME` to its component name (xname). In this example, `x3000c0s17b2n0`:

```bash
ncn# export XNAME=x3000c0s17b2n0
```

<a name="csm-boot-steps-reboot"></a>
### 4.4 Reboot the Node Using a BOS Session Template

Create a BOS session to reboot the chosen node using the BOS session template that was created:

```bash
ncn# cray bos session create --template-uuid shasta-1.4-csm-bare-bones-image --operation reboot --limit $XNAME
```

Expected output looks similar to the following:

```
limit = "x3000c0s17b2n0"
operation = "reboot"
templateUuid = "shasta-1.4-csm-bare-bones-image"
[[links]]
href = "/v1/session/8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1"
jobId = "boa-8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1"
rel = "session"
type = "GET"

[[links]]
href = "/v1/session/8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1/status"
rel = "status"
type = "GET"
```

<a name="csm-boot-steps-watch-boot"></a>
### 4.5 Connect to the Node's Console and Watch the Boot

The boot may take up to 10 or 15 minutes. The image being booted does not support a complete boot,
so the node will not boot fully into an operating system. This test is merely to verify that the
CSM services needed to boot a node are available and working properly.

1. Connect to the node's console.
   See [Manage Node Consoles](../operations/conman/Manage_Node_Consoles.md)
   for information on how to connect to the node's console (and for instructions on how to close it later).

2. Monitor the boot.
   This boot test is considered successful if the boot reaches the dracut stage. You know this has
   happened if the console output has something similar to the following somewhere within the final
   20 lines of its output:
   ```
   [    7.876909] dracut: FATAL: Don't know how to handle 'root=craycps-s3:s3://boot-images/e3ba09d7-e3c2-4b80-9d86-0ee2c48c2214/rootfs:c77c0097bb6d488a5d1e4a2503969ac0-27:dvs:api-gw-service-nmn.local:300:nmn0'
   [    7.898169] dracut: Refusing to continue
   ```

   **NOTE**: As long as the preceding text is found near the end of the console output, the test is
   considered successful. It is normal (and **not** indicative of a test failure) to see something
   similar to the following at the very end of the console output:
   ```
            Starting Dracut Emergency Shell...
   [   11.591948] device-mapper: uevent: version 1.0.3
   [   11.596657] device-mapper: ioctl: 4.40.0-ioctl (2019-01-18) initialised: dm-devel@redhat.com
   Warning: dracut: FATAL: Don't know how to handle
   Press Enter for maintenance
   (or press Control-D to continue):
   ```

3. Exit the console.
   ```
   cray-console-node# &.
   ```

The test is complete.
