## Troubleshoot a Down OSD

Identify down OSDs and manually bring them back up.

Troubleshoot the Ceph health detail reporting down OSDs. Ensuring that OSDs are operational and data is balanced across them will help remove the likelihood of hotspots being created.

### Prerequisites

This procedure requires admin privileges.

### Procedure

1.  Identify the down OSDs.

    ```bash
    ncn-m001# ceph osd tree
    ```

2.  Check the logs for the OSD that is down.

    Use the OSD number for the down OSD returned in the command above.

    ```bash
    ncn-m001# ceph osd find OSD_ID
    ```

3.  Manually restart the OSD.

    This step must be done on the node with the reported down OSD.

    ```bash
    ncn-m001# systemctl restart ceph-osd@OSD_NUMBER
    ```

4.  Verify the OSDs are running again.

    ```bash
    ncn-m001# ceph osd tree
    ID CLASS WEIGHT  TYPE NAME       STATUS REWEIGHT PRI-AFF
    -1       0.08212 root default
    -5       0.02737     host ceph-1
     1  kube 0.00879         osd.1       up  1.00000 1.00000 
     4   smf 0.01859         osd.4       up  1.00000 1.00000
    -3       0.02737     host ceph-2
     0  kube 0.00879         osd.0       up  1.00000 1.00000
     3   smf 0.01859         osd.3       up  1.00000 1.00000
    -7       0.02737     host ceph-3
     2  kube 0.00879         osd.2       up  1.00000 1.00000
     5   smf 0.01859         osd.5       up  1.00000 1.00000
    ```


If the OSD dies again, check dmesg for drive failures.


