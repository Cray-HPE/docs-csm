# Set BMC Credentials

Redfish BMCs are installed on the system with default credentials. After the
machine is shipped, all BMC credentials must be changed.

BMC credentials may be set with either the System Configuration Service \(SCSD\),
or with the System Administrator Toolkit's `sat bmccreds` command. Both methods
enable administrators to set a unique value for each credential, or to set the same
value for every credential.

This procedure describes how to set BMC credentials with `sat bmccreds`, which
conveniently automates the steps of the SCSD procedure.

**Important:** If the credentials for other devices need to be changed, refer to the following device-specific procedures:
- To change liquid-cooled BMC credentials, refer to [Change Cray EX Liquid-Cooled Cabinet Global Default Password](../security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md).
- To change air-cooled Node BMC credentials, refer to [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md).
- To change ServerTech PDU credentials, refer to [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).
- To change Slingshot switch BMC credentials, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.

### Prerequisites

The System Administrator Toolkit is installed and configured.

### Procedures

Choose one of the following procedures.

#### Generate a unique random password for each BMC in the system.

```
# sat bmccreds --random-password --pw-domain bmc
```

#### Generate a single random password for all BMCs in the system.

```
# sat bmccreds --random-password --pw-domain system
```

#### Provide a user-defined password for all BMCs in the system.

```
# sat bmccreds USER-DEFINED_PASSWORD
```
