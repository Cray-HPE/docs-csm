# Spire Server Pods stuck in Pod Initializing

## Description

There is a known issue when the Spire servers are started and Spire Postgres is not ready, where the pod will get stuck in a `PodInitializing` state and not be able to be restarted.

Starting the Spire server when its Postgres cluster is not ready leads to the pod crashing. However due to how the Spire servers are registered when the main process crashes
there is a loop that never gets killed in a side process. That leads to the pod crashing but never getting cleaned up to be restarted. There is no way to manually restart that pod
without restarting `Containerd` to forcefully clean up the running container.

## Symptoms

* The `spire-server` or `cray-spire-server` pods may be in a `PodInitializing` state.
* The `spire-agent` or `cray-spire-agent` pods may be in a `Init:CrashLoopBackOff` state.
* Services may fail to acquire tokens from the `spire-server` or `cray-spire-server`.
* The `spire-server` or `cray-spire-server` pods contain the following error in the logs.

  ```text
  time="2024-10-25T10:13:50Z" level=info msg="Opening SQL database" db_type=postgres subsystem_name=built-in_plugin.sql
  time="2024-10-25T10:13:50Z" level=error msg="Fatal run error" error="datastore-sql: dial tcp: lookup spire-postgres-pooler.spire.svc.cluster.local: no such host"
  time="2024-10-25T10:13:50Z" level=error msg="Server crashed" error="datastore-sql: dial tcp: lookup spire-postgres-pooler.spire.svc.cluster.local: no such host"
  ```

## Solution

### Apply workaround

1. Find the node that the first Spire server is attempting to start on.

   ```bash
   kubectl get pods -n spire -o wide | grep spire-server-0
   ```

   Output example:

   ```text
   spire-server-0                                0/2     PodInitializing         0                5h32m   10.34.0.129   ncn-w004   <none>           <none>
   ```

1. Verify that Postgres is running.

   ```bash
   kubectl get pods -n spire | grep spire-postgres
   ```

1. Delete the pod.

   ```bash
   kubectl delete pod -n spire spire-server-0
   ```

1. SSH to the node it was running on and restart `Containerd`.

   ```bash
   ssh ncn-w004 systemctl restart containerd
   ```

1. Check that the spire-server started up.

   ```bash
   kubectl get pods -n spire
   ```
