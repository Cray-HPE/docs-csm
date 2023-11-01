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
    1. Configuring the UAN node to use the [Content Projection Service \(CPS\)](../../glossary.md#content-projection-service-cps) and
       [Data Virtualization Service \(DVS\)](../../glossary.md#data-virtualization-service-dvs).
       These services manage the UAN image `rootfs` mounting and make that image available to the UANs.
    1. Mounting the `rootfs`.
1. Booting the UAN image `rootfs`.

## PXE issues

Most failures to PXE are the result of misconfigured network switches and/or BIOS settings. The UAN must PXE boot over the
[Node Management Network \(NMN\)](../../glossary.md#node-management-network-nmn) and the switches must be configured to allow connectivity to the NMN. The cable for the NMN must be
connected to the first port of the OCP card,on HPE DL325 and DL385 nodes, or to the first port of the built-in LAN-On-Motherboard (LOM), on Gigabyte nodes.

## `initrd` (dracut) issues

Failures in dracut are often caused by the wrong interface being named `nmn0`, or by having multiple entries for the UAN component name (xname) in DNS. The latter is a result of
multiple interfaces making DHCP requests. Either condition can cause IP address mismatches in the `dvs_node_map`. DNS configures entries based on DHCP leases.

When dracut starts, it renames the network device named by the `ifmap=netX:nmn0` kernel parameter to `nmn0`. This interface is the only one dracut will enable DHCP on.
The `ip=nmn0:dhcp` kernel parameter limits dracut to DHCP only `nmn0`. The `ifmap` value must be set correctly in the `kernel_parameters` field of the BOS session template.

For UAN nodes that have more than one PCI card installed, `ifmap=net2:nmn0` is the correct setting. If only one PCI card is installed, `ifmap=net0:nmn0` is normally the correct setting.

UANs require CPS and DVS to boot from images. These services are configured in dracut to retrieve the `rootfs` and mount it. If the image fails to download,
check that DVS and CPS are both healthy, and that DVS is running on all worker nodes.

(`ncn-mw#`) Run the following commands to check DVS and CPS:

```bash
kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers
```

Example output:

```text
ncn-w001
ncn-w002
```

```bash
for node in `kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers`; do
    ssh $node "lsmod | grep '^dvs '"
done
```

Example output:

```text
ncn-w001
ncn-w002
```

If DVS and CPS are both healthy, then both of these commands will return all the worker
[Non-Compute Nodes (NCNs)](../../glossary.md#non-compute-node-ncn) in the HPE Cray EX system.

## Image boot issues

Once dracut exits, the UAN will boot the `rootfs` image. Failures seen in this phase tend to be failures of `spire-agent`, `cfs-state-reporter`, or both, to start.
The `cfs-state-reporter` tells CFS that the node is ready and allows CFS to start node personalization. If `cfs-state-reporter` does not start, check if the `spire-agent` has started.
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
