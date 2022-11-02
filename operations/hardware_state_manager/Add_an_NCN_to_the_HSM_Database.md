# Add an NCN to the HSM Database

This procedure details how to customize the bare-metal non-compute node \(NCN\) on a system and add the NCN to the Hardware State Manager \(HSM\) database.

The examples in this procedure use `ncn-w0003-nmn` as the Customer Access Node \(CAN\). Use the correct CAN for the system.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The initial CSM software installation is complete.
- Keycloak authentication is complete. See [Configure Keycloak Account](../CSM_product_management/Configure_Keycloak_Account.md).

## Procedure

1. (`ncn-mw#`) Locate the component name (xname) of the NCN.

    The xname is located in the `/etc/hosts` file. This example shows the xname for `ncn-w003`.

    ```bash
    grep ncn-w003-nmn /etc/hosts
    ```

    Example output:

    ```text
    10.252.1.15   ncn-w003.local ncn-w003 ncn-w003-nmn ncn-w003-nmn.local sms03-nmn x3000c0s24b0n0 #-label-10.252.1.15
    ```

1. (`ncn-mw#`) Define the `get_token` helper function.

    ```bash
    function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

1. (`ncn-mw#`) Create an entry with the following keypairs.

    The `get_token` function adds the authorization required by the HTTPS security token.
    The `-H` options tell the REST API to accept the data as JSON and that the information is for a JSON-enabled application.

    > Be sure to modify the example below to use the xname identified in the previous step.

    ```bash
    curl -X POST -k https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components \
        -H "Authorization: Bearer $(get_token)" -H "accept: application/json" -H \
        "Content-Type: application/json" -d \
        '{"Components":[{"ID":"x3000c0s24b0","State":"On","NetType":"Sling","Arch":"X86","Role":"Management"}]}'
    ```

1. (`ncn-mw#`) List HSM state components and verify that information is correct.

    > Be sure to modify the example below to use the xname identified in the previous step.

    ```bash
    cray hsm state components list --id x3000c0s24b0 --format toml
    ```

    Example output:

    ```toml
    [[Components]]
    Arch = "X86"
    Enabled = true
    Flag = "OK"
    State = "On"
    Role = "Management"
    NetType = "Sling"
    Type = "NodeBMC"
    ID = "x3000c0s24b0"
    ```

1. (`ncn-mw#`) Find the `daemonset` pod that is running on the NCN being added to the HSM database.

    ```bash
    kubectl get pods -l app.kubernetes.io/instance=ncn-customization -n services -o wide
    ```

    Example output:

    ```text
    NAME                                  READY  STATUS    RESTARTS   AGE    IP          NODE       NOMINATED NODE   READINESS GATES
    ncn-customization-cray-service-4tqcg  2/2    Running   2          4d2h   10.47.0.3   ncn-m001   <none>           <none>
    ncn-customization-cray-service-dh8gb  2/2    Running   1          4d2h   10.42.0.4   ncn-w003   <none>           <none>
    ncn-customization-cray-service-gwxc2  2/2    Running   2          4d2h   10.40.0.8   ncn-w002   <none>           <none>
    ncn-customization-cray-service-rjms5  2/2    Running   2          4d2h   10.35.0.3   ncn-w004   <none>           <none>
    ncn-customization-cray-service-wgl44  2/2    Running   2          4d2h   10.39.0.3   ncn-w005   <none>           <none>
    ```

1. (`ncn-mw#`) Delete the `daemonset` pod identified in the previous step.

    Deleting the pod will restart it and enable the changes to be picked up.

    > Be sure to modify the example below to use the pod name identified in the previous step.

    ```bash
    kubectl -n services delete pod ncn-customization-cray-service-dh8gb
    ```

1. (`ncn-mw#`) Verify the `daemonset` restarts on the NCN with the CAN configuration.

    1. Retrieve the new pod name.

        > Be sure to modify the example below to use the name of the NCN being added.

        ```bash
        kubectl get pods -l app.kubernetes.io/instance=ncn-customization -n services -o wide | grep ncn-w003
        ```

        Example output:

        ```text
        ncn-customization-cray-service-dh8gb   2/2  Running   2   22d   10.36.0.119   ncn-w003   <none>   <none>
        ```

    1. Wait for the `daemonset` pod to cycle through the unload session.

        This may take up to 5 minutes.

        ```bash
        cray cfs sessions list --format toml | grep "name ="
        ```

        Example output:

        ```toml
        name = "ncn-customization-ncn-w003-unload"
        ```

    1. Wait for the `daemonset` pod to cycle through the load session.

        This may take up to 5 minutes.

        ```bash
        cray cfs sessions list --format toml | grep "name ="
        ```

        Example output:

        ```toml
        name = "ncn-customization-ncn-w003-load"
        ```

        Once the load job completes, if there are no errors returned, the session is removed.

        Running `cray cfs sessions list --format toml | grep "name ="` again should return with no sessions active.
        If Ansible errors were encountered during the unload or load sessions, then the dormant CFS session artifacts remain for CFS Ansible failure troubleshooting.
