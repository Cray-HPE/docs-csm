# Adjust Ceph Pool Quotas

Ceph pools are used for storing data. Use this procedure to set the Ceph pool quotas to determine the wanted number of bytes per pool. The `smf` Ceph pool now has replication factor of two.

Resolve Ceph health issues caused by a pool reaching its quota.

## Prerequisites

This procedure requires administrative privileges.

## Limitations

Currently, only `smf` includes a quota.

## Procedure

1. Log in as root on `ncn-m001`.

1. Determine the available space.

    In the following example, the 3.5 TiB is 33 percent of the 21 TiB total. Ceph keeps three copies of data, so a 3.5 TiB quota is actually provisioning 7.0 TiB of storage, which is 33 percent of 21 TiB.

    ```bash
    ceph df detail
    ```

    Example output:

    ```
    RAW STORAGE:
      CLASS     SIZE       AVAIL      USED        RAW USED     %RAW USED
      ssd       21 TiB     21 TiB     122 GiB      134 GiB          0.62
      TOTAL     **21 TiB**     21 TiB     122 GiB      134 GiB          0.62

    POOLS:
      POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL     QUOTA OBJECTS     QUOTA BYTES     DIRTY       USED COMPR     UNDER COMPR
      cephfs_data                     1     1.0 MiB          74     6.2 MiB         0       6.6 TiB     N/A               N/A                  74            0 B             0 B
      cephfs_metadata                 2      22 MiB          28      68 MiB         0       6.6 TiB     N/A               N/A                  28            0 B             0 B
      .rgw.root                       3     3.5 KiB           8     384 KiB         0       6.6 TiB     N/A               N/A                   8            0 B             0 B
      default.rgw.buckets.data        4      22 GiB      22.57k      65 GiB      0.32       6.6 TiB     N/A               N/A              22.57k            0 B             0 B
      default.rgw.control             5         0 B           8         0 B         0       6.6 TiB     N/A               N/A                   8            0 B             0 B
      default.rgw.buckets.index       6     197 KiB          13     197 KiB         0       6.6 TiB     N/A               N/A                  13            0 B             0 B
      default.rgw.meta                7      19 KiB         107     4.2 MiB         0       6.6 TiB     N/A               N/A                 107            0 B             0 B
      default.rgw.log                 8         0 B         207         0 B         0       6.6 TiB     N/A               N/A                 207            0 B             0 B
      kube                            9      15 GiB       6.48k      28 GiB      0.14       6.6 TiB     N/A               N/A               6.48k         17 GiB          33 GiB
      smf                            10      19 TiB       7.88k      28 GiB      0.14       9.9 TiB     N/A               **3.5 TiB**           7.88k        9.4 GiB          19 GiB
      default.rgw.buckets.non-ec     11         0 B           0         0 B         0       9.9 TiB     N/A               N/A                   0            0 B             0 B
    ```

1. Determine the maximum quota percentage.

    6TiB must be left for Kubernetes, Ceph RGW, and other services. To calculate the quota percentage, use the following equation:

    ```bash
    (TOTAL_SIZE-6)/TOTAL_SIZE
    ```

    Using the example output in step 2, the following would be the quota percentage:

    ```bash
    (21-6)/21 = .71
    ```

1. Edit the quota percentage as wanted.

    Do not exceed the percentage determined in the previous step.

    ```bash
    vim /etc/ansible/ceph-rgw-users/roles/ceph-pool-quotas/defaults/main.yml
    ```

    Example ceph-pool-quotas.yml:

    ```
    ceph_pool_quotas:
      - pool_name: smf
        percent_of_total: .71 <-- Change this to desired percentage
        replication_factor: 2.0
    ```

1. Run the ceph-pool-quotas.yml playbook from `ncn-s001`.

    ```bash
    /etc/ansible/boto3_ansible/bin/ansible-playbook /etc/ansible/ceph-rgw-users/ceph-pool-quotas.yml
    ```

1. View the quota/pool usage.

    Look at the USED and QUOTA BYTES columns to view usage and the new quota setting.

    ```bash
    ceph df detail
    ```

    Example output:

    ```
    RAW STORAGE:
      CLASS     SIZE       AVAIL      USED        RAW USED     %RAW USED
      ssd       21 TiB     21 TiB     122 GiB      134 GiB          0.62
      TOTAL     **21 TiB**     21 TiB     122 GiB      134 GiB          0.62

    POOLS:
      POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL     QUOTA OBJECTS     QUOTA BYTES     DIRTY       USED COMPR     UNDER COMPR
      cephfs_data                     1     1.0 MiB          74     6.2 MiB         0       6.6 TiB     N/A               N/A                  74            0 B             0 B
      cephfs_metadata                 2      22 MiB          28      68 MiB         0       6.6 TiB     N/A               N/A                  28            0 B             0 B
      .rgw.root                       3     3.5 KiB           8     384 KiB         0       6.6 TiB     N/A               N/A                   8            0 B             0 B
      default.rgw.buckets.data        4      22 GiB      22.57k      65 GiB      0.32       6.6 TiB     N/A               N/A              22.57k            0 B             0 B
      default.rgw.control             5         0 B           8         0 B         0       6.6 TiB     N/A               N/A                   8            0 B             0 B
      default.rgw.buckets.index       6     197 KiB          13     197 KiB         0       6.6 TiB     N/A               N/A                  13            0 B             0 B
      default.rgw.meta                7      19 KiB         107     4.2 MiB         0       6.6 TiB     N/A               N/A                 107            0 B             0 B
      default.rgw.log                 8         0 B         207         0 B         0       6.6 TiB     N/A               N/A                 207            0 B             0 B
      kube                            9      15 GiB       6.48k      28 GiB      0.14       6.6 TiB     N/A               N/A               6.48k         17 GiB          33 GiB
      smf                            10      19 TiB       7.88k      28 GiB      0.14       9.9 TiB     N/A               **7.4 TiB**           7.88k        9.4 GiB          19 GiB
      default.rgw.buckets.non-ec     11         0 B           0         0 B         0       9.9 TiB     N/A               N/A                   0            0 B             0 B
    ```

