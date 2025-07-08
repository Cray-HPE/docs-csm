# Keycloak Hung During Prerequisites Rollout

## Description

There is a known issue where during the upgrade to CSM 1.7 the Keycloak pods are restarted. This is done
during the `rollout-restart.sh` script in the `prerequisites.sh` script at the `RESTART_SERVICES_REFRESH_ISTIO`
stage. The Keycloak pods never complete the rollout and the entire process gets stuck waiting for them
to become ready.

## Symptoms

* One of the `cray-keycloak` pods may be in a `CrashLoopBackOff` state.
* The `cray-keycloak` pods contain the following error in the logs.

  ```text
  2025-07-08 05:13:44,350 ERROR [org.keycloak.quarkus.runtime.cli.ExecutionExceptionHandler] (main) ERROR: Failed to start server in (production) mode
  2025-07-08 05:13:44,350 ERROR [org.keycloak.quarkus.runtime.cli.ExecutionExceptionHandler] (main) ERROR: Failed to start caches
  2025-07-08 05:13:44,350 ERROR [org.keycloak.quarkus.runtime.cli.ExecutionExceptionHandler] (main) For more details run the same command passing the '--verbose' option. Also you can use '--help' to see the details about the usage of the particular command.
  ```

## Solution

1. (`ncn-mw#`) Force delete the Keycloak pods

   Command:

   ```bash
   kubectl -n services delete pod -n services cray-keycloak-0 cray-keycloak-1 cray-keycloak-2 --force
   ```

   Example output:

   ```text
   Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
   pod "cray-keycloak-0" force deleted
   pod "cray-keycloak-1" force deleted
   pod "cray-keycloak-2" force deleted
   ```
