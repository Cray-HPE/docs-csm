# Troubleshoot a Down OSD

Identify down OSDs and manually bring them back up.

Troubleshoot the Ceph health detail reporting down OSDs. Ensuring that OSDs are operational and data is balanced across them will help remove the likelihood of hotspots being created.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. (`ncn-m#|ncn-s00[1-3]`) Identify the down OSDs.

    ```bash
    ceph osd tree down
    ```

    Example output:

    ```text
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

     1. (`ncn-m#|ncn-s00[1-3]`) Restart the OSD utilizing `ceph orch`

        ```bash
        ceph orch daemon restart osd.<number>
        ```

   * **Option 2:**

     1. (`ncn-m#|ncn-s00[1-3]`) Check the logs for the OSD that is down.

        Use the OSD number for the down OSD returned in the earlier command.

        ```bash
        ceph osd find OSD_ID
        ```

     1. (`ncn-s#`) Manually restart the OSD.

        This step **must be done on the node with the reported down OSD.**

         ```bash
         ceph orch daemon restart osd.<number>
         ```

    **Troubleshooting:** If the service is not restarted with `ceph orch`, restart it using [Manage Ceph Services](Manage_Ceph_Services.md).

1. (`ncn-m#|ncn-s00[1-3]`) Verify the OSDs are running again.

    ```bash
    ceph osd tree down
    ```

    Example output:

    ```text
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

If the OSD dies again, check `dmesg` for drive failures.
