## System Configuration Service

The System Configuration Service \(SCSD\) allows admins to set various BMC and controller parameters. These parameters are typically set during discovery, but this tool enables parameters to be set before or after discovery. The operations to change these parameters are available in the Cray CLI under the `scsd` command.

The following are the parameters that most commonly must be set:

-   SSH keys

    **Important:** If the scsd tool is used to update the SSHConsoleKey value outside of ConMan, it will disrupt the ConMan connection to the console and collection of console logs. Refer to [ConMan](../conman/ConMan.md)

-   NTP server
-   Syslog server
-   BMC/Controller passwords

The scsd tool includes a REST API to facilitate operations to set parameters. It will contact the Hardware State Manager \(HSM\) to verify that targets are correct and in a valid hardware state, unless the "Force" flag is specified. Once it has a list of targets, scsd will perform the needed Redfish operations in parallel using TRS. Any credentials needed will be retrieved from Vault.

In all POST operation payloads, there is an optional "Force" parameter. If this parameter is present and set to "true", then HSM will not be contacted and the Redfish operations will be attempted without verifying they are present or in a good state. If the "Force" option is not present, or is present but set to "false", HSM will be used.

The specified targets can be BMCs, controller xnames, or HSM group IDs. If BMCs and controllers are grouped in HSM, this service becomes much easier to use because single targets can be used rather than long lists.

To view the current build version of the scsd service:

```
ncn-m001# cray scsd version list
Version = "v1.2.3"
```

### Limitations in Release 1.4

SCSD cannot be used to alter NTP, Syslog, SSH keys, or BMC credentials on Chassis Management Modules \(CMM\) due to a DNS name resolution bug in the 1.4 release. Alterations must be done manually with the curl command.

For example:

```screen
ncn-m001# curl -k -u root:<redacted\> -X PATCH -d '\{"Oem": \{"SSHAdmin: \\
\{"AuthorizedKeys":"xxxxxxxx"\}\}\}' https://x1000c0/redfish/v1/Managers/BMC/NetworkProtocol
```

### Table of Contents
  
* [Manage Parameteres with the scsd Service](Manage_Parameters_with_the_scsd_Service.md)
* [Set BMC Credentials](Set_BMC_Credentials.md)


