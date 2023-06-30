# Kernel

This page provides information on the Linux kernel in the NCN.

* [Locks](#locks)
* [Module Blacklisting](#module-blacklisting)
* [Parameters](#parameters)
  * [`biosdevname`](#biosdevname)
  * [`ifname`](#ifname)
  * [`ip`](#ip)
  * [`psi`](#psi)
  * [`pcie_ports`](#pcie_ports)
  * [`transparent_hugepage`](#transparent_hugepage)
  * [`console`](#console)
  * [`iommu`](#iommu)
  * [`metal.server`](#metalserver)
  * [`metal.no-wipe`](#metalno-wipe)
  * [`ds`](#ds)
  * [`rootfallback`](#rootfallback)
  * [`initrd`](#initrd)
  * [`root`](#root)
  * [`rd.live.ram`](#rdliveram)
  * [`rd.writable.fsimg`](#rdwritablefsimg)
  * [`rd.skipfsck`](#rdskipfsck)
  * [`rd.live.squashimg`](#rdlivesquashimg)
  * [`rd.live.overlay`](#rdliveoverlay)
  * [`rd.live.overlay.thin`](#rdliveoverlaythin)
  * [`rd.live.overlay.overlayfs`](#rdliveoverlayoverlayfs)
  * [`rd.luks`](#rdluks)
  * [`rd.luks.crypttab`](#rdlukscrypttab)
  * [`rd.lvm.conf`](#rdlvmconf)
  * [`rd.lvm`](#rdlvm)
  * [`rd.auto`](#rdauto)
  * [`rd.md`](#rdmd)
  * [`rd.dm`](#rddm)
  * [`rd.neednet`](#rdneednet)
  * [`rd.peerdns`](#rdpeerdns)
  * [`rd.md.waitclean`](#rdmdwaitclean)
  * [`rd.multipath`](#rdmultipath)
  * [`rd.md.conf`](#rdmdconf)
  * [`rd.bootif`](#rdbootif)
  * [`hostname`](#hostname)
  * [`rd.net.timeout.carrier`](#rdnettimeoutcarrier)
  * [`rd.net.timeout.ifup`](#rdnettimeoutifup)
  * [`rd.net.timeout.iflink`](#rdnettimeoutiflink)
  * [`rd.net.dhcp.retry`](#rdnetdhcpretry)
  * [`rd.net.timeout.ipv6auto`](#rdnettimeoutipv6auto)
  * [`rd.net.timeout.ipv6dad`](#rdnettimeoutipv6dad)
  * [`append`](#append)
  * [`nosplash`](#nosplash)
  * [`quiet`](#quiet)
  * [`crashkernel`](#crashkernel)
  * [`log_buf_len`](#log_buf_len)
  * [`split_lock_detect`](#split_lock_detect)
  * [`rd.retry`](#rdretry)
  * [`rd.shell`](#rdshell)
  * [`xname`](#xname)
* [Versioning](#versioning)

## Locks

The Kernel version is controlled by the `kernel-default` package, and this package is locked.
Locking
this package prevents accidental updates.

To view the locks, run `zypper locks`.

To remove the lock, run `zypper removelock kernel-default`.

To add set the lock, run `zypper addlock kernel-default`.

## Module Blacklisting

Certain kernel modules are blacklisted from loading on the non-compute node.

* `rpcrdma` due to conflicts with slingshot.

## Parameters

Below are a list of kernel parameters used on an NCN, each will denote its default values. If more
than one default value is listed, that means the parameter itself is listed on the command line
multiple times.

e.g. `console` is listed on the command line twice, once to enable `tty0` and again

to enable serial devices with `ttyS0,115200`.

Parameters are viewable in four places:

* `/proc/cmdline` on any booted Linux server will denote the currently *active* parameters.
* `/metal/recovery/boot/grub2/grub.cfg` will contain boot parameters for disk boots.
* `/var/www/ncn-*/script.ipxe` contains boot parameters for PXE boots from the PIT.
* Cray-BSS contains boot parameters for PXE boots from CSM runtime.

For custom kernel parameters for resizing partitions or controlling other behaviors from CSM:
Metal's
dracut, see the following pages:

* [`dracut-metal-mdsquash`](https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#kernel-parameters)
* [`dracut-metal-dmk8s`](https://github.com/Cray-HPE/dracut-metal-dmk8s/blob/main/README.md#customizable-parameters)
* [`dracut-metal-luksetcd`](https://github.com/Cray-HPE/dracut-metal-luksetcd/blob/main/README.md#customizable-parameters)

### `biosdevname`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

This value determines whether interfaces will use standardized names. Any interface that does not
receive a `udev` rule from `ifname` or from an RPM package installed in the OS will use a
standardized name.

See [Consistent Network Device Naming Using `biosdevname`][1] for more information.

### `ifname`

|      NCN Type      | Default Value(s)      |
|:------------------:|:----------------------|
|        All         | `mgmt0:<mac address>` |
|        All         | `mgmt1:<mac address>` |
| Kubernetes Masters | `lan0:<mac address>`  |
| Kubernetes Workers | `hsn0:<mac address>`  |
| Kubernetes Workers | `hsn1:<mac address>`  |
|      Storage       | `sun0:<mac address>`  |
|      Storage       | `sun1:<mac address>`  |

This parameter creates a `udev` rule for a network interface, assigning a bus ID or a MAC address to
a name.

* `mgmt*` interfaces are used for the management network and are members of `bond0`.
* `sun*` interfaces are used for the storage utility network (SUN) and are members of `bond1`
  and will only exist if more than 2 ports are detected in the PCI bus.
* `hsn*` interfaces are used for the high-speed network (HSN) and will only exist on nodes with
  detectable PCIe cards classified for HSN use.
* `lan*` interfaces are used for connections to customer LAN(s) and will only exist if unclassified
  onboard or PCIe NICs are detected. LANs are cleared for use on Kubernetes masters,
  `lan*` interfaces should only be utilized on those nodes.

> ***NOTE*** The MAC address will be filled in by `metal-iPXE` during boots from the PIT, or by Cray
> BSS during boots
> in runtime.

For more information, see [dracut command line's network parameter definition][13] and the
[NCN Networking page](./ncn_networking.md).

### `ip`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |   `mgmt0:dhcp`   |
|   All    |    `*:auto6`     |

This parameter hard codes the DHCP request to go over `mgmt0` during boot. The IP received from the
`DHCPREQUEST` will be used to download the NCN image to a local disk when the NCN boots.

This parameter also sets `auto6` for any other interface, this is a workaround to ensure the
initramFS
acknowledges the given interface. In CSM 0.9 and 1.0 despite having `ifname` set, `udev` rules were
not created for devices unless they had a corresponding `ip` parameter set. The `auto6` value was
the
safest value to set here that did not disrupt the state of the NCN.

> ***NOTE*** When an NCN boots using a disk this parameter is not set (`ip` is removed), disk boots
> will use the already stored image found in the SquashFS storage.

For more information, see [dracut command line's network parameter definition][13].

### `psi`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

This parameter enables pressure stall information from the kernel.

```bash
cat /proc/pressure/{cpu,io,memory}
```

Potential output:

```text
some avg10=0.00 avg60=0.00 avg300=0.00 total=4054991
some avg10=0.00 avg60=0.00 avg300=0.00 total=18417915
full avg10=0.00 avg60=0.00 avg300=0.00 total=18199681
some avg10=0.00 avg60=0.00 avg300=0.00 total=0
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
```

> ***NOTE*** If this is unset, the default is `0`. The files `cpu`, `io`, and `memory` located
> at `/proc/pressure` will be unreadable if this is disabled.

### `pcie_ports`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `native`     |

Ensures that Linux uses native AER and DPC services.

### `transparent_hugepage`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `never`      |

This parameter controls the behavior of memory paging with regard to transparent huge pages.

CSM does not want these to be used at all, and disables them by setting this parameter to `never`.

> ***NOTE*** Historically, Cray has always set this to `never`.

### `console`

| NCN Type | Default Value(s) |
|:--------:|:-----------------|
|   All    | `tty0`           |
|   All    | `ttyS0,115200`   |

### `iommu`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `pt`       |

This parameter sets the Input-Output Memory Management Unit (IOMMU) to pass-through mode (when set
to `pt`).

This ensures maximum performance when `SR-IOV` is enabled, telling the operating system to ignore
IOMMU
for host-only devices (e.g. devices created via SR-IOV).

> ***NOTE*** This is set whether or not `SR-IOV` is enabled in the BIOS.

### `metal.server`

This parameter's value tells the initramFS where to download the kernel, `initrd`, and SquashFS
from.

| NCN Type | Default Value(s)                                            | Context         |
|:--------:|:------------------------------------------------------------|:----------------|
|   All    | `http://pit/<hostname>`                                     | `/proc/cmdline` |
|   All    | `http://rgw-vip.nmn/$K8S_IMS_IMAGE_ID/rootfs?<auth-token>`  | `/proc/cmdline` |
|   All    | `http://rgw-vip.nmn/$CEPH_IMS_IMAGE_ID/rootfs?<auth-token>` | `/proc/cmdline` |
|   All    | `s3://boot-images/$K8S_IMS_IMAGE_ID/rootfs`                 | `cray-bss`      |
|   All    | `s3://boot-images/$CEPH_IMS_IMAGE_ID/rootfs`                | `cray-bss`      |

For more information, see [`dracut-metal-mdsquash`'s usage on `metal.server`][2].

When the node boots, `cray-bss` will replace any URL prefixed with `s3://` with an `http://` URL
that includes
a pre-signed authorization token.

> ***NOTE*** This parameter is not set for disk boots because no images need to be downloaded.
> Instead, the local images will be used.

### `metal.no-wipe`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |
|   All    |       `1`        |

This parameter's value is `0` for initial deployments, when `metal.no-wipe=0` is set (or
when `metal.no-wipe`
is not set at all) the NCN will wipe any existing LVMs, RAIDs, NVME, SAS, and SATA devices.

When this value is set to `1`, the wipe function mentioned in the previous paragraph is disabled.

For more information, see [`dracut-metal-mdsquash`'s definition of `metal.no-wipe`][3]. This
parameter
gives the administrator some time to cancel the boot before the wipe occurs, that time is controlled
by `metal.wipe-delay`. For more information on `metal.wipe-delay`, see [`dracut-metal-mdsquash`'s
definition of `metal.wipe-delay`][4].

> ***NOTE*** USB Devices are always ignored.

### `ds`

| NCN Type | Default Value(s)                                 |
|:--------:|:-------------------------------------------------|
|   All    | `nocloud-net;s=http://10.1.1.2:8888/;h=ncn-m002` |
|   All    | `nocloud-net;s=http://10.92.100.81:8888/`        |

This parameter tells `cloud-init` what to use for the data source. The values listed above will vary
depending on whether the node is booting from the PIT or from runtime, this is because the server
hosting the data source moves in each context.

For more information on the `ds=nocloud` and `ds=nocloud-net`,
see [`cloud-init`'s data sources `NoCloud` page][6].

### `rootfallback`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    | `LABEL=BOOTRAID` |

This parameter tells the initramFS what to use if it is unable to resolve the root filesystem.

> ***NOTE*** This parameter is actually broken, the `BOOTRAID` does not contain a full filesystem
> that
> the initramFS can switch to. In the event this is needed, an emergency shell will appear.

For more information, see [dracut command line's standard parameter definition][7].

### `initrd`

| NCN Type | Default Value(s) |
|:--------:|:-----------------|
|   All    | `initrd.img.xz`  |
|   All    | `initrd`         |

> ***NOTE*** Runtime uses the name `initrd`, which hides the fact that the `initrd` is compressed.
> Both the `initrd` used in bootstrap and runtime are `xz` compressed.

For more information, see [the Linux kernel user's administrator's guide][5].

### `root`

| NCN Type |   Default Value(s)    |
|:--------:|:---------------------:|
|   All    | `live:LABEL=SQFSRAID` |

This parameter tells dracut two things:

1. We are using the [`live` module][10] for booting images.
1. Our SquashFS image is on a filesystem with the `FSLabel` of `SQFSRAID`

For more information, see [dracut command line's standard parameter definition][7], and
[`dracut-metal-mdsquash` usage][2].

### `rd.live.ram`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

This parameter determines whether or not to copy the entire SquashFS image into RAM or not. This is
useful when the media resides on a slow I/O device such as a DVD.

For more information, see [dracut command line's booting live images definitions][14].

### `rd.writable.fsimg`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

This enables writing to the SquashFS image, this is not always supported nor desired. CSM does not
want to enable writing to the image in order to preserve the original image. All changes are written
to a persistent OverlayFS instead.

For more information, see [dracut command line's booting live images definitions][14].

### `rd.skipfsck`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

This parameter skips the filesystem check when it exists (or is set to `1`). This is skipped because
it takes extra time during boot and is not always necessary.

For more information, see [dracut command line's standard parameter definition][7].

### `rd.live.squashimg`

| NCN Type |   Default Value(s)    |
|:--------:|:---------------------:|
|   All    | `filesystem.squashfs` |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.live.dir`

| NCN Type | Default Value(s) |
|:--------:|:-----------------|
|   All    | `unset`          |
|   All    | `$CSM_RELEASE`   |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.live.overlay`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    | `LABEL=ROOTRAID` |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.live.overlay.thin`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.live.overlay.overlayfs`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.live.overlay.reset`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

For more information, see [dracut command line's booting live images definitions][14].

### `rd.luks`

|      NCN Type      | Default Value(s) |
|:------------------:|:----------------:|
| Kubernetes Masters |     `exists`     |
| Kubernetes Workers |       `0`        |
|      Storage       |     `exists`     |

When this parameter exists it assumes the value of `1` and enables LUKS usage.

> ***NOTE*** Kubernetes masters and workers use the same dracut modules, in order to disable
> `dracut-metal-luksetcd` on worker nodes this parameter is set to `0`. For more information on
> how `dracut-metal-luksetcd` uses `rd.luks`, see its page [here][18].

### `rd.luks.crypttab`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

For more information, see [dracut command line's definition of LUKS parameters][16] and
[`dracut-metal-luksetcd`'s usage][19].

### `rd.lvm.conf`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

For more information, see [dracut command line's definition of LVM parameters][15] and
[`dracut-metal-luksetcd`'s usage][20].

### `rd.lvm`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

Whether or not `lvm` is enabled in the initramFS.

For more information, see [dracut command line's definition of LVM parameters][15] and
[`dracut-metal-luksetcd`'s usage][20].

### `rd.auto`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

Enable automatic assembly of special devices like `cryptoLUKS`, `dmraid`, `mdraid` or `lvm`.

> ***NOTE*** Any specific setting such as `rd.luks=0` will take precedence to `rd.auto=1`.

For more information, see [dracut command line's standard definition][7].

### `rd.md`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

This parameter enables or disables `mdraid` in the initramFS.

### `rd.dm`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

This parameter enables or disables `dmraid` in the initramFS.

> ***NOTE*** `dmraid` is not used by the NCNs.

### `rd.neednet`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

Whether or not the network is necessary for boot.

> ***NOTE*** This is useful for booting over an NFS or other network share, NCNs set this to `0`
> because despite downloading a SquashFS the `root` parameter is set to a disk `FSLabel`. As
> such, `root`
> is *not* dependent on the network to come up.

### `rd.peerdns`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

Whether or not DNS should be resolved from peers.

> ***NOTE*** This is set to `0` because it is inconsistent and the DNS will differ between boots.
> Setting this to `0` removes question whether DNS was incorrect or not, if a DHCP lease was
> received
> from CSM or PIT services then DNS will work unless core DNS providers are down.

### `rd.md.waitclean`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

Whether RAID must be clean/synced before use.

> ***NOTE*** Setting this to `0` will not workaround a dirty RAID, a dirty RAID will cause a boot
> failure.

### `rd.multipath`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

Whether or not `multipath` is used in the initramFS and in the booted OS.

> ***NOTE*** This will cause undesirable behavior when set to `1` on an NCN.

### `rd.md.conf`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

Whether or not `mdraid` should acknowledge any `md.conf` available in the initramFS.

> ***NOTE*** This is important to set to `1`, otherwise `mdraid` will not acknowledge our NCN configuration that
> specifically tells `mdraid` not to use hostnames for naming RAID devices. That means RAID `/dev/md/` devices will use
> the defined, expected names.

### `rd.bootif`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

This sets the boot interface.

> ***NOTE*** This is deprecated in native dracut. NCNs set this to `0` to ensure nothing can
> be coded to depend on it.

### `hostname`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |    `<varies>`    |

Sets the hostname for the node within the initramFS.

### `rd.net.timeout.carrier`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    | `120` (seconds)  |

The amount of time dracut will wait for a carrier to come up on a requested device.

### `rd.net.timeout.ifup`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    | `120` (seconds)  |

The amount of time dracut will wait for an interface to establish connectivity if it is requested.

### `rd.net.timeout.iflink`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    | `120` (seconds)  |

The amount of time dracut will wait for an interface to establish a link-up.

### `rd.net.dhcp.retry`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |  `5` (attempts)  |

How many times DHCP will be attempted before dracut gives up.

> ***NOTE*** If any `ip=` argument is set to `dhcp` (e.g. `ip=*:dhcp` or `ip=net0:dhcp`), then dracut will fail if an IP
> is not provided. By setting an `ip=` argument to `dhcp` the user is telling dracut that it is dependent on an IP lease.

### `rd.net.timeout.ipv6auto`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

The amount of time dracut will wait for an interface using `ipv6auto` to receive its IPv6
information.

### `rd.net.timeout.ipv6dad`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `0`        |

The amount of time dracut will wait for an interface using `ipv6auto` to receive its IPv6 DAD
information.

### `append`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `exists`     |

Deprecated/not-used.

> ***NOTE*** This parameter exists as a no-op, it is used for `sed` to key off of but it does
> nothing by itself.

### `nosplash`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `exists`     |

Disables splash screens, if they are present anywhere.

### `quiet`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `exists`     |

Minimize the output from the initramFS to only `stderr`.

> ***NOTE*** Setting `rd.info` will override this, and emit `stdout` to the console as well.

### `crashkernel`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |      `360M`      |

The amount of memory reserved in the event of a crash to run dump tools.

This must be larger than the size of the `kdump` `initrd` located in `/boot`.

### `log_buf_len`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `1`        |

Size of the kernel's internal log buffer by powers of 2.

### `split_lock_detect`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |      `off`       |

Intel has added Split Lock Detection to its 10th generation CPUs and this affects the Castle and
Wisteria
platforms which will be delivered in the Alice release. The Linux kernel has Split Lock Detect
enabled
by default, but it can be disabled on a host by adding the kernel parameter, `split_lock_detect=off`
to the kernel command line. See [this ticket][24] for more detail.

### `rd.retry`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |       `10`       |

How long dracut should retry the `initqueue` to configure devices (in seconds). See the [misc][8]
section
of dracut.

### `rd.shell`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |     `exists`     |

This parameter ensures that if the initramFS were to fail that a shell be created for an
administrator to investigate and/or provide triage information.

### `xname`

| NCN Type | Default Value(s) |
|:--------:|:----------------:|
|   All    |    `<varies>`    |

This value sets the `xname` for the node, detailing the geolocation of the node.

## Versioning

| CSM Release               | Kernel Version                                 | Kernel Change Rationale                             |
|:--------------------------|:-----------------------------------------------|-----------------------------------------------------|
| CSM 0.9.0 (Shasta v1.4.0) | 5.3.18-24.49.2                                 | Initial                                             |
| CSM 0.9.2 (Shasta v1.4.1) | 5.3.18-24.49.2                                 |                                                     |
| CSM 0.9.3 (Shasta v1.4.2) | 5.3.18-24.49.2                                 |                                                     |
| CSM 0.9.3                 | 5.3.18-24.**75.3**                             | Proactive update                                    |
| CSM 0.9.4                 | 5.3.18-24.75.3                                 |                                                     |
| CSM 0.9.5                 | 5.3.18-24.75.3                                 |                                                     |
| CSM 0.9.6                 | 5.3.18-24.75.3                                 |                                                     |
| CSM 1.0.0                 | 5.3.18-24.75.3                                 |                                                     |
| CSM 1.0.1 (Shasta v1.5.0) | 5.3.18-24.75.3                                 |                                                     |
| CSM 1.0.10                | 5.3.18-24.75.3                                 |                                                     |
| CSM 1.0.11                | 5.3.18-24.**99.1**                             | [`CVE-2021-4034`][21]                               |
| CSM 1.2.0                 | 5.3.18-**150300.59.43.1**                      | [`CVE-2022-0185`][22]                               |
| CSM 1.2.1                 | 5.3.18-150300.59.43.1                          | [`CVE-2022-0185`][22]                               |
| CSM 1.2.2                 | 5.3.18-150300.59.43.1                          |                                                     |
| CSM 1.3.0                 | 5.3.18-150300.59.**87.1**                      | [`CVE-2022-33981`][23]                              |
| CSM 1.3.1                 | 5.3.18-150300.59.87.1                          |                                                     |
| CSM 1.4.0                 | 5.**14.21-150400.24.38.1.25440.1.PTF.1204911** | SLES-15-SP4 upgrade and SUSE patch (case #00502283) |
| CSM 1.5.0                 | 5.14.21-150400.24.**66.1**                     |                                                     |

[1]:https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-consistent_network_device_naming_using_biosdevname

[2]:https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#usage

[3]:https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#metalno-wipe

[4]:https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#metalwipe-delay

[5]:https://docs.kernel.org/admin-guide/initrd.html

[6]:https://cloudinit.readthedocs.io/en/21.4/topics/datasources/nocloud.html

[7]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#standard

[8]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#misc

[10]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#md-raid

[13]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#network

[14]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#booting-live-images

[15]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#lvm

[16]:https://github.com/dracutdevs/dracut/blob/master/man/dracut.cmdline.7.asc#crypto-luks

[18]:https://github.com/Cray-HPE/dracut-metal-luksetcd/blob/main/README.md#rdluks

[19]:https://github.com/Cray-HPE/dracut-metal-luksetcd/blob/main/README.md#rdlukscryptab

[20]:https://github.com/Cray-HPE/dracut-metal-luksetcd/blob/main/README.md#rdlvmconf

[21]:https://www.suse.com/security/cve/CVE-2021-4034.html

[22]:https://www.suse.com/security/cve/CVE-2022-0185.html

[23]:https://www.suse.com/security/cve/CVE-2022-33981.html

[24]:https://www.virtualbox.org/ticket/20180
