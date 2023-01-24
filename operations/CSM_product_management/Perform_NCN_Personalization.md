# Perform NCN Personalization

NCN personalization is the process of applying product-specific configuration to NCNs post-boot.

## Procedure: Perform NCN personalization

See [NCN Node Personalization](../configuration_management/NCN_Node_Personalization.md).

## Procedure: Re-Run NCN personalization

If no changes have been made to the configuration layers (such as a new layer,
different playbook, or new commit made), but NCN personalization needs to be
run again, then CFS can re-run NCN personalization on specific nodes.

Re-run the configuration for an NCN by clearing the state of the node. Clearing
the node state will cause CFS to reconfigure the node to its desired configuration.

* [Re-run CFS on single node](#re-run-cfs-on-single-node)
* [Re-run CFS on all management NCNs](#re-run-cfs-on-all-management-ncns)

### Re-run CFS on single node

(`ncn#`) Clear the state and error count of the node using CFS.

Replace the `<XNAME>` string in the following command with the component name (xname) of the node being reconfigured.

```bash
cray cfs components update --error-count 0 --state '[]' --format json <XNAME>
```

### Re-run CFS on all management NCNs

(`ncn#`) To re-run NCN personalization on all management NCNs at once, use the following loop:

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
[[ -z ${FAILED} ]] && echo "No errors" || echo "ERROR: There were errors clearing the CFS state for the following nodes:${xname}"
```
