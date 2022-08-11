# Remove NCN Data

## Description

Remove NCN data to System Layout Service (SLS), Boot Script Service (BSS), and Hardware State Manager (HSM) as needed to remove an NCN.

## Procedure

**IMPORTANT:** The following procedures assume that you have set the variables from [the prerequisites section](../Add_Remove_Replace_NCNs.md#remove-ncn-prerequisites).

1. Prepare for the procedure.

    1. Obtain an API token.

        ```bash
        ncn-mw# cd /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs
        ncn-mw# export TOKEN=$(curl -s -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                                | jq -r '.access_token')
        ```

    1. Set BMC credentials for the NCN (unless doing this for `ncn-m001`).

        The default username is `root`.
        Set `IPMI_USERNAME` if this needs to be different for the given BMC.

        > `read -s` is used in order to prevent the password from being echoed to the screen or saved in the shell history.

        ```bash
        ncn-mw# read -r -s -p "BMC ${IPMI_USERNAME-root} password: " IPMI_PASSWORD
        ncn-mw# export IPMI_PASSWORD
        ```

1. Fetch the status of the nodes.

    ```bash
    ncn-mw# ./ncn_status.py --all
    ```

    Example output:

    ```text
    first_master_hostname: ncn-m002
    ncns:
        ncn-m001 x3000c0s1b0n0 master
        ncn-m002 x3000c0s3b0n0 master
        ncn-m003 x3000c0s5b0n0 master
        ncn-w001 x3000c0s7b0n0 worker
        ncn-w002 x3000c0s9b0n0 worker
        ncn-w003 x3000c0s11b0n0 worker
        ncn-w004 x3000c0s34b0n0 worker
        ncn-s001 x3000c0s13b0n0 storage
        ncn-s002 x3000c0s15b0n0 storage
        ncn-s003 x3000c0s17b0n0 storage
        ncn-s004 x3000c0s26b0n0 storage
    ```

1. Fetch the status of the node to be removed.

    ```bash
    ncn-mw# ./ncn_status.py --xname "${XNAME}"
    ```

    Example output:

    ```text
    ...
    x3000c0s26b0n0:
        xname: x3000c0s26b0n0
        name: ncn-s004
        parent: x3000c0s26b0
        type: Node, Management, Storage
        sources: bss, hsm, sls
        ip_reservations: 10.1.1.19, 10.101.5.150, 10.101.5.214, 10.101.5.36, 10.252.1.21, 10.254.1.38
        ip_reservations_name: ncn-s004-mtl, ncn-s004-can, x3000c0s26b0n0, ncn-s004-cmn, ncn-s004-nmn, ncn-s004-hmn
        ip_reservations_mac: a4:bf:01:38:f4:50, a4:bf:01:38:f4:50, , , a4:bf:01:38:f4:50, a4:bf:01:38:f4:50
        ifnames: mgmt0:a4:bf:01:38:f4:50, mgmt1:a4:bf:01:38:f4:51, lan0:b8:59:9f:de:b4:8c, lan1:b8:59:9f:de:b4:8d
    ncn_macs:
        ifnames: mgmt0:a4:bf:01:38:f4:50, mgmt1:a4:bf:01:38:f4:51, lan0:b8:59:9f:de:b4:8c, lan1:b8:59:9f:de:b4:8d
        bmc_mac: a4:bf:01:38:f4:54
    ```

    **Important**: Save the `ifnames` and `bmc_mac` information if planning to add this NCN back at some time in the future.

1. Shutdown `cray-reds`.

    ```bash
    ncn-mw# kubectl -n services scale deployment cray-reds --replicas=0
    ```

1. Remove the node from SLS, HSM, and BSS.

    ```bash
    ncn-mw# ./remove_management_ncn.py --xname "${XNAME}"
    ```

    Example output:

    ```text
    ...

    Permanently remove x3000c0s26b0n0 - ncn-s004 (y/n)? y

    ...

    Summary:
        Logs: /tmp/remove_management_ncn/x3000c0s26b0n0
        xname: x3000c0s26b0n0
        ncn_name: ncn-s004
        ncn_macs:
            ifnames: mgmt0:a4:bf:01:38:f4:50, mgmt1:a4:bf:01:38:f4:51, lan0:b8:59:9f:de:b4:8c, lan1:b8:59:9f:de:b4:8d
            bmc_mac: a4:bf:01:38:f4:54

    Successfully removed x3000c0s26b0n0 - ncn-s004
    ```

    **NOTE:**
    If workers have been removed and the worker count is currently at two, then a timeout restarting `cray-bss` can be ignored.
    For example, the following failure output from `remove_management_ncn.py` can be ignored.

    ```text
    Waiting for cray-bss to start.
    Do not kill this script. The wait will timeout in 10 minutes if bss does not fully start up.
    Ran:     kubectl -n services rollout status deployment cray-bss --timeout=600s
    Error:          Failed: 1
             stdout:
    Waiting for deployment "cray-bss" rollout to finish: 0 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...

             stderr:
    error: timed out waiting for the condition
    ```

1. Start `cray-reds`.

    ```bash
    ncn-mw# kubectl -n services scale deployment cray-reds --replicas=1
    ```

1. Verify the results by fetching the status of the management nodes.

    ```bash
    ncn-mw# ./ncn_status.py --all
    ```

    Example output:

    ```text
    first_master_hostname: ncn-m002
    ncns:
        ncn-m001 x3000c0s1b0n0 master
        ncn-m002 x3000c0s3b0n0 master
        ncn-m003 x3000c0s5b0n0 master
        ncn-w001 x3000c0s7b0n0 worker
        ncn-w002 x3000c0s9b0n0 worker
        ncn-w003 x3000c0s11b0n0 worker
        ncn-w004 x3000c0s34b0n0 worker
        ncn-s001 x3000c0s13b0n0 storage
        ncn-s002 x3000c0s15b0n0 storage
        ncn-s003 x3000c0s17b0n0 storage
    ```

1. Fetch the status of the node that was removed.

    ```bash
    ncn-mw# ./ncn_status.py --xname "${XNAME}"
    ```

    Example output:

    ```text
    Not found: x3000c0s26b0n0
    ```

Proceed to [Remove Switch Configuration](Remove_Switch_Config.md) or return to the main
[Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
