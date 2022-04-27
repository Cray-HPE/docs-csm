# Troubleshoot Failure to Get Ceph Health

Inspect Ceph commands that are failing by looking into the Ceph monitor logs \(ceph-mon\). For example, the monitoring logs can help determine any issues causing the `ceph -s` command to hang.

Troubleshoot Ceph commands failing to run and determine how to make them operational again. These commands need to be operational to obtain critical information about the Ceph cluster on the system.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. Verify the node being used is running ceph-mon.

1. Verify ceph-mon processes are running on the first three NCN storage nodes.

   - See [Manage_Ceph_Service](Manage_Ceph_Services.md) for more information.

    If more than three storage nodes exist, check the output of `ceph orch ps` for more information.

1. Check ceph-mon logs to see if the cluster is out of quorum.

    Verify the issue is resolved by rerunning the Ceph command that failed.

