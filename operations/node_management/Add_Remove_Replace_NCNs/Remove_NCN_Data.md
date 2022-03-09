# Remove NCN Data

## Description

Remove NCN data to System Layout Service (SLS), Hardware Management Services (HMS) and Boot Script Service (BSS) as needed to remove an NCN.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#remove-prerequisites)

1. Setup
``` bash
ncn-mw# cd /usr/share/docs/csm/scripts/operations/node_management

ncn-mw# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
            -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
            | jq -r '.access_token')
```

1. Fetch the status of the nodes
``` bash
ncn-mw# ncn_status.py --all

ncn-mw# ncn_status.py --xname $XNAME
```

1. Remove the node
``` bash
ncn-mw# remove_management_ncn.py --xname $XNAME
```

1. Verify the results by fetching the status of the nodes

``` bash
ncn-mw# ncn_status.py --all

ncn-mw# ncn_status.py --xname $XNAME
```
