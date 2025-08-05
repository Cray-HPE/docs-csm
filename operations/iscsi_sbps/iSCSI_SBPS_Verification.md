# iSCSI SBPS Verification

* [Introduction](#introduction)
* [Automated tests](#automated-tests)
* [Node personalization](#node-personalization)
* [iSCSI-enabled workers](#iscsi-enabled-workers)
* [SBPS Marshal Agent](#sbps-marshal-agent)
* [`targetcli` command](#targetcli-command)
* [`multipath` command](#multipath-command)
* [DNS SRV and A records](#dns-srv-and-a-records)

## Introduction

Before booting managed nodes, it is important to validate the iSCSI configuration. Most of this configuration is either done
by the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
during [Node personalization](#node-personalization), or done periodically by the [SBPS Marshal Agent](#sbps-marshal-agent).

## Automated tests

The fastest way to check the overall readiness of the iSCSI targets is to run the automated Goss health checks.

(`ncn-mw#`) Execute all of the worker automated health checks (including those for iSCSI):

```bash
 /opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker
 ```

## Node personalization

The `config_sbps_iscsi_targets.yml` Ansible playbook in the `csm-config-management`
[Version Control Service (VCS)](../../glossary.md#version-control-service-vcs) repository is responsible for much of the
iSCSI configuration. During [Management Node Personalization](../configuration_management/Management_Node_Personalization.md),
this playbook does the following:

* Installs the [SBPS Marshal Agent](#sbps-marshal-agent)
* Adds iSCSI Kubernetes labels to the worker NCNs
* Creates DNS SRV and A records for the workers.

## iSCSI-enabled workers

(`ncn-mw#`) List all iSCSI-enabled worker NCNs.

```bash
kubectl get nodes -l iscsi=sbps
```

Example output:

```text
NAME       STATUS   ROLES    AGE    VERSION
ncn-w001   Ready    <none>   7d2h   v1.32.5
ncn-w002   Ready    <none>   6d     v1.32.5
ncn-w003   Ready    <none>   7d1h   v1.32.5
ncn-w004   Ready    <none>   7d1h   v1.32.5
```

## SBPS Marshal Agent

The SBPS Marshal Agent runs on the iSCSI-enabled worker NCNs as a Linux `systemd` service.
Every 180 seconds it looks for `rootfs` and `PE` images in the
[Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
and [S3](../../glossary.md#simple-storage-service-s3) storage.
For any image found, the Marshal Agent creates `fileio` backing stores and corresponding
iSCSI `LUNs`. This enables the images to be projected.

The following steps should be performed on every iSCSI-enabled worker NCN, in order to ensure that
the Marshal Agent is running without errors.

1. (`ncn-w#`) Check that the SBPS Marshal Agent is running on every iSCSI-enabled node without any errors.

    ```bash
    systemctl status sbps-marshal -n 3
    ```

    The most important thing to verify in the command output is that the service is `active (running)`.

    Example output:

    ```text
    ● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE.
         Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; preset: disabled)
         Active: active (running) since Mon 2025-07-28 20:17:17 UTC; 6 days ago
       Main PID: 342842 (sbps-marshal)
          Tasks: 1
            CPU: 1h 16min 21.251s
         CGroup: /system.slice/sbps-marshal.service
                 └─342842 /usr/lib/sbps-marshal/bin/python /usr/lib/sbps-marshal/bin/sbps-marshal

    Aug 04 18:40:34 ncn-w001 sbps-marshal[342842]: agent.py:main:314 INFO 2025-08-04T18:40:34+0000 No sbps-project key value, so image is not marked for projection
    Aug 04 18:40:34 ncn-w001 sbps-marshal[342842]: agent.py:main:314 INFO 2025-08-04T18:40:34+0000 No sbps-project key value, so image is not marked for projection
    Aug 04 18:40:34 ncn-w001 sbps-marshal[342842]: agent.py:main:405 INFO 2025-08-04T18:40:34+0000 END SCAN
    ```

1. (`ncn-w#`) Check for errors in the current Marshal Agent run.

    Any errors shown by this command should be investigated.

    ```bash
    journalctl -xeu sbps-marshal.service | tac | sed '/START SCAN/q' | grep -i error
    ```

## `targetcli` command

(`ncn-w#`) On each of the iSCSI-enabled worker NCNs, display information on the `fileio` backing stores, LUNs, and network portals.

> For more details on the information discussed in this section, see [iSCSI SBPS solution details](README.md#iscsi-sbps-solution-details).

```bash
targetcli ls
```

### `targetcli` command example 1

Example output:

> Below the example output are guides on how to interpret its contents.

```text
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................ [Storage Objects: 14]
  | | o- 162eec8935d9251  [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-25.09-20250701.squashfs (771.8MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 2b9d303c515911a ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-25.03.squashfs (320.8MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 31fcfe145252d40  [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.09-20250701.squashfs (191.2MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 602f57d78f7162d ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.03.squashfs (117.3MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 7de5e25dcbfeb8e  [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-25.09-20250701.squashfs (748.4MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 7df1b36a366a1a3  [/var/lib/cps-local/boot-images/83f3f34c-b09c-445b-8253-f0708f588328/rootfs (4.2GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 83b09a0062d4edb .......... [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs (2.6GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 851b2a42d007322 ......... [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-25.03.squashfs (298.1MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 8767f2cfdb49d5f  [/var/lib/cps-local/boot-images/efd2f545-1a08-4f63-bd18-45c2bfcf7efc/rootfs (4.3GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- a1ceab379f1c908  [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-25.09-20250701.squashfs (199.6MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- a78fe7060cf474d  [/var/lib/cps-local/boot-images/5095f83f-b500-4f7c-81be-76b185ad7108/rootfs (2.5GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- d4b0cd14d4625db  [/var/lib/cps-local/boot-images/50256d2c-60a8-41f8-ab37-901515d607e8/rootfs (2.4GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- dc28db97d8d01d5 . [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.09-20250701.squashfs (6.7GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- eb63d6793a27096 ........ [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-25.03.squashfs (121.9MiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2023-06.csm.iscsi:ncn-w002 .................................................................................... [TPGs: 1]
  |   o- tpg1 .................................................................................................. [gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 0]
  |     o- luns ......................................................................................................... [LUNs: 14]
  |     | o- lun0 .... [fileio/851b2a42d007322 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-25.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun1  [fileio/7de5e25dcbfeb8e (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-25.09-20250701.squashfs) (default_tg_pt_gp)]
  |     | o- lun2 ... [fileio/eb63d6793a27096 (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-25.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun3  [fileio/a1ceab379f1c908 (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-25.09-20250701.squashfs) (default_tg_pt_gp)]
  |     | o- lun4 ... [fileio/83b09a0062d4edb (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun5  [fileio/dc28db97d8d01d5 (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.09-20250701.squashfs) (default_tg_pt_gp)]
  |     | o- lun6 .. [fileio/602f57d78f7162d (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun7  [fileio/31fcfe145252d40 (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.09-20250701.squashfs) (default_tg_pt_gp)]
  |     | o- lun8 . [fileio/2b9d303c515911a (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-25.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun9  [fileio/162eec8935d9251 (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-25.09-20250701.squashfs) (default_tg_pt_gp)]
  |     | o- lun10  [fileio/7df1b36a366a1a3 (/var/lib/cps-local/boot-images/83f3f34c-b09c-445b-8253-f0708f588328/rootfs) (default_tg_pt_gp)]
  |     | o- lun11  [fileio/8767f2cfdb49d5f (/var/lib/cps-local/boot-images/efd2f545-1a08-4f63-bd18-45c2bfcf7efc/rootfs) (default_tg_pt_gp)]
  |     | o- lun12  [fileio/d4b0cd14d4625db (/var/lib/cps-local/boot-images/50256d2c-60a8-41f8-ab37-901515d607e8/rootfs) (default_tg_pt_gp)]
  |     | o- lun13  [fileio/a78fe7060cf474d (/var/lib/cps-local/boot-images/5095f83f-b500-4f7c-81be-76b185ad7108/rootfs) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 2]
  |       o- 10.252.1.8:3260 .................................................................................................. [OK]
  |       o- 10.253.0.2:3260 .................................................................................................. [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- srpt ............................................................................................................. [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

The following provide examples of how to interpret the command output.

#### PE image

The example output gives information about the PE image `CPE-intel.x86_64-25.03.squashfs`.

* `fileio` backing store

    ```text
      | | o- 602f57d78f7162d ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.03.squashfs (117.3MiB) write-thru activated]
    ```

    This line in the example output shows that the `fileio` backing store for the PE image exists and is
    `/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.03.squashfs`.

* LUN

    ```text
      |     | o- lun6 .. [fileio/602f57d78f7162d (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-25.03.squashfs) (default_tg_pt_gp)]
    ```

    This line in the example output shows that the LUN for the PE image exists and is `lun6`.

#### IMS `rootfs` image

The example output also gives information about the `rootfs` for the IMS image with ID `50256d2c-60a8-41f8-ab37-901515d607e8`.

* `fileio` backing store

    ```text
      | | o- d4b0cd14d4625db  [/var/lib/cps-local/boot-images/50256d2c-60a8-41f8-ab37-901515d607e8/rootfs (2.4GiB) write-thru activated]
    ```

    This line in the example output shows that the `fileio` backing store for the `rootfs` image exists and is
    `/var/lib/cps-local/boot-images/50256d2c-60a8-41f8-ab37-901515d607e8/rootfs`.

* LUN

    ```text
     |     | o- lun12  [fileio/d4b0cd14d4625db (/var/lib/cps-local/boot-images/50256d2c-60a8-41f8-ab37-901515d607e8/rootfs) (default_tg_pt_gp)]
    ```

    This line in the example output shows that the LUN for the `rootfs` image exists and is `lun12`.

#### Network portals

There should be portals configured for iSCSI projection for the
[High Speed Network (HSN)](../../glossary.md#high-speed-network-hsn) or the
[Node Management Network (NMN)](../../glossary.md#node-management-network-nmn), or both.
If neither of these portals is configured, then managed nodes will be unable to boot.

```text
 |     o- portals .................................................................................................... [Portals: 2]
 |       o- 10.252.1.8:3260 .................................................................................................. [OK]
 |       o- 10.253.0.2:3260 .................................................................................................. [OK]
```

These lines in the example output show the portals that are configured for iSCSI projection. They consist of the HSN or NMN IP address
and the iSCSI port number.

(`ncn-w#`) Determining which network the a portal belongs to is done by comparing its IP address to the NMN and HSN network interfaces:

```bash
ip addr | grep -E 'hsn|nmn'
```

Example output:

```text
4: hsn0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP group default qlen 1000
    inet 10.253.0.2/16 brd 10.253.255.255 scope global hsn0
12: bond0.nmn0@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP group default qlen 1000
    inet 10.252.1.8/17 brd 10.252.127.255 scope global bond0.nmn0
```

Based on this example output, the portal `10.253.0.2:3260` corresponds to the HSN, and `10.252.1.8:3260` corresponds to the NMN.

### `targetcli` command example 2

(`ncn-w#`) Example output:

```text
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................ [Storage Objects: 28]
  | | o- 0331b9aaef49840 ......... [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.03.squashfs (122.2MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 0f3847fd8e25624 ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.03.squashfs (114.8MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 1373e69e2028baa ......... [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.11.squashfs (503.4MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 2babe2c96d6f900 ......... [/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-23.12.squashfs (1.9GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 380840014ffe295  [/var/lib/cps-local/boot-images/f731d8d5-0fed-41d7-996e-6a0d19b6ff6d/rootfs (10.8GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 719593b460753ac ........ [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.11.squashfs (131.6MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 76e638d3bfc3107 ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-23.12.squashfs (64.0KiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 7c0bba5c5301c97  [/var/lib/cps-local/boot-images/5b43428e-4381-4f39-9335-6dababb76d86/rootfs (2.9GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 7cccd5c7adc8cc6 ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-23.12.squashfs (114.4MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 818ff2c161855b6 ........ [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.03.squashfs (117.9MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 85801b9e9c9cea7 ......... [/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-24.03.squashfs (2.0GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 8edfc76b6dae21f ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.03.squashfs (134.1MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 953aa229aafffa6 ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.11.squashfs (128.6MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 979b7868c15ee00 ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-23.12.squashfs (123.2MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 9de1fe8a016602f ......... [/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-24.07.squashfs (2.0GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- 9f7ee65eadd1d3c ..... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-24.07.squashfs (272.3MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- a50dd52157e1636 ......... [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-23.12.squashfs (121.9MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- a6db212e5a329fa .......... [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.03.squashfs (2.4GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- aac0f352b7a30d6 ....... [/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.07.squashfs (110.1MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- b91b33a9f98a0be ........ [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.07.squashfs (113.2MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- c1d98cf92b0647f ........ [/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-23.12.squashfs (117.9MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- cfaa140ac182849 ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.07.squashfs (333.5MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- d265658496338c0 ......... [/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.07.squashfs (298.2MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- d797313856f7502 .......... [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.07.squashfs (2.4GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- da65cccd2e89d0c ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.11.squashfs (555.7MiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- de4cc04e7dacfb9 .......... [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.11.squashfs (7.7GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- e41757ef248d642 .......... [/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-23.12.squashfs (2.4GiB) write-thru activated]
  | | | o- alua ................................................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | | o- e837346fddf2004 ...... [/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-24.03.squashfs (92.5MiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2023-06.csm.iscsi:ncn-w002 .................................................................................... [TPGs: 1]
  |   o- tpg1 .................................................................................................. [gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 0]
  |     o- luns ......................................................................................................... [LUNs: 28]
  |     | o- lun0 .... [fileio/a50dd52157e1636 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun1 .... [fileio/0331b9aaef49840 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun2 .... [fileio/d265658496338c0 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun3 .... [fileio/1373e69e2028baa (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-24.11.squashfs) (default_tg_pt_gp)]
  |     | o- lun4 ... [fileio/c1d98cf92b0647f (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun5 ... [fileio/818ff2c161855b6 (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun6 ... [fileio/b91b33a9f98a0be (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun7 ... [fileio/719593b460753ac (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-24.11.squashfs) (default_tg_pt_gp)]
  |     | o- lun8 .. [fileio/2babe2c96d6f900 (/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun9 .. [fileio/85801b9e9c9cea7 (/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun10 . [fileio/9de1fe8a016602f (/var/lib/cps-local/boot-images/PE/CPE-base.aarch64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun11 .. [fileio/e41757ef248d642 (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun12 .. [fileio/a6db212e5a329fa (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun13 .. [fileio/d797313856f7502 (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun14 .. [fileio/de4cc04e7dacfb9 (/var/lib/cps-local/boot-images/PE/CPE-base.x86_64-24.11.squashfs) (default_tg_pt_gp)]
  |     | o- lun15 . [fileio/7cccd5c7adc8cc6 (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun16 . [fileio/0f3847fd8e25624 (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun17 . [fileio/aac0f352b7a30d6 (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun18 . [fileio/953aa229aafffa6 (/var/lib/cps-local/boot-images/PE/CPE-intel.x86_64-24.11.squashfs) (default_tg_pt_gp)]
  |     | o- lun19  [fileio/76e638d3bfc3107 (/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun20  [fileio/e837346fddf2004 (/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun21  [fileio/9f7ee65eadd1d3c (/var/lib/cps-local/boot-images/PE/CPE-nvidia.aarch64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun22  [fileio/979b7868c15ee00 (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-23.12.squashfs) (default_tg_pt_gp)]
  |     | o- lun23  [fileio/8edfc76b6dae21f (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.03.squashfs) (default_tg_pt_gp)]
  |     | o- lun24  [fileio/cfaa140ac182849 (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.07.squashfs) (default_tg_pt_gp)]
  |     | o- lun25  [fileio/da65cccd2e89d0c (/var/lib/cps-local/boot-images/PE/CPE-nvidia.x86_64-24.11.squashfs) (default_tg_pt_gp)]
  |     | o- lun26  [fileio/7c0bba5c5301c97 (/var/lib/cps-local/boot-images/5b43428e-4381-4f39-9335-6dababb76d86/rootfs) (default_tg_pt_gp)]
  |     | o- lun27  [fileio/380840014ffe295 (/var/lib/cps-local/boot-images/f731d8d5-0fed-41d7-996e-6a0d19b6ff6d/rootfs) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 3]
  |       o- 10.102.104.28:3260 ............................................................................................... [OK]
  |       o- 10.150.0.4:3260 .................................................................................................. [OK]
  |       o- 10.252.1.13:3260 ................................................................................................. [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

The above `targetcli ls` command output shows the following:

* Four `fileio` backing store are created for two `rootfs` images
* Two iSCSI `LUNs` are created which have the `rootfs` image ID being mapped
* 26 `PE` or `squashfs` `fileio` backing store are created
* 26 iSCSI `LUNs` created which have the `PE` or `squashfs` image ID being mapped
* These iSCSI `LUNs` are ready for projection

## `multipath` command

(`nid#`) Administrators may also view the state of the initiator nodes (i.e. managed nodes using iSCSI LUNs).

> For more details on the information discussed in this section, see [iSCSI SBPS solution details](README.md#iscsi-sbps-solution-details).

```bash
multipath -ll
```

Example output:

```text
11218.831779 | /etc/multipath.conf line 10: ignoring deprecated option "disable_changed_wwids", using built-in value: "yes"
PE_CPE-base.x86_64-24.11.squashfs (36001405de4cc04e7dacfb9ada0a6b4cc) dm-0 LIO-ORG,de4cc04e7dacfb9
size=7.7G features='1 queue_if_no_path' hwhandler='1 alua' wp=ro
`-+- policy='round-robin 0' prio=50 status=active
  |- 1:0:0:14 sdo  8:224  active ready running
  |- 2:0:0:14 sdaq 66:160 active ready running
  |- 3:0:0:14 sdbs 68:96  active ready running
  `- 4:0:0:14 sdcu 70:32  active ready running
f731d8d5-0fed-41d7-996e-6a0d19b6ff6d_rootfs (36001405380840014ffe295091e8689db) dm-24 LIO-ORG,380840014ffe295
size=11G features='1 queue_if_no_path' hwhandler='1 alua' wp=ro
`-+- policy='round-robin 0' prio=50 status=active
  |- 1:0:0:27 sdab 65:176 active ready running
  |- 2:0:0:27 sdbd 67:112 active ready running
  |- 3:0:0:27 sdcf 69:48  active ready running
  `- 4:0:0:27 sddh 70:240 active ready running
```

## DNS SRV and A records

The DNS records check only needs to be performed on a single worker NCN.

1. (`ncn-w#`) Verify that every iSCSI-enabled worker NCN has DNS SRV and A records.

    1. Get the system domain name.

        ```bash
        DOMAIN=$(kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' \
                 | base64 -d | yq4 .spec.network.dns.external); echo "${DOMAIN}"
        ```

        Example output:

        ```text
        drax.hpc.amslabs.hpecorp.net
        ```

    1. List the DNS SRV records for SBPS on the HSN and NMN.

        ```bash
        dig -t SRV +short "_sbps-hsn._tcp.${DOMAIN}" "_sbps-nmn._tcp.${DOMAIN}"
        ```

        Example output:

        ```text
        1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
        1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
        ```

        Each `iscsi-server-id` number corresponds to a different worker NCN.
        After that ID comes the network (`hsn` or `nmn` for that record).
        This example output shows that DNS SRV records exist for four worker NCNs, on both the HSN and NMN.

1. (`ncn-w#`) Verify that a DNS A record exists for each DNS SRV record.

    ```bash
    dig -t SRV +short "_sbps-hsn._tcp.${DOMAIN}" "_sbps-nmn._tcp.${DOMAIN}" \
        | awk '{ print $NF }' | xargs dig -t A +short
    ```

    Example output:

    ```text
    10.253.0.2
    10.253.0.8
    10.253.0.9
    10.253.0.14
    10.252.1.7
    10.252.1.8
    10.252.1.9
    10.252.1.10
    ```

    Confirm that the number of DNS A records listed by this command equals the number of DNS SRV records listed in the previous step.
    If any NMN A records are not created, then see [iSCSI NMN DNS A Records Missing](../../troubleshooting/known_issues/iSCSI_NMN_DNS_A_Records_Missing.md).
