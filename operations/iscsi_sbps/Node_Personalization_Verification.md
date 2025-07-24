# Post-personalization Verification

(`ncn-w#`) Run these checks on each worker node, in order to verify that it was configured correctly.

1. Verify that the SBPS Marshal Agent is running without any errors.

    ```bash
    systemctl status sbps-marshal
    ```

    Beginning of example output:

    ```text
    ● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE.
         Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; vendor preset: disabled)
         Active: active (running) since Thu 2024-08-22 11:57:48 UTC; 2 weeks 4 days ago
       Main PID: 2878373 (sbps-marshal)
          Tasks: 1
         CGroup: /system.slice/sbps-marshal.service
                 └─ 2878373 /usr/lib/sbps-marshal/bin/python /usr/lib/sbps-marshal/bin/sbps-marshal
    ```

1. Verify that the images and LUN mappings have been created.

    Check to see if the `fileio` backing stores exist for `rootfs` images,
    along with corresponding iSCSI `LUNs`. These should have the `rootfs` ID being mapped and network portals created (HSN and NMN).

    ```bash
    targetcli ls
    ```

    Example output:

    ```text
    o- / ......................................................................................................................... [...]
      o- backstores .............................................................................................................. [...]
      | o- block .................................................................................................. [Storage Objects: 0]
      | o- fileio ................................................................................................. [Storage Objects: 4]
      | | o- 059c573240acc07  [/var/lib/cps-local/boot-images/1681d5d6-bfaf-41e6-9dd4-2cc355314476/rootfs (3.7GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- 553a9957f5efcbf  [/var/lib/cps-local/boot-images/c434edc1-8080-43c5-8393-4ab831d9eb00/rootfs (2.1GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- ad7d9e9736a1b8a  [/var/lib/cps-local/boot-images/f1d6c8fe-32e2-420a-a051-377e34a8bd8a/rootfs (3.6GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- cd5c6354b0d12d2  [/var/lib/cps-local/boot-images/6e993608-068a-4f6d-8d3f-b904ff7d3602/rootfs (3.7GiB) write-thru activated]
      | |   o- alua ................................................................................................... [ALUA Groups: 1]
      | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | o- pscsi .................................................................................................. [Storage Objects: 0]
      | o- ramdisk ................................................................................................ [Storage Objects: 0]
      | o- rbd .................................................................................................... [Storage Objects: 0]
      o- iscsi ............................................................................................................ [Targets: 1]
      | o- iqn.2023-06.csm.iscsi:ncn-w001 .................................................................................... [TPGs: 1]
      |   o- tpg1 .................................................................................................. [gen-acls, no-auth]
      |     o- acls .......................................................................................................... [ACLs: 0]
      |     o- luns .......................................................................................................... [LUNs: 4]
      |     | o- lun0  [fileio/ad7d9e9736a1b8a (/var/lib/cps-local/boot-images/f1d6c8fe-32e2-420a-a051-377e34a8bd8a/rootfs) (default_tg_pt_gp)]
      |     | o- lun1  [fileio/cd5c6354b0d12d2 (/var/lib/cps-local/boot-images/6e993608-068a-4f6d-8d3f-b904ff7d3602/rootfs) (default_tg_pt_gp)]
      |     | o- lun2  [fileio/059c573240acc07 (/var/lib/cps-local/boot-images/1681d5d6-bfaf-41e6-9dd4-2cc355314476/rootfs) (default_tg_pt_gp)]
      |     | o- lun3  [fileio/553a9957f5efcbf (/var/lib/cps-local/boot-images/c434edc1-8080-43c5-8393-4ab831d9eb00/rootfs) (default_tg_pt_gp)]
      |     o- portals .................................................................................................... [Portals: 3]
      |       o- 10.102.193.24:3260 ............................................................................................... [OK]
      |       o- 10.252.1.9:3260 .................................................................................................. [OK]
      |       o- 10.253.0.2:3260 .................................................................................................. [OK]
      o- loopback ......................................................................................................... [Targets: 0]
      o- vhost ............................................................................................................ [Targets: 0]
      o- xen-pvscsi ....................................................................................................... [Targets: 0]
    ```

1. Verify that all the DNS SRV and A records are configured for all the intended worker nodes.

    ```bash
    dig -t SRV +short _sbps-hsn._tcp.odin.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.odin.hpc.amslabs.hpecorp.net
    ```

    Example output:

    ```text
    1 0 3260 iscsi-server-id-001.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-004.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-006.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-002.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-003.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-005.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-004.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-001.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-005.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-003.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-002.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-006.nmn.odin.hpc.amslabs.hpecorp.net.
    ```

    ```bash
    dig -t A +short iscsi-server-id-005.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-005.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.odin.hpc.amslabs.hpecorp.net.
    ```

    Example output:

    ```text
    10.253.0.6
    10.253.0.16
    10.253.0.18
    10.253.0.20
    10.253.0.2
    10.253.0.4
    10.252.1.7
    10.252.1.9
    10.252.1.12
    10.252.1.8
    10.252.1.10
    10.252.1.11
    ```

1. Run readiness checks.

    After worker node personalization, in order to verify the overall readiness of the iSCSI targets before booting compute nodes or UANs,
    run GOSS tests to do additional verification of the iSCSI targets.

    See [GOSS tests for SBPS](https://github.com/Cray-HPE/sbps-marshal/blob/main/GOSS_tests_for_sbps.md) for more information.
