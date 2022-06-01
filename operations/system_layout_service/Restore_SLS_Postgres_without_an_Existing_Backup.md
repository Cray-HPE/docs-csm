# Restore SLS Postgres without an Existing Backup

This procedure is intended to repopulate SLS in the event when no Postgres backup exists.

## Prerequisite

- Healthy SLS Service.
    > Verify all 3 SLS replicas are up and running:
    > ```
    > ncn# kubectl -n services get pods -l cluster-name=cray-sls-postgres
    > NAME                  READY   STATUS    RESTARTS   AGE
    > cray-sls-postgres-0   3/3     Running   0          18d
    > cray-sls-postgres-1   3/3     Running   0          18d
    > cray-sls-postgres-2   3/3     Running   0          18d
    > ```


## Procedure

1. Retrieve the initial `sls_input_file.json` that was used to initially install the system with from `sls` S3 bucket.
    ```bash
    ncn# cray artifacts get sls sls_input_file.json sls_input_file.json
    ```

2. Perform an SLS load state operation to replace the contents of SLS with the data from the `sls_input_file.json` file.

    Get an API Token:
    ```bash
    ncn# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

    Perform the load state operation:
    ```bash
    ncn# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -F sls_dump=@sls_input_file.json \
        https://api-gw-service-nmn.local/apis/sls/v1/loadstate
    ```

3. Any previously made customizations made to SLS will need to be applied again. This includes any SLS API operations that modified the state of SLS.
    - The HSN network in SLS will be missing HSN subnet data, this data will need to be repopulated again using the "Set up DNS for HSN IP addresses" procedure in the *Slingshot Operations Guide*.

    - Any hardware that was added or moved in the system using one of the following procedures will need to be performed again.
        - [Add a Standard Rack Node](../node_management/Add_a_Standard_Rack_Node.md)
        - [Move a Standard Rack Node Same Rack/Same HSN Ports](../node_management/Move_a_Standard_Rack_Node_SameRack_SameHSNPorts.md)
        - [Move a Standard Rack Node](../node_management/Move_a_Standard_Rack_Node.md)