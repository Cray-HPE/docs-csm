# Remove NCN Data

## Description

Remove NCN data to System Layout Service (SLS), Boot Script Service (BSS) and Hardware State Manager (HSM) as needed to remove an NCN.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#remove-prerequisites)

1.  Setup:
    ```bash
    ncn-mw# cd /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs

    ncn-mw# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
                -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                | jq -r '.access_token')
    ```

1.  Optional Setup:

    Set the username and password to the BMC for the NCN. This step is optional. The NCN can be successfully be removed without this.
    Setting this enables the scripts to print the BMC's MAC address, which is information needed when the hardware is added back into the system.

    ```bash
    ncn-mw# export IPMI_USERNAME=root
    ncn-mw# export IPMI_PASSWORD=changeme
    ```

1.  Fetch the status of the nodes:
    ```bash
    ncn-mw# ./ncn_status.py --all
    ```
    
    Example output:
    ```
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

1.  Fetch the status of the node to be removed:
    ```bash
    ncn-mw# ./ncn_status.py --xname $XNAME
    ```

    Example output
    ```
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

    **Important**: Save the ifnames and bmc_mac information if you plan to add this NCN back at some time in the future.

1.  Remove the node from SLS, HSM, and BSS:
    ```bash
    ncn-mw# ./remove_management_ncn.py --xname $XNAME
    ```

    Example output
    ```
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

1.  Verify the results by fetching the status of the management nodes:

    ``` bash
    ncn-mw# ./ncn_status.py --all
    ```

    Example output:
    ```
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


1.  Fetch the status of the node that was removed:
    ```bash
    ncn-mw# ./ncn_status.py --xname $XNAME
    ```

    Example output:
    ```
    Not found: x3000c0s26b0n0
    ```

1.  Follow [Redeploy Services](./Redeploy_Services.md) to update service endpoints for the removed storage node.
