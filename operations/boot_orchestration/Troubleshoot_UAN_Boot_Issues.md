# Troubleshoot UAN Boot Issues

Use this topic to guide troubleshooting of [User Access Node (UAN)](../../glossary.md#user-access-node-uan) boot issues.

- [UAN boot process](#uan-boot process)
- [PXE issues](#pxe-issues)
- [`initrd` (dracut) issues](#initrd-dracut-issues)
- [Image boot issues](#image-boot-issues)

## UAN boot process

The [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) boots UANs. BOS uses session templates to define various parameters such as:

- Which nodes to boot
- Which image to boot
- Kernel parameters
- Whether to perform post-boot configuration of the nodes by the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs);
  this is also referred to as Node Personalization.
- Which CFS configuration to use if Node Personalization is enabled.

UAN boots are performed in three phases:

1. PXE booting an iPXE binary that will load the `initrd` of the chosen UAN image to boot.
1. Booting the `initrd` \(dracut\) image which configures the UAN for booting the UAN image. This process consists of two phases:
1. Booting the UAN image `rootfs`, which is projected using the [Scalable Boot Projection Service (SBPS)](../../glossary.md#scalable-boot-projection-service-sbps).

## PXE issues

Most failures to PXE are the result of misconfigured network switches and/or BIOS settings. The UAN must PXE boot over the
[Node Management Network \(NMN\)](../../glossary.md#node-management-network-nmn) and the switches must be configured to allow connectivity to the NMN. The cable for the NMN must be
connected to the first port of the OCP card,on HPE DL325 and DL385 nodes, or to the first port of the built-in LAN-On-Motherboard (LOM), on Gigabyte nodes.

## `initrd` (dracut) issues

Failures in dracut are often caused by the wrong interface being named `nmn0`, or by having multiple entries for the UAN component name (xname) in DNS. The latter is a result of
multiple interfaces making DHCP requests.

When dracut starts, it renames the network device named by the `ifmap=netX:nmn0` kernel parameter to `nmn0`. This interface is the only one dracut will enable DHCP on.
The `ip=nmn0:dhcp` kernel parameter limits dracut to DHCP only `nmn0`. The `ifmap` value must be set correctly in the `kernel_parameters` field of the BOS session template.

For UAN nodes that have more than one PCI card installed, `ifmap=net2:nmn0` is the correct setting. If only one PCI card is installed, `ifmap=net0:nmn0` is normally the correct setting.

## Image boot issues

Once dracut exits, the UAN will boot the `rootfs` image. Failures seen in this phase tend to be failures of `spire-agent`, `cfs-state-reporter`, or both, to start.
The [CFS State Reporter](../configuration_management/CFS_State_Reporter.md) tells CFS that the node is ready and allows CFS to start node personalization.
If `cfs-state-reporter` does not start, then check if the `spire-agent` has started.
The `cfs-state-reporter` depends on the `spire-agent`. Running `systemctl status spire-agent` will show that that service is enabled and running if there are no issues with that service.
Similarly, running `systemctl status cfs-state-reporter` will show a status of `SUCCESS`.

1. (`uan#`) Verify that the `spire-agent` service is enabled and running.

   ```bash
   systemctl status spire-agent
   ```

   Example output:

   ```text
   ● spire-agent.service - SPIRE Agent
      Loaded: loaded (/usr/lib/systemd/system/spire-agent.service; enabled; vendor preset: enabled)
      Active: active (running) since Wed 2021-02-24 14:27:33 CST; 19h ago
   Main PID: 3581 (spire-agent)
      Tasks: 57
      CGroup: /system.slice/spire-agent.service
            └─3581 /usr/bin/spire-agent run -expandEnv -config /var/lib/spire/conf/spire-agent.conf
   ```

1. (`uan#`) Verify that `cfs-state-reporter` is healthy and returns `SUCCESS`.

   ```bash
   systemctl status cfs-state-reporter
   ```

   Example output:

   ```text
   ● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
      Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: enabled)
      Active: inactive (dead) since Wed 2021-02-24 14:29:51 CST; 19h ago
   Main PID: 3827 (code=exited, status=0/SUCCESS)
   ```
