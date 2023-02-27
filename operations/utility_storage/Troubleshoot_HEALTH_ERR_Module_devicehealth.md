# Troubleshoot `HEALTH_ERR` Module `devicehealth` has failed table Device already exists

In the event that a `ceph health detail` or a `ceph -s` shows the below command then please follow the below procedure to fix the issue.

Error Message:

```text
    health: HEALTH_ERR
    Module 'devicehealth' has failed
```

## Procedure

1. Stop the Ceph mgr services via `systemd` on `ncn-s001`, `ncn-s002`, and `ncn-s003`.
   1. Find the `systemd` unit name.
      1. On each node listed above run the following:

         ```bash
         ncn-s001:~ # cephadm ls|jq -r '.[]|select(.systemd_unit|contains ("mgr"))|.systemd_unit'
         ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

   2. Stop the service.
      1. On each node listed above run the following:

         ```bash
         ncn-s001:~ # systemctl stop ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

2. Remove the Ceph pool containing the corrupt table.
   1. The following commands will be executed once from `ncn-s001`, `ncn-s002`, or `ncn-s003`.
   2. Set flag to allow pool deletion.

      ```bash
      ncn-s001:~ # ceph config set mon mon_allow_pool_delete true
      ```

   3. Delete pool

      ```bash
      ncn-s001:~ # ceph osd pool rm .mgr .mgr --yes-i-really-really-meant-it
      ```

      The output should contain `pool '.mgr' removed`.

   4. Unset flag to prohibit pool deletion.

      ```bash
      ncn-s001:~ # ceph config set mon mon_allow_pool_delete false
      ```

3. Start the Ceph mgr services via `systemd` on `ncn-s001`, `ncn-s002`, and `ncn-s003`.
   1. Find the `systemd` unit name.
      1. On each node listed above run the following:

         ```bash
         ncn-s001:~ # cephadm ls|jq -r '.[]|select(.systemd_unit|contains ("mgr"))|.systemd_unit'
         ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

   2. Start the service.
      1. On each node listed above run the following:

         ```bash
         ncn-s001:~ # systemctl start ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

4. Verify Ceph mgr is operational.
   1. Verify the .mgr pool was automatically created.

      ```bash
      ncn-s001:~ # ceph osd lspools
      ```

      This will list the pools.  Verify that the `.mgr` pools is present.  This could take a minute or so to create the pool if the cluster is busy. If the pool is not created, please verify that the mgr processes are running using following step.

   2. Verify all 3 mgr instances are running.

      ```bash
      ncn-s001:~ # ceph -s
      ```

      There should see 3 mgr processes in the output like below:

      ```text
        cluster:
        id:     660ccbec-a6c1-11ed-af32-b8599ff91d22
        health: HEALTH_OK

        services:
          mon: 3 daemons, quorum ncn-s001,ncn-s003,ncn-s002 (age 12m)
          mgr: ncn-s001.xufexf(active, since 44s), standbys: ncn-s003.uieiom, ncn-s002.zlhlvs
          mds: 2/2 daemons up, 3 standby, 1 hot standby
          osd: 24 osds: 24 up (since 11m), 24 in (since 11m)
          rgw: 3 daemons active (3 hosts, 1 zones)
      ```

   3. Additional verification steps.
      1. Run the following from either a master node, or on one of the following: `ncn-s001`, `ncn-s002`, or `ncn-s003`.
         1. Fetch the Ceph Prometheus endpoint.

            ```bash
            ncn-s001:~ # ceph mgr services
            ```

            Expected output:

            **IMPORTANT:** The below is an example output and ip addresses may vary, so please make sure that the correct endpoint is obtained from the Ceph cluster.

            ```text
            {  
            "dashboard": "https://10.252.1.11:8443/",
            "prometheus": "http://10.252.1.11:9283/"   <--- This is the url you need.
            }
            ```

         2. Curl against the endpoint to dump metrics.

            ```bash
            ncn-s001:~ # curl -s http://10.252.1.11:9283/metrics
            ```

            Expected output:

            ```text
            # HELP ceph_health_status Cluster health status
            # TYPE ceph_health_status untyped
            ceph_health_status 0.0
            # HELP ceph_mon_quorum_status Monitors in quorum
            # TYPE ceph_mon_quorum_status gauge
            ceph_mon_quorum_status{ceph_daemon="mon.ncn-s001"} 1.0
            ceph_mon_quorum_status{ceph_daemon="mon.ncn-s003"} 1.0
            ceph_mon_quorum_status{ceph_daemon="mon.ncn-s002"} 1.0
            # HELP ceph_fs_metadata FS Metadata
            # TYPE ceph_fs_metadata untyped
            ceph_fs_metadata{data_pools="3",fs_id="1",metadata_pool="2",name="cephfs"} 1.0
            ceph_fs_metadata{data_pools="9",fs_id="2",metadata_pool="8",name="admin-tools"} 1.0
            ...
            ```

            This is a small sample of the output.  If the `curl` is successful, then the active manager instance is active and will ensure that the standby mgr daemons are functional and ready.
