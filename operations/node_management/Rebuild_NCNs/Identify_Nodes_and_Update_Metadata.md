# Identify Nodes and Update Metadata

Use the following procedure to inspect and modify the Boot Script Service \(BSS\) boot parameters JSON file.

This section applies to all node types. The commands in this section assume the variables from [the prerequisites section](Rebuild_NCNs.md#Prerequisites) have been set.

## Procedure

1. Generate the BSS boot parameters JSON file.

   Run the following commands from a node that has `cray` CLI initialized:

   ```bash
   cray bss bootparameters list --name $XNAME --format=json | jq .[] > ${XNAME}.json
   ```

1. Modify the JSON file and set the kernel parameters to wipe the disk.

   Locate the portion of the line that contains `"metal.no-wipe"` and ensure it is set to zero `"metal.no-wipe=0"`.

1. Re-apply the boot parameters list for the node using the JSON file.

   1. Get a token to interact with BSS using the REST API.

       ```bash
       TOKEN=$(curl -s -S -d grant_type=client_credentials \
           -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
           -o jsonpath='{.data.client-secret}' | base64 -d` \
           https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
           | jq -r '.access_token')
       ```

   1. Do a PUT action for the new JSON file.

       ```bash
       curl -i -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
       "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" -X PUT -d @./${XNAME}.json
       ```

       **IMPORTANT:** Ensure a good response \(`HTTP CODE 200`\) is returned in the output.

1. Verify the `bss bootparameters list` command returns the expected information.

   1. Export the list from BSS to a file with a different name.

       ```bash
       cray bss bootparameters list --name ${XNAME} --format=json |jq .[]> ${XNAME}.check.json
       ```

   1. Compare the new JSON file with what was PUT to BSS.

       ```bash
       diff ${XNAME}.json ${XNAME}.check.json
       ```

       The files should be identical

## Next Step

Proceed to the next step to [Power Cycle and Rebuild Nodes](Power_Cycle_and_Rebuild_Nodes.md). Otherwise, return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
