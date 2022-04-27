# Validate Health

## Description

Validate that the system is healthy.

## Procedure

The following procedures can be run from any master or worker node.

1. Collect data about the system management platform health.

   ```bash
   ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
   ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```

   **NOTE:**
   If workers have been removed and the worker count is currently at two, the following failures can be ignored. A re-check will be needed once workers are added and the count returns to three or above.
   - the `ncnPostgresHealthChecks` may report `Unable to determine a leader` and one of the three Postgres pods may be in `Pending` state.
   - the `ncnHealthChecks` may report `Error from server...FAILED - Pod Not Healthy`, `FAILED DATABASE CHECK` and one of the three Etcd pods may be in `Pending` state.

1. Restart the Goss server on all the NCNs. Adjust the commands based on the number of master, worker, and storage nodes.

   ```bash
   ncn-mw# pdsh -w ncn-m00[1-3],ncn-w00[1-3],ncn-s00[1-3] systemctl restart goss-servers
   ```

1. Collect data about the various subsystems.

   ```bash
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-master
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-storage
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks
   ```

   **NOTE:**
   The following errors can be ignored if `<NODE>` has been removed and it is one of the first three worker, master, or storage nodes:
   `Server URL: http://<NODE> ... ERROR: Server endpoint could not be reached`

   **NOTE:**
   If workers have been removed and the worker count is currently at two, failures of the following tests can be ignored. A re-check will be needed once workers are added and the count returns to three or above.
   - `Verify cray etcd is healthy`

The procedure is complete. [Return to Main Page](../Add_Remove_Replace_NCNs.md).
