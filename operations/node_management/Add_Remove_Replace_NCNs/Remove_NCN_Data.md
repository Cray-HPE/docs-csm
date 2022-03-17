# Remove NCN Data

## Description

Remove NCN data to System Layout Service (SLS), Hardware Management Services (HMS) and Boot Script Service (BSS) as needed to remove an NCN.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#remove-prerequisites)

``` bash
ncn-mw# cd /usr/share/docs/csm/scripts/operations/node_management
ncn-mw# remove_management_ncn.py --xname $XNAME
```
