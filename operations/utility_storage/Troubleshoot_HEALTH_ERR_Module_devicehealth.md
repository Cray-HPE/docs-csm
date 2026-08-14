# Troubleshoot `HEALTH_ERR` Module `devicehealth` has failed table Device already exists

## Symptom

In the event that a `ceph health detail` or a `ceph -s` shows the below error message,
then follow the below procedure to fix the issue:

```text
    health: HEALTH_ERR
    Module 'devicehealth' has failed
```

## Procedure

1. Stop the Ceph `mgr` services via `systemd` on `ncn-s001`, `ncn-s002`, and `ncn-s003`.

   1. Find the `systemd` unit name.

      1. On each node listed above run the following:

         ```bash
         cephadm ls|jq -r '.[]|select(.systemd_unit|contains ("mgr"))|.systemd_unit'
         ```

         Example output:

         ```text
         ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

   1. Stop the service.

      1. On each node listed above run the following:

         ```bash
         systemctl stop ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

1. Remove the Ceph pool containing the corrupt table.

   The following commands will be executed once from `ncn-s001`, `ncn-s002`, or `ncn-s003`.

   1. Set flag to allow pool deletion.

      ```bash
      ceph config set mon mon_allow_pool_delete true
      ```

   1. Delete pool

      ```bash
      ceph osd pool rm .mgr .mgr --yes-i-really-really-mean-it
      ```

      The output should contain `pool '.mgr' removed`.

   1. Unset flag to prohibit pool deletion.

      ```bash
      ceph config set mon mon_allow_pool_delete false
      ```

1. Start the Ceph `mgr` services via `systemd` on `ncn-s001`, `ncn-s002`, and `ncn-s003`.

   1. Find the `systemd` unit name.

      1. On each node listed above run the following:

         ```bash
         cephadm ls|jq -r '.[]|select(.systemd_unit|contains ("mgr"))|.systemd_unit'
         ```

         Example output:

         ```text
         ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

   1. Start the service.

      1. On each node listed above run the following:

         ```bash
         systemctl start ceph-660ccbec-a6c1-11ed-af32-b8599ff91d22@mgr.ncn-s001.xufexf
         ```

1. Verify Ceph `mgr` is operational.

   1. Verify the `.mgr` pool was automatically created.

      ```bash
      ceph osd lspools
      ```

      This will list the pools. Verify that the `.mgr` pool is present.
      This could take a minute or so to create the pool if the cluster is busy.
      If the pool is not created, verify that the `mgr` processes are running using following step.

   1. Verify all 3 `mgr` instances are running.

      ```bash
      ceph -s
      ```

      There should be 3 `mgr` processes in the output, similar to this example output:

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

   1. Additional verification steps.

        Run the following from either a master node, or on one of the following: `ncn-s001`, `ncn-s002`, or `ncn-s003`.

        1. Fetch the Ceph Prometheus endpoint.

            ```bash
            ceph mgr services
            ```

            Expected output:

            **IMPORTANT:** The below is an example output and IP addresses may vary;
            make sure that the correct endpoint is obtained from the Ceph cluster.

            ```json
            {
            "dashboard": "https://10.252.1.11:8443/",
            "prometheus": "http://10.252.1.11:9283/"
            }
            ```

        1. Use the `prometheus` endpoint to dump metrics.

            ```bash
            curl -s http://10.252.1.11:9283/metrics
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

            This is a small sample of the output.
            If the `curl` is successful, then the active manager instance is active and will
            ensure that the standby `mgr` daemons are functional and ready.
