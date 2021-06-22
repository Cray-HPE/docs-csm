# Troubleshoot an Unresponsive S3 Endpoint

Restart Ceph OSDs to help make the rgw.local:8080 endpoint responsive.

Ceph has an issue where it appears healthy but the rgw.local:8080 endpoint is unresponsive. This issue occurs when `ceph -s` is run and produces a very high reads per second output:

```bash
io:
    client:   103 TiB/s rd, 725 KiB/s wr, 2 op/s rd, 44 op/s wr
```

The rgw.local endpoint needs to be responsive in order to interact directly with the Simple Storage Service \(S3\) RESTful API.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. View the OSD status.

    ```bash
    ncn-m001# ceph osd tree
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95312 root default
    -7        6.98438     host ncn-s001
     0   ssd  3.49219         osd.0         up  1.00000 1.00000
     3   ssd  3.49219         osd.3         up  1.00000 1.00000
    -3        6.98438     host ncn-s002
     2   ssd  3.49219         osd.2         up  1.00000 1.00000
     5   ssd  3.49219         osd.5         up  1.00000 1.00000
    -5        6.98438     host ncn-s003
     1   ssd  3.49219         osd.1         up  1.00000 1.00000
     4   ssd  3.49219         osd.4         up  1.00000 1.00000
    
    ```

1. Log in to each node and restart the OSDs.

    The OSD number in the example below should be replaced with the number of the OSD being restarted.

    ```bash
    ncn-m001# ceph orch restart osd.3
    ```

    Wait for Ceph health to return to OK before moving between nodes.
