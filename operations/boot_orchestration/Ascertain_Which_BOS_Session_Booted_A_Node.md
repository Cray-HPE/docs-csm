# Ascertain Which BOS Session Booted a Node

This guide is split into BOS Version 1 (V1) and BOS Version 2 (V2) sections
because the procedures are different for the two different versions.

## BOS Version 1 (V1)

To determine which BOS Session booted or rebooted a node, query the node's
kernel boot parameters. They contain a string 'bos_session_id' which identifies
which BOS session booted or rebooted the node. Then, use this BOS Session ID
to describe the BOS Session, which identifies the BOS Session template used.

### Query the Node

From a management node (master or worker), ssh to the node in question.
(`ncn-mw#`) ssh <node's xname>
('<node>#') cat /proc/cmdline

Find the bos_session_id value in the cmdline string. This is the ID of the BOS
session that was used to boot the node.

Exit from the node.
('<node>#') exit

### Query BOS
Ask BOS to describe this session.
(`ncn-mw#`#) cray bos v1 session describe  <BOS session ID> --format json

The templateName parameter is the BOS session template used to boot or reboot the node.

### Example

From a management node (master or worker), ssh to the node in question.
ncn-m001#: ssh x3000c0s28b4n0
x3000c0s28b4n0#: cat /proc/cmdline

```bash
kernel initrd=initrd console=ttyS0,115200 bad_page=panic crashkernel=512M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu.passthrough=on modprobe.blacklist=amdgpu numa_interleave_omit=headless oops=panic pageblock_order=14 rd.neednet=1 rd.retry=10 rd.shell systemd.unified_cgroup_hierarchy=1 console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 quiet spire_join_token=<redacted>2 root=craycps-s3:s3://boot-images/51a448dc-3ed1-4b02-b9cc-a0cc7be63763/rootfs:c414a8cbe0fd427102a18fc5ed0f7cb5-318:dvs:api-gw-service-nmn.local:300:hsn0,nmn0:0 nmd_data=url=s3://boot-images/51a448dc-3ed1-4b02-b9cc-a0cc7be63763/rootfs,etag=c414a8cbe0fd427102a18fc5ed0f7cb5-318 bos_session_id=147b09de-59a8-4444-9bcb-9b54ac7d78cc xname=x3000c0s28b4n0 nid=12 bss_referral_token=<redacted> ds=nocloud-net;s=http://10.92.100.81:8888/
```
The string of interest is bos_session_id=147b09de-59a8-4444-9bcb-9b54ac7d78cc.

x3000c0s28b4n0# exit

ncn-m001#: cray bos v1 session describe  147b09de-59a8-4444-9bcb-9b54ac7d78cc --format json
{
  "complete": false,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-147b09de-59a8-4444-9bcb-9b54ac7d78cc",
  "operation": "reboot",
  "start_time": "2023-06-23T20:57:34.352623Z",
  "status_link": "/v1/session/147b09de-59a8-4444-9bcb-9b54ac7d78cc/status",
  "stop_time": "2023-06-23 21:24:14.647779",
  "templateName": "knn-boot-x3000c0s28b4n0"
}
The session template is "knn-boot-x3000c0s28b4n0".

## BOS Version 2 (V2)

Ask BOS V2 to describe the component. The session that last acted upon the
node is listed in this description.

### Instructions
(`ncn-mw#`) cray bos v2 components describe <node's xname> --format json | jq .session

(`ncn-mw#`) cray bos v2 sessions describe <BOS session ID> --format json

### Example
(`ncn-mw#`) cray bos v2 components describe x3000c0s17b0n0 --format json | jq .session
"94e712ab-df76-40ee-8cfb-7ac487fd8a13"

(`ncn-mw#`) cray bos v2 sessions describe 94e712ab-df76-40ee-8cfb-7ac487fd8a13 --format json
{
  "components": "x3000c0s17b0n0",
  "limit": "x3000c0s17b0n0",
  "name": "94e712ab-df76-40ee-8cfb-7ac487fd8a13",
  "operation": "reboot",
  "stage": false,
  "status": {
    "end_time": "2023-06-27T00:55:58",
    "error": null,
    "start_time": "2023-06-27T00:33:17",
    "status": "complete"
  },
  "template_name": "gdr-tmpl"
}
The session template is "gdr-tmpl".