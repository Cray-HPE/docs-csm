# Troubleshooting guide for IUF management-nodes-rollout to worker nodes hangs on final worker node with DVS related errors

## Description

During upgrades from CSM 1.6.x to 1.7.0, the IUF `management-nodes-rollout` that targets worker nodes can hang on the final worker node because of DVS related errors.
The rollout may appear stalled even though most worker nodes have successfully received the new image. IUF logs may repeatedly show errors with DVS modules, as below:

```text
INFO Running before each hook: cos-prechecks-for-worker-reboots
dvs module is not loaded on x3000c0s8b0n0
dvs module is not loaded on x3000c0s9b0n0
dvs module is not loaded on x3000c0s10b0n0
ERROR: HA requires at least 1 running DVS server, but there are none
Pods not running.
```

Pods related to DVS may be in an `Error` or `NotReady` state, and Argo workflows such as `ncn-lifecycle-rebuild` may be in a loop or failing.

## Symptoms

- IUF stops at the last worker node and reports DVS health-check failures.
- IUF logs reference missing DVS modules or failed health checks.
- IUF hook object `cos-prechecks-for-worker-reboots` is mentioned in logs.
- DVS pods may show `NotReady` or `Error` status (this can be checked by running `kubectl get pods -A | grep dvs`).

## Impact

- IUF `management-nodes-rollout` stage for worker nodes may not complete.
- Automated rebuild workflows (`ncn-lifecycle-rebuild`) can become stuck and require manual intervention.

## Root cause

An IUF hook (`cos-prechecks-for-worker-reboots`) was removed from the `docs-csm` CSM 1.7.0 RPM.
However, the corresponding Kubernetes IUF hook object created by the 1.6.x rpm can remain in the cluster.
The upgrade workflow template `before-each-hooks` lists and executes hook objects in the `argo` namespace:

```bash
kubectl get hooks -n argo -l before-each=true
```

When the obsolete IUF hook object is executed, the DVS NCN health check can fail and block the worker rebuild,
causing IUF to hang on the last worker node.

## Workaround

If this issue is encountered during the upgrade, then perform the following steps to recover and proceed.

1. Find and delete the `cos-prechecks-for-worker-reboots` IUF hook.

   For details on how to manually check and remove the `cos-prechecks-for-worker-reboots` IUF hook from the cluster, see
   [Note: When upgrading from CSM 1.6 to CSM 1.7.0 only](../../operations/iuf/workflows/management_rollout.md#note-when-upgrading-from-csm-16-to-csm-170-only)
   under [Management Rollout for NCN worker nodes](../../operations/iuf/workflows/management_rollout.md#23-ncn-worker-nodes).

1. (`ncn-mw#`) If Argo shows a stuck workflow (e.g., `upgrade-recipe-25-9-0-management-nodes-rollout`), then remove it.

   ```bash
   kubectl -n argo get wf
   kubectl -n argo delete wf upgrade-recipe-25-9-0-management-nodes-rollout
   ```

   Or delete it using the Argo UI.

   *Note:* After deleting the hook, the workflow may attempt to run the hook and report `NotFound`.
   If the IUF process is unresponsive, interrupt with **Control-C** and force exit.

1. (`ncn-mw#`) Label worker nodes that have already received the image so subsequent IUF runs skip them.

   ```bash
   kubectl label node <node-name> iuf-prevent-rollout=true --overwrite
   ```

   Example:

   ```bash
   kubectl label nodes ncn-w002 ncn-w003 --overwrite iuf-prevent-rollout=true
   kubectl get nodes --show-labels | grep iuf-prevent-rollout
   ```

1. (`ncn-mw#`) Restart the IUF operation for the remaining worker nodes.

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout <worker>
   ```
