<h2 id="pre-upgrade-checks">Pre-Upgrade checks</h2>

Execute the following tests for the type of node being upgraded before proceeding -- ensuring the system stays healthy between each ncn being upgraded.

1. Master node specific goss instructions
   **TBD**: CASMINST-1962
1. Worker node specific goss instructions
   **TBD**: CASMINST-1963
1. Storage node specific goss instructions
   **TBD**: CASMINST-1964

<h2 id="prerequisite-steps">Prerequisite Steps</h2>

These steps should be taken regardless of the type of NCN you will be upgrading.

1. Get a token to use for authenticated communication with the gateway. These should be exported on a "stable" master
   node (i.e., one that you will not be upgrading in this iteration).
   > **`NOTE`** `api-gw-service-nmn.local` is legacy, and will be replaced with api-gw-service.nmn.

   ```bash
   ncn# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
      -d client_id=admin-client \
      -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

2. Export additional variables to hold all the information we need:

    ```text
    ncn# export CSM_RELEASE=csm-x.y.z
    ncn# export UPGRADE_NCN=<ncn> # <-- SET TO NODE BEING UPGRADED (like ncn-s001)
   
    ncn# export STABLE_NCN=$(hostname)  <=== it is recommended to use "ncn-m001" as stable ncn unless you are going to upgrade "ncn-m001"
    ncn# export UPGRADE_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
         jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$UPGRADE_NCN\")) | .Xname")
    ncn# export UPGRADE_IP_NMN=$(dig +short $UPGRADE_NCN.nmn)
    ```

    Double check the values returned by the commands:

    ```text
    ncn# echo $STABLE_NCN
    ncn-m002
   
    ncn# echo $UPGRADE_NCN
    ncn-m001
   
    ncn# echo $UPGRADE_XNAME
    x3000c0s1b0n0
   
    ncn# echo $UPGRADE_IP_NMN
    10.252.1.4
    ```

    If there are any incorrect values, correct them before proceeding.

3. Proceed either of the next steps:
   - [Upgrade Master Node](../stage3/k8s-master-node-upgrade.md)
   - [Upgrade Worker Node](../stage3/k8s-worker-node-upgrade.md)
   - [Storage Node Prerequisite Steps](../stage2/storage-prerequisite-steps.md)
