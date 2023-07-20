# Management Node Personalization

- [Introduction](#introduction)
- [Re-run node personalization on management nodes](#re-run-node-personalization-on-management-nodes)
- [Re-run node personalization on a specific management node](#re-run-node-personalization-on-a-specific-management-node)

## Introduction

Management node personalization refers to the process of CFS applying a configuration to a
management node after it is booted.

The same CFS configuration is used for post-boot personalization of master, storage, and worker
management nodes. However, some individual parts of that configuration will only be applied to
appropriate node types.

This document provides several common procedures which are performed during CSM install and upgrade
and as operational tasks after the install or upgrade. Each procedure is described in its own
section below.

## Re-run node personalization on management nodes

This procedure describes how to re-run node personalization on management nodes even if
no changes have been made to the configuration layers (such as a new layer, different playbook,
or new commit made).

This procedures causes CFS to re-run personalization on management nodes by clearing the
configuration state and error count on the management node components. This causes the CFS Batcher
to reconfigure these components.
See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md)
for more information on the CFS Batcher.

This procedure has a scripted option and a manual option. Use the scripted option if possible.

### Prerequisites to re-run node personalization on management nodes

- The Cray CLI must be configured and authenticated.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation RPM must be installed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

### Scripted procedure to re-run node personalization on management nodes

The `apply_csm_configuration.sh` script can be used to easily clear the configuration state and
error count across all the management nodes at once. This causes CFS to reconfigure these
components. The script waits for all the management node components to complete their configuration
and reports a message indicating how many management nodes succeeded and how many failed their
configuration.

The script currently requires that we provide it with the name of the CFS configuration applied
to the management nodes. If all management nodes do not use the same CFS configuration, it is
best to use the
[Manual procedure to re-run node personalization on management nodes](#manual-procedure-to-re-run-node-personalization-on-management-nodes).
The first step of this procedure checks whether all management nodes use the same CFS configuration.

1. (`ncn-mw#`) Get the CFS configuration applied to all management NCNs.

    ```bash
    CFS_CONFIG_NAME="$(cray cfs components list --format json \
        --ids "$(cray hsm state components list --role=management --format json \
                 | jq -r '.Components | map(.ID) | join(",")')" \
        | jq -r 'map(.desiredConfig) | unique | first')"
    echo "${CFS_CONFIG_NAME}" | xargs -n 1
    ```

    If there is a single configuration applied to all management nodes, the output should look like this:

    ```text
    management-23.4.0
    ```

    If there is more than one CFS configuration listed, use the
    [Manual procedure to re-run node personalization on management nodes](#manual-procedure-to-re-run-node-personalization-on-management-nodes)
    instead of the scripted procedure.

1. (`ncn-mw#`) Execute the script with the `CFS_CONFIG_NAME` variable set in the previous step.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --clear-state
    ```

    Successful output will end with a message similar to the following:

    ```text
    Configuration complete. 9 component(s) completed successfully.  0 component(s) failed.
    ```

    The number reported should match the number of management NCNs in the system. If there are failures, see
    [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md).

### Manual procedure to re-run node personalization on management nodes

This procedure manually clears the CFS configuration state and error count across all the management
node components at once. This causes CFS to reconfigure these components.

1. (`ncn-mw#`) To re-run NCN personalization on all management NCNs at once, use the following loop:

    ```bash
    FAILED="" ; COUNT=0 ; \
    for xname in $(cray hsm state components list \
                        --role Management --type node \
                        --format json |
                jq -r .Components[].ID)
    do
        echo "Clearing CFS state of ${xname}"
        cray cfs components update --error-count 0 --state '[]' --format json "${xname}" && let COUNT+=1 || FAILED+=" ${xname}"
    done ; \
    echo "Cleared CFS state on ${COUNT} nodes" ; \
    [[ -z ${FAILED} ]] && echo "No errors" || echo "ERROR: There were errors clearing the CFS state for the following nodes:${FAILED}"
    ```

## Re-run node personalization on a specific management node

This procedure describes how to re-run node personalization on a specific management node even if no
changes have been made to the configuration layers (such as a new layer, different playbook, or new
commit made).

This procedures causes CFS to re-run personalization on a management node by clearing the
configuration state and error count on the management node component. This causes the CFS Batcher
to reconfigure these components.
See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md)
for more information on the CFS Batcher.

### Prerequisites to re-run node personalization on a specific management node

- The Cray CLI must be configured and authenticated.
  - See [Configure the Cray CLI](../configure_cray_cli.md).

### Manual procedure to re-run node personalization on a specific management node

1. (`ncn#`) Set `XNAME` to the xname of the management node which should be reconfigured.

    Here is one way the xname can be obtained from the node to be reconfigured:

    ```bash
    XNAME=$(cat /etc/cray/xname)
    ```

1. (`ncn#`) Clear the state and error count of the node using CFS.

    ```bash
    cray cfs components update --error-count 0 --state '[]' --format json "${XNAME}"
    ```
