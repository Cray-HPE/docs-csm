# Prepare Storage Nodes

Prepare a storage node before rebuilding it.

**IMPORTANT:** All of the output examples may not reflect the cluster status where this operation is being performed. For example, if this is a rebuild in place, then Ceph components will not be reporting down, in contrast to a failed node rebuild.

## Prerequisites

When rebuilding a node, make sure that `/srv/cray/scripts/common/storage-ceph-cloudinit.sh` and `/srv/cray/scripts/common/pre-load-images.sh` have been removed from the `runcmd` in BSS.

1. (`ncn-m001#`) Set node name and xname if not already set.

   ```bash
   NODE=ncn-s00n
   ```

   ```bash
   XNAME=$(ssh $NODE cat /etc/cray/xname)
   ```

1. (`ncn-m001#`) Get the `runcmd` in BSS.

   ```bash
   cray bss bootparameters list --name ${XNAME} --format=json|jq -r '.[]|.["cloud-init"]|.["user-data"].runcmd'
   ```

   Expected Output:

   ```json
   [
   "/srv/cray/scripts/metal/net-init.sh",
   "/srv/cray/scripts/common/update_ca_certs.py",
   "/srv/cray/scripts/metal/install.sh",
   "/srv/cray/scripts/common/ceph-enable-services.sh",
   "touch /etc/cloud/cloud-init.disabled"
   ]
   ```

   If `/srv/cray/scripts/common/storage-ceph-cloudinit.sh` or `/srv/cray/scripts/common/pre-load-images.sh` is in the `runcmd`, then it will need to be fixed by running:

   A token will need to be generated and made available as an environment variable. Refer to the [Retrieve an Authentication Token](../../security_and_authentication/Retrieve_an_Authentication_Token.md) procedure for more information.

   **IMPORTANT:** The below python script is provided by the `docs-csm` RPM. To install the latest version of it, see [Check for Latest Documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

   ```bash
   python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
   ```

## Procedure

Upload Ceph container images into nexus.

1. Logged into one of (`ncn-s00[1/2/3]`), execute the `upload_ceph_images_to_nexus.sh`.

   ```bash
   /srv/cray/scripts/common/upload_ceph_images_to_nexus.sh
   ```

Check the status of Ceph.

1. Check the OSD status, weight, and location:

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -5         20.95853      host ncn-s001
    2    ssd   3.49309          osd.2          up   1.00000  1.00000
    5    ssd   3.49309          osd.5          up   1.00000  1.00000
    6    ssd   3.49309          osd.6          up   1.00000  1.00000
    9    ssd   3.49309          osd.9          up   1.00000  1.00000
    12   ssd   3.49309          osd.12         up   1.00000  1.00000
    16   ssd   3.49309          osd.16         up   1.00000  1.00000
    -3         20.95853      host ncn-s002
    0    ssd   3.49309          osd.0          up   1.00000  1.00000
    3    ssd   3.49309          osd.3          up   1.00000  1.00000
    7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10   ssd   3.49309          osd.10         up   1.00000  1.00000
    13   ssd   3.49309          osd.13         up   1.00000  1.00000
    15   ssd   3.49309          osd.15         up   1.00000  1.00000
    -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1          up   1.00000  1.00000
    4    ssd   3.49309          osd.4          up   1.00000  1.00000
    8    ssd   3.49309          osd.8          up   1.00000  1.00000
    11   ssd   3.49309          osd.11         up   1.00000  1.00000
    14   ssd   3.49309          osd.14         up   1.00000  1.00000
    17   ssd   3.49309          osd.17         up   1.00000  1.00000

2. If the node is up, then stop and disable all the Ceph services on the node being rebuilt.

    From `(ncn-s00[1/2/3])`, run:

    ```bash
    ceph orch maintenance enter <storage node hostname being rebuilt>
    ```

    Example output:

    ```screen
    ncn-s001:~ # ceph orch host maintenance enter ncn-s003 --force
    Daemons for Ceph cluster 5f79a490-c281-11ed-b6ec-fa163e741e89 stopped on host ncn-s003. Host ncn-s003 moved to maintenance mode
    ```

    **IMPORTANT**: The --force flag is used to bypass warnings.  These pertain to ceph services which can handle failures like rgw.  
    * ***IF*** the command returns any lines with an **ALERT** status then please follow the output to remedy.  
      * Typically this will be something like the active MGR process is on that node and you have to fail it over first.  

    Example:

    ```screen
    ncn-s001:~ # ceph orch host maintenance enter ncn-s003
    WARNING: Stopping 1 out of 1 daemons in Alertmanager service. Service will not be operational with no daemons left. At least 1 daemon must be running to guarantee service.
    ALERT: Cannot stop active Mgr daemon, Please switch active Mgrs with 'ceph mgr fail ncn-s003.ydycwn'
    WARNING: Removing RGW daemons can cause clients to lose connectivity.
    ```

    In this example our warnings for RGW and Alertmanager would be ignored by passing the `--force` flag.  The Alert for active MGR will need to be addressed with the provided command `ceph mgr fail ncn-s003.ydycwn`

3. Re-check the OSD status, weight, and location:

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -5         20.95853      host ncn-s001
    2    ssd   3.49309          osd.2          up   1.00000  1.00000
    5    ssd   3.49309          osd.5          up   1.00000  1.00000
    6    ssd   3.49309          osd.6          up   1.00000  1.00000
    9    ssd   3.49309          osd.9          up   1.00000  1.00000
    12   ssd   3.49309          osd.12         up   1.00000  1.00000
    16   ssd   3.49309          osd.16         up   1.00000  1.00000
    -3         20.95853      host ncn-s002
    0    ssd   3.49309          osd.0          up   1.00000  1.00000
    3    ssd   3.49309          osd.3          up   1.00000  1.00000
    7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10   ssd   3.49309          osd.10         up   1.00000  1.00000
    13   ssd   3.49309          osd.13         up   1.00000  1.00000
    15   ssd   3.49309          osd.15         up   1.00000  1.00000
    -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1        down   1.00000  1.00000
    4    ssd   3.49309          osd.4        down   1.00000  1.00000
    8    ssd   3.49309          osd.8        down   1.00000  1.00000
    11   ssd   3.49309          osd.11       down   1.00000  1.00000
    14   ssd   3.49309          osd.14       down   1.00000  1.00000
    17   ssd   3.49309          osd.17       down   1.00000  1.00000
    ```

4. Check the status of the Ceph cluster:

    ```bash
    ceph -s
    ```

    Example output:

    ```text
      cluster:
        id:     4c9e9d74-a208-11ed-b008-98039bb427f6
        health: HEALTH_WARN
                1 host is in maintenance mode           <-------- Expect this line.
                1/3 mons down, quorum ncn-s001,ncn-s002
                6 osds down
                1 host (6 osds) down
                Degraded data redundancy: 34257/102773 objects degraded (33.333%), 370 pgs degraded, 352 pgs undersized

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002 (age 56s), out of quorum: ncn-s003
        mgr: ncn-s002.amfitm(active, since 43m), standbys: ncn-s001.rytusj
        mds: 1/1 daemons up, 1 hot standby
        osd: 18 osds: 12 up (since 55s), 18 in (since 13h)
        rgw: 2 daemons active (2 hosts, 1 zones)

      data:
        volumes: 1/1 healthy
        pools:   13 pools, 553 pgs
        objects: 34.26k objects, 58 GiB
        usage:   173 GiB used, 63 TiB / 63 TiB avail
        pgs:     34257/102773 objects degraded (33.333%)
                370 active+undersized+degraded
                159 active+undersized
                24  active+clean

      io:
        client:   8.7 KiB/s rd, 353 KiB/s wr, 3 op/s rd, 53 op/s wr
    ```

5. Remove Ceph OSDs.

   **IMPORTANT:** Only do this step if you are fully wiping the node.  In some cases the rebuild may not require the OSDs to be wiped.

   The `ceph osd tree` capture indicated that there are down OSDs on `ncn-s003`.

   ```bash
   ceph osd tree down
   ```

   Example output:

   ```text
   ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
   -1         62.87758  root default
   -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1        down   1.00000  1.00000
    4    ssd   3.49309          osd.4        down   1.00000  1.00000
    8    ssd   3.49309          osd.8        down   1.00000  1.00000
    11   ssd   3.49309          osd.11       down   1.00000  1.00000
    14   ssd   3.49309          osd.14       down   1.00000  1.00000
    17   ssd   3.49309          osd.17       down   1.00000  1.00000
   ```

   1. Remove the OSD references to allow the rebuild to re-use the original OSD references on the drives.
  
       By default, if the OSD reference is not removed, then there will still a reference to them in the CRUSH map.
       This will result in OSDs that no longer exist appearing to be down.

        The following command assumes the variables from [the prerequisites section](Rebuild_NCNs.md#Prerequisites) are set.

        This must be run from a `ceph-mon` node (ncn-s00[1/2/3])

        ```bash
        for osd in $(ceph osd ls-tree $NODE); do ceph osd destroy osd.$osd --force; ceph osd purge osd.$osd --force; done
        ```

        Example Output:

        ```text
        destroyed osd.1
        purged osd.1
        destroyed osd.4
        purged osd.4
        destroyed osd.6
        purged osd.6
        destroyed osd.11
        purged osd.11
        destroyed osd.14
        purged osd.14
        destroyed osd.17
        purged osd.17
        ```

## Next Step

If executing this procedure as part of an NCN rebuild, return to the main [Rebuild NCNs](Rebuild_NCNs.md#storage-node) page and proceed with the next step.
