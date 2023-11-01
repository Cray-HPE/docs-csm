# Set the Turbo Boost Limit

Turbo boost limiting is supported on the Intel® and AMD® processors. Because processors have a high degree of variability in the amount of turbo boost each processor can supply,
limiting the amount of turbo boost can reduce performance variability and reduce power consumption.

Turbo boost can be limited by setting the `turbo_boost_limit` kernel parameter to one of these values:

- 0 - Disable turbo boost
- 999 - \(default\) No limit is applied.

The following values are not supported in COS v1.4:

- 100 - Limits turbo boost to 100 MHz
- 200 - Limits turbo boost to 200 MHz
- 300 - Limits turbo boost to 300 MHz
- 400 - Limits turbo boost to 400 MHz

The limit applies only when a high number of cores are active. On an `N`-core processor, the limit is in effect when the active core count is `N`, `N-1`, `N-2`, or `N-3`.
For example, on a 12-core processor, the limit is in effect when 12, 11, 10, or 9 cores are active.

## Set or change the turbo boost limit parameter

Modify the Boot Orchestration Service \(BOS\) template for the nodes. This example below disables turbo boost. The default setting is 999 \(no limit\).

```json
{
  "boot_sets": {
    "boot_set61": {
      "kernel_parameters": "console=tty0 console=ttyS0,115200n8 root=crayfs imagename=/SLES15 selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M turbo_boost_limit=0",
      "node_groups": [
        "group1",
        "group2"
      ],
      "node_list": [
        "x0c0s28b0n0",
        "node2",
        "node3"
      ],
      "node_roles_groups": [
        "compute"
      ],
      "rootfs_provider": "",
      "rootfs_provider_passthrough": ""
    },
  },
  "cfs": {
    "configuration": "my-cfs-configuration"
  },
  "enable_cfs": true,
  "name": "st6"
}
```
