# Prepare Storage Nodes

Prepare a storage node before rebuilding it.

**IMPORTANT:** All of the output examples may not reflect the cluster status where this operation is being performed. For example, if this is a rebuild in place, then Ceph components will not be reporting down, in contrast to a failed node rebuild.

## Prerequisites

If rebuilding `ncn-s001`, it is critical that the `storage-ceph-cloudinit.sh` has been removed from the `runcmd` in BSS.

1. Get the component name (xname) for `ncn-s001`.

   ```bash
   linux# ssh ncn-s001 cat /etc/cray/xname
   ```

2. Check the bss boot parameters for `ncn-s001`.

   ```bash
   ncn# cray bss bootparameters list --name x3000c0s7b0n0 --format=json|jq -r '.[]|.["cloud-init"]|.["user-data"].runcmd'
   ```

   Expected Output:

   ```json
   [
   "/srv/cray/scripts/metal/install-bootloader.sh",
   "/srv/cray/scripts/metal/set-host-records.sh",
   "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
   "/srv/cray/scripts/metal/set-dns-config.sh",
   "/srv/cray/scripts/metal/set-ntp-config.sh",
   "/srv/cray/scripts/metal/enable-lldp.sh",
   "/srv/cray/scripts/metal/set-bmc-bbs.sh",
   "/srv/cray/scripts/metal/set-efi-bbs.sh",
   "/srv/cray/scripts/metal/disable-cloud-init.sh",
   "/srv/cray/scripts/common/update_ca_certs.py",
   "/srv/cray/scripts/metal/install-rpms.sh",
   "/srv/cray/scripts/common/pre-load-images.sh",
   "/srv/cray/scripts/common/ceph-enable-services.sh"
   ]
   ```

   If it is there then it will need to be fixed by running:

   **IMPORTANT:** The below python script is provided by the `docs-csm` RPM. To install the latest version of it, see [Check for Latest Documentation](../../../update_product_stream/index.md#documentation).

   ```bash
   ncn# python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
   ```

## Procedure

Check the status of Ceph.

1. If the node is up, then stop and disable all the Ceph services on the node being rebuilt.

    On the node being rebuilt run:

    ```bash
    ncn-s# for service in $(cephadm ls |jq -r '.[].systemd_unit'); do systemctl stop $service; systemctl disable $service; done
    ```

    Example output:

    ```screen
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.39.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mgr.ncn-s003.tjuyhj.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mon.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.41.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.36.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.37.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mds.cephfs.ncn-s003.jcnovs.    service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.40.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@crash.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@node-exporter.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.38.service.
    ```

1. If the node is up, then stop and disable all the Ceph services on the node being rebuilt.

    On the node being rebuilt run:

    ```bash
    ncn-s# for service in $(cephadm ls |jq -r '.[].systemd_unit'); do systemctl stop $service; systemctl disable $service; done
    ```

    Example output:

    ```screen
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.39.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mgr.ncn-s003.tjuyhj.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mon.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.41.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.36.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.37.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mds.cephfs.ncn-s003.jcnovs.    service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.40.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@crash.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@node-exporter.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.38.service.
    ```

1. Check the OSD status, weight, and location:

    ```bash
    ncn-s# ceph osd tree
    ```

    Example output:

    ```
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95917 root default
    -3        6.98639     host ncn-s001
     2   ssd  1.74660         osd.2         up  1.00000 1.00000
     5   ssd  1.74660         osd.5         up  1.00000 1.00000
     8   ssd  1.74660         osd.8         up  1.00000 1.00000
    11   ssd  1.74660         osd.11        up  1.00000 1.00000
    -7        6.98639     host ncn-s002
     0   ssd  1.74660         osd.0         up  1.00000 1.00000
     4   ssd  1.74660         osd.4         up  1.00000 1.00000
     7   ssd  1.74660         osd.7         up  1.00000 1.00000
    10   ssd  1.74660         osd.10        up  1.00000 1.00000
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1       down        0 1.00000
     3   ssd  1.74660         osd.3       down        0 1.00000
     6   ssd  1.74660         osd.6       down        0 1.00000
     9   ssd  1.74660         osd.9       down        0 1.00000
    ```

1. Check the status of the Ceph cluster:

    ```screen
    ncn-s# ceph -s
    ```

    Example output:

    ```
      cluster:
        id:     184b8c56-172d-11ec-aa96-a4bf0138ee14
        health: HEALTH_WARN
                1/3 mons down, quorum ncn-s001,ncn-s002
                6 osds down
                1 host (6 osds) down
                Degraded data redundancy: 21624/131171 objects degraded (16.485%),     522 pgs degraded, 763 pgs undersized

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002 (age 3m), out of quorum: ncn-s003
        mgr: ncn-s001.afiqwl(active, since 14h), standbys: ncn-s002.nafbdr
        mds: cephfs:1 {0=cephfs.ncn-s001.nzsgxr=up:active} 1 up:standby-replay
        osd: 36 osds: 30 up (since 3m), 36 in (since 14h)
        rgw: 3 daemons active (site1.zone1.ncn-s002.tipbuf, site1.zone1.ncn-s004.    uvzcms, site1.zone1.ncn-s005.twisxx)

      task status:

      data:
        pools:   12 pools, 1641 pgs
        objects: 43.72k objects, 81 GiB
        usage:   228 GiB used, 63 TiB / 63 TiB avail
        pgs:     21624/131171 objects degraded (16.485%)
                 878 active+clean
                 522 active+undersized+degraded
                 241 active+undersized

      io:
        client:   6.2 KiB/s rd, 280 KiB/s wr, 2 op/s rd, 49 op/s wr
    ```

1. Remove Ceph OSDs.

    The `ceph osd tree` capture indicated that there are down OSDs on `ncn-s003`.

     ```screen
     ncn-s# ceph osd tree down
     ```

     Example output:

     ```
     ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
     -1         62.87750  root default
     -9         10.47958      host ncn-s003
     36    ssd   1.74660          osd.36       down   1.00000  1.00000
     37    ssd   1.74660          osd.37       down   1.00000  1.00000
     38    ssd   1.74660          osd.38       down   1.00000  1.00000
     39    ssd   1.74660          osd.39       down   1.00000  1.00000
     40    ssd   1.74660          osd.40       down   1.00000  1.00000
     41    ssd   1.74660          osd.41       down   1.00000  1.00000
     ```

    1. Remove the OSD references to allow the rebuild to re-use the original OSD references on the drives. By default, if the OSD reference is not removed, then there will still a reference to them in the CRUSH map. This will result in OSDs that no longer exist appearing to be down.

      The following command assumes the variables from [the prerequisites section](Rebuild_NCNs.md#Prerequisites) are set.

      This must be run from a `ceph-mon` node (ncn-s00[1/2/3])

      ```bash
      ncn-s# for osd in $(ceph osd ls-tree $NODE); do ceph osd destroy osd.$osd --force; ceph osd purge osd.$osd --force; done
      ```

      Example Output:

      ```screen
      destroyed osd.1
      purged osd.1
      destroyed osd.3
      purged osd.3
      destroyed osd.6
      purged osd.6
      destroyed osd.9
      purged osd.9
      ```

## Next Step

Proceed to the next step to [Identify Nodes and Update Metadata](Identify_Nodes_and_Update_Metadata.md) or return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
