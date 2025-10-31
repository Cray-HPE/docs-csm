# Troubleshooting guide for IUF management-nodes-rollout to worker nodes hangs on last worker node DVS errors

## Description

During upgrades from CSM 1.6.x to 1.7.0, the IUF management-nodes-rollout that targets worker nodes can hang on the final worker node due to `DVS-related` errors.
The rollout may appear stalled even though most worker nodes have successfully received the new image. IUF logs may repeatedly show errors with DVS modules, as below:

```console
INFO Running before each hook: cos-prechecks-for-worker-reboots
dvs module is not loaded on x3000c0s8b0n0
dvs module is not loaded on x3000c0s9b0n0
dvs module is not loaded on x3000c0s10b0n0
ERROR: HA requires at least 1 running DVS server, but there are none
Pods not running.
```

Pods related to DVS may be in an error or `NotReady` state, and Argo Workflows such as `ncn-lifecycle-rebuild` may be in a loop or failing.

## Impact

- IUF management-nodes-rollout stage for worker nodes may not complete.
- Automated rebuild workflows (`ncn-lifecycle-rebuild`) can become stuck and require manual intervention.

## Symptoms

- IUF stops at the last worker node and reports DVS health-check failures.
- IUF Logs reference missing DVS modules or failed health checks.
- IUF hook object `cos-prechecks-for-worker-reboots` is mentioned in logs.
- DVS pods may show `NotReady` or Error, e.g. with `kubectl get pods -A | grep dvs`.

## Root Cause

An IUF hook (`cos-prechecks-for-worker-reboots`) was removed from the `docs-csm` CSM 1.7.0 rpm. However, the corresponding Kubernetes IUF hook object created by the 1.6.x rpm can remain in the cluster.
The upgrade workflow template `before-each-hooks` lists and executes hook objects in the `argo` namespace:

```bash
kubectl get hooks -n argo -l before-each=true
```

When the leftover IUF hook object is executed but its script is no longer present on nodes, the DVS NCN health check can fail and block the worker rebuild, causing IUF to hang on the last worker node.

## Pre-check Resolution (Recommended)

**Before starting the upgrade:**

- Check for and remove the `cos-prechecks-for-worker-reboots` Argo hook object from the cluster as a pre-check step:

  Verify the cos-prechecks-for-worker-reboots hook exists:

  ```bash
  kubectl -n argo get hooks -l app.kubernetes.io/name=cos-prechecks-for-worker-reboots
  ```

  Delete the hook:

  ```bash
  kubectl -n argo delete hook cos-prechecks-for-worker-reboots --ignore-not-found=true
  ```

**Example session:**

```console
root@ncn-m001# kubectl -n argo get hooks
NAME                               AGE
cos-prechecks-for-worker-reboots   197d
...
root@ncn-m001# kubectl -n argo delete hook cos-prechecks-for-worker-reboots --ignore-not-found=true
hook.cray-nls.hpe.com "cos-prechecks-for-worker-reboots" deleted
```

## Workaround

If you encounter the issue during the upgrade, perform the following steps to recover and proceed:

1. **Find and delete the `cos-prechecks-for-worker-reboots` IUF hook:**  
   See commands above.

2. **If Argo shows a stuck workflow (e.g., `upgrade-recipe-25-9-0-management-nodes-rollout`), remove it:**

   ```bash
   kubectl -n argo get wf
   kubectl -n argo delete wf upgrade-recipe-25-9-0-management-nodes-rollout
   ```

   Or delete via the Argo UI.

   *Note:* After deleting the hook, the workflow may attempt to run the hook and report `NotFound`. If the IUF process is unresponsive, interrupt with Ctrl-C and force exit.

3. **Mark worker nodes that already received the image so subsequent IUF runs skip them:**

   ```bash
   kubectl label node <node-name> iuf-prevent-rollout=true --overwrite
   ```

   Example:

   ```bash
   kubectl label nodes ncn-w002 ncn-w003 --overwrite iuf-prevent-rollout=true
   kubectl get nodes --show-labels | grep iuf-prevent-rollout
   ```

4. **Restart the IUF operation for the remaining worker nodes:**

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout <label-or-list>
   ```

## Resolution

- Remove the `cos-prechecks-for-worker-reboots` IUF hook object from clusters as a pre-upgrade check before upgrading to CSM 1.7.0.
