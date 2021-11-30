## Pre-Install Steps

This section provides information on what needs to be done before
an initial install of CSM.

### River BMC Credentials

It is necessary to set the default credentials of all River BMCs so that
CSM Hardware Management can interact with Redfish.

This procedure is outlined in [Change River BMC Credentials](Change_River_BMC_Credentials.md).

### ServerTech PDU Default Credentials

ServerTech PDUs must have their default credentials set as well.  These are
not native Redfish devices; they have a proprietary interface which is
abstracted by the HMS Redfish Translation Service.

To set ServerTech PDU default credentials, follow the procedure outlined in
[Change ServerTech PDU Credentials](Change_ServerTech_PDU_Credentials.md).


