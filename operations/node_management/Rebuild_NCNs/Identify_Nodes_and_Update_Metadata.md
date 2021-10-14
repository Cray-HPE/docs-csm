# Identify Nodes and Update Metadata

## Inspect and modify the JSON file

This section applies to all node types. The commands in this section assume you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#set-var).

### Step 1 - Generate the Boot Script Service \(BSS\) boot parameters JSON file

1. Run the following commands from a node that has cray cli initialized:

    ```bash
    cray bss bootparameters list --name $XNAME --format=json > ${XNAME}.json
    ```

### Step 2 - Modify the JSON file

1. Remove the outer array brackets.

    * Do this by removing the first and last line of the XNAME.json file, indicated with the `[` and `]` brackets.

1. Remove the leading whitespace on the new first and last lines.

    * On the new first and last lines of the file, removing all whitespace characters at the beginning of those lines. The first line should now just be a `{` character and the last line should now just be a `}` character.

1. Ensure the current boot parameters are appropriate for PXE booting.

    1. Inspect the `"params": "kernel..."` line. If the line begins with `BOOT_IMAGE` and/or does not contain `metal.server`, the following steps are needed:

    1. Remove everything before `kernel` on the `"params": "kernel"` line.
    1. Re-run steps [Retrieve the xname and Generate BSS JSON](#identify-retrieve) for another node/xname.  Look for an example that does not contain `BOOT_IMAGE`.

    1. Once an example is found, copy a portion of the `params` line for everything including and after `biosdevname`, and use that in the JSON file.

    1. After copying the content after `biosdevname`, change the `"hostname=<hostname>"` to the correct host.

    1. Set the kernel parameters to wipe the disk.

        * Locate the portion of the line that contains `"metal.no-wipe"` and ensure it is set to zero `"metal.no-wipe=0"`.

### Step 3 - Re-apply the boot parameters list for the node using the JSON file

1. Get a token to interact with BSS using the REST API.

    ```bash
    ncn# TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
        -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
        -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
        | jq -r '.access_token')
    ```

1. Do a PUT action for the new JSON file.

    ```bash
    ncn# curl -i -s -k -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
    "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" -X PUT -d @./${XNAME}.json
    ```

    **IMPORTANT:** Ensure a good response \(`HTTP CODE 200`\) is returned in the output.

### Step 4 -  Verify the `bss bootparameters list` command returns the expected information.

1. Export the list from BSS to a file with a different name.

    ```bash
    ncn# cray bss bootparameters list --name ${XNAME} --format=json > ${XNAME}.check.json
    ```

1. Compare the new JSON file with what was PUT to BSS.

    ```bash
    ncn# diff ${XNAME}.json ${XNAME}.check.json
    ```

    * The only difference between the files should be the square brackets that were removed from the file, and* the whitespace changes on the first and last lines with curly braces. Expected output will look similar to:

      ```screen
      1,2c1
      < [
      <   {
      ---
      > {
      47,48c46
      <   }
      < ]
      ---
      > }
      ```

[Click here for the Next Step](Wipe_Drives.md)

Or [Click here to returrn to the Main Page](../Rebuild_NCNs.md)