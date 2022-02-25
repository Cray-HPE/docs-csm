## Add an NCN to the HSM Database

This procedure details how to customize the bare-metal non-compute node \(NCN\) on a system and add the NCN to the Hardware State Manager \(HSM\) database.

The examples in this procedure use `ncn-w0003-nmn` as the Customer Access Node \(CAN\). Use the correct CAN for the system.

### Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.
- The initial software installation is complete.
- Keycloak authentication is complete.

### Procedure

1.  Locate the component name (xname) of the system.

    The component name (xname) is located in the `/etc/hosts` file.

    ```bash
    ncn# grep ncn-w003-nmn /etc/hosts
    ```

    Example output:

    ```
    0.252.1.15   ncn-w003.local ncn-w003 ncn-w003-nmn ncn-w003-nmn.local sms03-nmn x3000c0s24b0n0 #-label-10.252.1.15
    ```

2. Create an entry with the following keypairs.

   get\_token needs to be created or exist in the script with the following curl command. The get\_token function is defined below:

   ```bash
    ncn# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
   ```

   The `get_token` function adds the authorization required by the HTTPS security token. `-H` options tell the REST API to accept the data as JSON and that the information is for a JSON-enabled application.

   ```bash
   ncn# curl -X POST -k https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components \
   -H "Authorization: Bearer $(get_token)" -H "accept: application/json" -H \
   "Content-Type: application/json" -d \
   '{"Components":[{"ID":"x3000c0s24b0","State":"On","NetType":"Sling","Arch":"X86","Role":"Management"}]}'
   ```

3.  List HSM state components and verify information is correct.

    ```bash
    ncn# cray hsm state components list --id x3000c0s24b0
    ```

    Example output:

    ```
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

4.  Find the daemonset pod that is running on the NCN being added to the HSM database.

    ```bash
    ncn# kubectl get pods -l app.kubernetes.io/instance=ncn-customization -n services -o wide
    ```

    Example output:

    ```
    NAME                                  READY  STATUS    RESTARTS   AGE    IP          NODE       NOMINATED NODE   READINESS GATES
    ncn-customization-cray-service-4tqcg  2/2    Running   2          4d2h   10.47.0.3   ncn-m001   <none>           <none>
    ncn-customization-cray-service-dh8gb  2/2    Running   1          4d2h   10.42.0.4   ncn-w003   <none>           <none>
    ncn-customization-cray-service-gwxc2  2/2    Running   2          4d2h   10.40.0.8   ncn-w002   <none>           <none>
    ncn-customization-cray-service-rjms5  2/2    Running   2          4d2h   10.35.0.3   ncn-w004   <none>           <none>
    ncn-customization-cray-service-wgl44  2/2    Running   2          4d2h   10.39.0.3   ncn-w005   <none>           <none>
    ```

5.  Delete the daemonset pod.

    Deleting the pod will restart it and enable the changes to be picked up.

    ```bash
    ncn# kubectl -n services delete pod ncn-customization-cray-service-dh8gb
    ```

6.  Verify the daemonset restarts on the NCN with the CAN configuration.

    1.  Retrieve the new pod name.

        ```bash
        ncn# kubectl get pods -l app.kubernetes.io/instance=ncn-customization \
        -n services -o wide | grep ncn-w003
        ```

        Example output:

        ```
        ncn-customization-cray-service-dh8gb   2/2  Running   2   22d   10.36.0.119   ncn-w003   <none>   <none>
        ```

    2.  Wait for the daemonset pod to cycle through the unload session.

        This may take up to 5 minutes.

        ```bash
        ncn# cray cfs sessions list | grep "name ="
        ```

        Example output:

        ```
        name = "ncn-customization-ncn-w003-unload"
        ```

    3.  Wait for the daemonset pod to cycle through the load session.

        This may take up to 5 minutes.

        ```bash
        ncn# cray cfs sessions list | grep "name ="
        ```

        Example output:

        ```
        name = "ncn-customization-ncn-w003-load"
        ```

        Once the load job completes, if there are no errors returned, the session is removed.

        Running `cray cfs sessions list | grep "name ="` again should return with no sessions active. If Ansible errors were encountered during the unload or load sessions, the dormant CFS session artifacts remain for CFS Ansible failure troubleshooting.

