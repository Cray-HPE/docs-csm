# Troubleshoot a Down OSD

Identify down OSDs and manually bring them back up.

Troubleshoot the Ceph health detail reporting down OSDs. Ensuring that OSDs are operational and data is balanced across them will help remove the likelihood of hotspots being created.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. Identify the down OSDs.

    ```bash
    ncn-m/s(001/2/3)# ceph osd tree down
    ```

    Example output:

    ```
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -7         20.95853      host ncn-s002
     1    ssd   3.49309          osd.1        down   1.00000  1.00000
     3    ssd   3.49309          osd.3        down   1.00000  1.00000
     7    ssd   3.49309          osd.7        down   1.00000  1.00000
    10    ssd   3.49309          osd.10       down   1.00000  1.00000
    13    ssd   3.49309          osd.13       down   1.00000  1.00000
    16    ssd   3.49309          osd.16       down   1.00000  1.00000
    ```

1. Restart the down OSDs.

   * **Option 1:**

     1. Restart the OSD utilizing `ceph orch`

        ```bash
        ncn-m/s00(1/2/3)# ceph orch daemon restart osd.<number>
        ```

   * **Option 2:**

     1. Check the logs for the OSD that is down.

        Use the OSD number for the down OSD returned in the command above.

        ```bash
        ncn-m/s(001/2/3)# ceph osd find OSD_ID
        ```

     2. Manually restart the OSD.

        This step **must be done on the node with the reported down OSD.**

         ```bash
         ncn-s# ceph orch daemon restart osd.<number>
         ```

    **Troubleshooting:** If the service is not restarted with `ceph orch`, restart it using [Manage Ceph Services](Manage_Ceph_Services.md).

2. Verify the OSDs are running again.

    ```bash
    # ceph osd tree down
    ```

    Example output:

    ```
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -7         20.95853      host ncn-s002
     1    ssd   3.49309          osd.1          up   1.00000  1.00000
     3    ssd   3.49309          osd.3          up   1.00000  1.00000
     7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10    ssd   3.49309          osd.10         up   1.00000  1.00000
    13    ssd   3.49309          osd.13         up   1.00000  1.00000
    16    ssd   3.49309          osd.16         up   1.00000  1.00000
    ```

If the OSD dies again, check dmesg for drive failures.

