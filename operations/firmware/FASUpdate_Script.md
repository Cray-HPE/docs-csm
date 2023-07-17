# `FASUpdate` Script

The `FASUpdate` Script automates several steps for updating firmware using one of the standard default FAS action recipes.

The script will use an action recipe and monitor the update until all nodes have completed.
While waiting for the update to complete, a summary will periodically be outputted.

To update the firmware, first create an authentication token.
On most systems, this is created with the following command (`ncn-mw#`)

```bash
export TOKEN=$(curl -s -S -d grant_type=client_credentials \
-d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
-o jsonpath='{.data.client-secret}' | base64 -d` \
https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
| jq -r '.access_token')
```

The `FASUpdate` Script will be installed in `/usr/share/doc/csm/scripts/operations/firmware`
Set an alias for the `FASUdate.py` script to include the path (`ncn-mw#`)

```bash
alias FASUpdate.py=/usr/share/doc/csm/scripts/operations/firmware/FASUpdate.py
```

* [List available action recipes](#list-available-action-recipes)
* [Performing a FAS update](#performing-a-fas-update)
* [Options for `FASUpdate` script](#options-for-fasupdate-script)
* [Sample `FASUpdate` script run](#sample-fasupdate-script-run)

## List available action recipes

`FASUpdate.py --list` : list the available action recipes in the default directory

`FASUpdate.py --list --recipedir {dir}` : list the available action recipes in the directory `{dir}`

## Performing a FAS update

(`ncn-mw#`) `FASUpdate.py --file {filename} --overrideDryrun [true/false]` : Use recipe {`filename`} in default directory to do an update on the system.
Default for `overrideDryrun` is false, which will perform a dryrun of the update.
Set `overrideDryrun` to true to do an actual update instead of a dryrun.

`FASUpdate.py --file {filename} --recipedir {dir}` : Use recipe {`filename`} in directory {`dir`} to do an update on the system.

`FASUpdate.py --file {filename} --xnames x1,x2,x3` : Use recipe {`filename`} to do an update only on `x1`, `x2`, and `x3`

`FASUpdate.py --file {filename} --watchtime {sec} --description {des}` : Use recipe {`filename`} to do an update, output summary every {`sec`} seconds (default 30) and overwrite the description with {`des`}.

## Options for `FASUpdate` script

* `--file filename` : Name of the action recipe file (required for update).
* `--list` : List the available action recipe files in the default or specified directory.
* `--recipedir dir` : Directory containing the action recipe file (if not using the default directory).
* `--xnames xname1,xname2` : List of xnames to be updated. If not present, FAS will check all xnames.
* `--overrideDryrun {true/false}` : Default false - Set to true to do an actual update run instead of a dryrun.
* `--imageID imageID` : Update nodes to `imageID` instead of the latest firmware available.
* `--watchtime sec` : Number of seconds to wait before outputting the summary status (default 30).
* `--description des` : Overwrite the description field in the recipe file.
* `--url-fas url` : URL to access FAS (usually not needed).

## Sample `FASUpdate` script run

(`ncn-mw#`)

```bash
export TOKEN=$(curl -s -S -d grant_type=client_credentials \
        -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
        -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
    | jq -r '.access_token')
FASUpdate.py --list
```

Example output:

```text
Available files in /usr/share/doc/csm/scripts/operations/firmware/recipes:
cray_chassisBMC_BMC.json
cray_nodeBMC_BMC.json
cray_nodeBMC_node0AccFPGA0.json
cray_nodeBMC_node0BIOS.json
cray_nodeBMC_node1AccFPGA0.json
cray_nodeBMC_node1BIOS.json
cray_nodeBMC_nodeAccFPGA0.json
cray_nodeBMC_nodeBIOS.json
cray_routerBMC_BMC.json
gigabyte_nodeBMC_BIOS.json
gigabyte_nodeBMC_BMC.json
hpe_nodeBMC_iLO5.json
hpe_nodeBMC_systemRom.json
cray_nodeBMC_node0AccVBIOS.json
cray_nodeBMC_node0ManagementEthernet.json
cray_nodeBMC_node1ManagementEthernet.json
cray_nodeBMC_node2BIOS.json
cray_nodeBMC_node2ManagementEthernet.json
cray_nodeBMC_node3BIOS.json
cray_nodeBMC_node3ManagementEthernet.json
cray_nodeBMC_nodeManagementEthernet.json

FASUpdate.py --file cray_chassisBMC_BMC.json --watchtime 15

Recipe filename: /usr/share/doc/csm/scripts/operations/firmware/recipes/cray_chassisBMC_BMC.json
JSON payload to FAS action command:
{"inventoryHardwareFilter": {"manufacturer": "cray"}, "stateComponentFilter": {"deviceTypes": ["chassisBMC"]}, "targetFilter": {"targets": ["BMC"]}, "command": {"version": "latest", "tag": "default", "overrideDryrun": false, "restoreNotPossibleOverride": true, "timeLimit": 1000, "description": "Upgrade of Cray Chassis Controllers -- Dryrun 10/11/2022 20:37:14"}}
Action ID: dc47615a-a491-4199-b7a6-b58f5c33f0c2
--------------------------- running ----------------------
State: running Date: 10/11/2022 20:37:16
> total: 8
> configured: 8
--------------------------- running ----------------------
State: running Date: 10/11/2022 20:37:19
> total: 8
> configured: 8
--------------------------- running ----------------------
State: running Date: 10/11/2022 20:37:21
> total: 8
> configured: 8
--------------------------- running ----------------------
State: running Date: 10/11/2022 20:37:24
> total: 8
> inProgress: 1
> succeeded: 7
--------------------------- running ----------------------
State: running Date: 10/11/2022 20:37:26
> total: 8
> succeeded: 8
--------------------------- COMPLETED ----------------------
State: completed Date: 10/11/2022 20:37:28
> total: 8
> succeeded: 8
--------------------------- COMPLETED ----------------------
Action ID: dc47615a-a491-4199-b7a6-b58f5c33f0c2
Review action with the following command:
cray fas actions describe dc47615a-a491-4199-b7a6-b58f5c33f0c2
```
