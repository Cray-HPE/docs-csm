# Troubleshooting Unused Drives on Storage Nodes

> NOTE: This page is only applicable to storage NCNs on Gigabyte or HPE hardware.

Utility storage nodes (also known as storage NCNs) are expected to have a particular number of OSDs based on the type of NCN hardware. This page
describes how to validate that the storage NCNs have the expected number of OSDs, and provides remediation steps if this is not the case.

(`ncn-s#`) Perform all procedures on this page on any of the first three storage NCNs (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

## Topics

- [Expected number of OSDs](#expected-number-of-osds)
- [Automatic check](#automatic-check)
- [Manual checks and remediation](#manual-checks-and-remediation)
  - [Option 1](#option-1)
  - [Option 2](#option-2)
  - [Wipe and add drives](#wipe-and-add-drives)
- [Additional information](#additional-information)

## Expected number of OSDs

The following table shows the expected number of OSDs for every storage NCN.

| Hardware Manufacturer | OSD Drive Count per Storage NCN (not including OS drives) |
| :-------------------: | :---------------------------------------: |
| GigaByte              | 12 |
| HPE                   | 8  |

The expected total number of OSDs on the system is determined by taking the number in the second column of the above
table and multiplying it by the number of storage NCNs in the system. That is:

`total_osds` = `(Number of utility storage nodes)` `*` `(OSD drive count per storage NCN)`

## Automatic check

1. Record the hardware type of the storage NCNs.

    ```bash
    HWTYPE=$(ipmitool mc info | grep "^Manufacturer Name" | sed 's/^Manufacturer Name[[:space:]][[:space:]]*:[[:space:]][[:space:]]*//')
    echo "${HWTYPE}"
    ```

    Example output on a system with HPE hardware:

    ```text
    Hewlett Packard Enterprise
    ```

1. Record the number of storage NCNs on the system.

    Be sure to set the `NUM_STORAGE_NCNS` variable to the actual number of storage NCNs on the system.

    ```bash
    NUM_STORAGE_NCNS=x
    ```

1. Execute the automatic check.

    ```bash
    /opt/cray/tests/install/ncn/scripts/python/check_for_unused_drives.py "${NUM_STORAGE_NCNS}" "${HWTYPE}"
    ```

    The final line of output will report whether or not the number of OSDs found matches what is expected.

    Example of successful output on system with five HPE storage nodes:

    ```text
    2022-09-20 16:00:44.651 DEBUG    Parsing command line arguments: ['/opt/cray/tests/install/ncn/scripts/python/check_for_unused_drives.py', '5', 'Hewlett Packard Enterprise']
    2022-09-20 16:00:44.652 INFO     Based on hardware type (hpe) and number of storage nodes (5): min_expected_osds = 40, max_expected_osds = 40
    2022-09-20 16:00:44.652 DEBUG    Loading Ceph
    2022-09-20 16:00:44.657 DEBUG    Connecting to Ceph
    2022-09-20 16:00:44.664 INFO     Running ceph osd stat command
    2022-09-20 16:00:44.671 INFO     Command return code = 0
    2022-09-20 16:00:44.671 DEBUG    Decoding command output to string:
    {
        "epoch": 2634,
        "num_osds": 40,
        "num_up_osds": 40,
        "osd_up_since": 1663023364,
        "num_in_osds": 40,
        "osd_in_since": 1659470908,
        "num_remapped_pgs": 0
    }
    
    2022-09-20 16:00:44.671 DEBUG    Decoding command output from JSON into object
    2022-09-20 16:00:44.671 DEBUG    Extracting number of OSDs from object
    2022-09-20 16:00:44.671 INFO     num_osds = 40
    2022-09-20 16:00:44.671 INFO     SUCCESS -- number of OSDs found matches expectations based on hardware type
    ```

If the number of OSDs does not match what is expected, then proceed to [Manual checks and remediation](#manual-checks-and-remediation).

## Manual checks and remediation

If there are OSDs on each node (`ceph osd tree` can show this), then all the nodes are in Ceph. That means the orchestrator can be used to look for the devices. In that case, begin
by following [Option 1](#option-1). Otherwise, proceed to [Option 2](#option-2).

### Option 1

1. Get the number of OSDs in the cluster.

    ```bash
    ceph -f json-pretty osd stat |jq .num_osds
    ```

    Example output:

    ```text
    24
    ```

    **IMPORTANT:** If the returned number of OSDs is equal to the [Expected number of OSDs](#expected-number-of-osds) calculated earlier, then skip the following steps.
    If not, then proceed with the below additional checks and remediation steps.

1. Compare the number of OSDs to what is listed by Ceph.

    > **NOTE:** If the Ceph cluster is large and has a lot of nodes, then a node may be specified after the below command to limit the results.

    ```bash
    ceph orch device ls
    ```

    Example output:

    ```text
    Hostname  Path      Type  Serial              Size   Health   Ident  Fault  Available
    ncn-s001  /dev/sda  ssd   PHYF015500M71P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdb  ssd   PHYF016500TZ1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdc  ssd   PHYF016402EB1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdd  ssd   PHYF016504831P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sde  ssd   PHYF016500TV1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdf  ssd   PHYF016501131P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdi  ssd   PHYF016500YB1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdj  ssd   PHYF016500WN1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sda  ssd   PHYF0155006W1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdb  ssd   PHYF0155006Z1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdc  ssd   PHYF015500L61P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdd  ssd   PHYF015502631P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sde  ssd   PHYF0153000G1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdf  ssd   PHYF016401T41P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdi  ssd   PHYF016504C21P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdj  ssd   PHYF015500GQ1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sda  ssd   PHYF016402FP1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdb  ssd   PHYF016401TE1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdc  ssd   PHYF015500N51P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdd  ssd   PHYF0165010Z1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sde  ssd   PHYF016500YR1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdf  ssd   PHYF016500X01P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdi  ssd   PHYF0165011H1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdj  ssd   PHYF016500TQ1P9DGN  1920G  Unknown  N/A    N/A    No
    ```

    If there are devices that show `Available` as `Yes` and they are not being automatically added, then those devices may need to be zapped.

    **IMPORTANT:** Prior to zapping any device, ensure that it is not being used.

1. Check to see if the number of devices is less than the number of listed drives in the output from step 1.

    ```bash
    ceph orch device ls|grep dev|wc -l
    ```

    Example output:

    ```text
    24
    ```

    If the numbers are equal, but less than the `total_osds` calculated, then the `ceph-mgr` daemon may need to be failed in order to get a fresh inventory.

    1. Fail the `ceph-mgr` daemon.

        ```bash
        ceph mgr fail $(ceph mgr dump | jq -r .active_name)
        ```

    1. Wait five minutes and then re-check `ceph orch device ls`.

        See if the drives are still showing as `Available`. If so, then proceed to the next step.

1. Compare `lsblk` output on each storage node against the device list from `ceph orch device ls`.

    ```bash
    lsblk
    ```

    Example output:

    ```text
    NAME                                                                                                 MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
    loop0                                                                                                   7:0    0   4.2G  1 loop  / run/    rootfsbase
    loop1                                                                                                  7:1    0    30G  0 loop
     └─live-overlay-pool                                                                                  254:8    0   300G  0 dm
    loop2                                                                                                  7:2    0   300G  0 loop
     └─live-overlay-pool                                                                                  254:8    0   300G  0 dm
    sda                                                                                                    8:0    0   1.8T  0 disk
     └─ceph--0a476f53--8b38--450d--8779--4e587402f8a8-osd--data--b620b7ef--184a--46d7--9a99--771239e7a323 254:7    0   1.8T  0 lvm
    ```

    If a device has an LVM volume like above, then it may be in use. In that case, perform the [Option 2](#option-2) check below to make sure that the drive can be wiped.
    Otherwise, proceed to the [Wipe and add drives](#wipe-and-add-drives) procedure.

### Option 2

Log into **each** storage NCN and check for unused drives. There are two ways to do this:

- List all drives on the node.

    ```bash
    cephadm shell -- ceph-volume inventory
    ```

    > Note: The following warning message from the `cephadm` command should be ignored if it is seen: `WARNING: The same type, major and minor should not be used for multiple devices.`

    In the output of the command, the `available` field will be `True` if Ceph sees the drive as empty (and therefore available for use). For example:

    ```text
    Device Path               Size         rotates available Model name
    /dev/sda                  447.13 GB    False   False     SAMSUNG MZ7LH480
    /dev/sdb                  447.13 GB    False   False     SAMSUNG MZ7LH480
    /dev/sdc                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdd                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sde                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdf                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdg                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdh                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    ```

- List only the paths of available drives on the node.

    ```bash
    cephadm shell -- ceph-volume inventory --format json-pretty | jq -r '.[]|select(.available==true)|.path'
    ```

    > Note: The following warning message from the `cephadm` command should be ignored if it is seen: `WARNING: The same type, major and minor should not be used for multiple devices.`

### Wipe and add drives

1. Wipe a drive **ONLY after confirming that the drive is not being used by the current Ceph cluster** by using the above procedures.

    The following example wipes drive `/dev/sdc` on `ncn-s002`. Replace these values with the appropriate ones for the situation.

    ```bash
    ceph orch device zap ncn-s002 /dev/sdc --force
    ```

1. Add unused drives.

    Run this command on the storage NCN containing the drive that was zapped. Be sure to modify the following command to
    specify the actual name of the zapped drive.

    ```bash
    cephadm shell -- ceph-volume lvm create --data /dev/sd<drive to add> --bluestore
    ```

## Additional Information

More information can be found at [the `cephadm` reference page](../operations/utility_storage/Cephadm_Reference_Material.md).
