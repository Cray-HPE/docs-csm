# Bare-Metal Steps

This section provides information on what needs to be done before
an initial install of CSM.

### Air-Cooled BMC Credentials

It is necessary to set the default credentials of all air-cooled BMCs so that
CSM Hardware Management can interact with Redfish.

This procedure is outlined in [Change Air-Cooled BMC Credentials](Change_River_BMC_Credentials.md).

### Liquid-Cooled BMC Credentials

As with air-cooled BMCs, liquid-cooled BMCs also need their credentials changed.

This procedure is outlined in [Change Liquid-Cooled BMC Credentials](../security_and_authentication/Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md).

### ServerTech PDU Default Credentials

ServerTech PDUs must have their default credentials set as well. These are
not native Redfish devices; they have a proprietary interface which is
abstracted by the HMS Redfish Translation Service.

To set ServerTech PDU default credentials, follow the procedure outlined in
[Change ServerTech PDU Credentials](Change_ServerTech_PDU_Credentials.md).

