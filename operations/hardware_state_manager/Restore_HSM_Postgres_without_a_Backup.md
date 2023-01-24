# Restore Hardware State Manager (HSM) Postgres without an Existing Backup

This procedure is intended to repopulate HSM in the event when no Postgres backup exists.

## Prerequisite

- Healthy System Layout Service (SLS). Recovered first if also affected.

- Healthy HSM service.

  Verify all 3 HSM Postgres replicas are up and running:

  ```bash
  kubectl -n services get pods -l cluster-name=cray-smd-postgres
  ```

  Example output:

  ```text
  NAME                  READY   STATUS    RESTARTS   AGE
  cray-smd-postgres-0   3/3     Running   0          18d
  cray-smd-postgres-1   3/3     Running   0          18d
  cray-smd-postgres-2   3/3     Running   0          18d
  ```

## Procedure

1. Re-run the HSM loader job.

    ```bash
    kubectl -n services get job cray-smd-init -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
    ```

    Wait for the job to complete:

    ```bash
    kubectl wait -n services job cray-smd-init --for=condition=complete --timeout=5m
    ```

2. Verify that the service is functional.

    ```bash
    cray hsm service ready list
    ```

    Example output:

    ```text
    code = 0
    message = "HSM is healthy"
    ```

3. Get the number of node objects stored in HSM.

    ```bash
    cray hsm state components list --type Node --format json | jq .Components[].ID | wc -l
    ```

4. Restart MEDS and REDS.

    To repopulate HSM with components, restart MEDS and REDS so that they will add known `RedfishEndpoints` back in to HSM. This will also kick off HSM rediscovery to repopulate components and hardware inventory.

    ```bash
    kubectl scale deployment cray-meds -n services --replicas=0
    kubectl scale deployment cray-meds -n services --replicas=1
    kubectl scale deployment cray-reds -n services --replicas=0
    kubectl scale deployment cray-reds -n services --replicas=1
    ```

    Wait for the RedfishEndpoints table to get repopulated and discovery to complete.

    ```bash
    cray hsm inventory redfishEndpoints list --format json | jq .RedfishEndpoints[].ID | wc -l
    100
    cray hsm inventory redfishEndpoints list --format json | grep -c "DiscoveryStarted"
    0
    ```

5. Check for Discovery Errors.

    ```bash
    cray hsm inventory redfishEndpoints list --format json | grep LastDiscoveryStatus | grep -v -c "DiscoverOK"
    ```

    If any of the RedfishEndpoint entries have a `LastDiscoveryStatus` other than `DiscoverOK` after discovery has completed, refer
    to the [Troubleshoot Issues with Redfish Endpoint Discovery](../node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md) procedure for guidance.

6. Re-apply any component group or partition customizations.

    Any component groups or partitions created before HSM's Postgres information was lost will need to be manually re-entered.

    - [Manage Component Groups](Manage_Component_Groups.md)
    - [Manage Component Partitions](Manage_Component_Partitions.md)
