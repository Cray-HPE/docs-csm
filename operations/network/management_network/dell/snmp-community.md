# Configure SNMPv2c community

The switch supports SNMPv2c community-based security for read-only and read-write access.

## Configuration commands

### Configure the SNMP community

1. Enter configuration mode.

   ```console
   configure terminal
   ```

1. Configure the SNMPv2c community name

   ```console
   snmp-server community community-name access-mode
   ```

   Parameters:

   | Parameter        | Description                                                                                  |
   |------------------|----------------------------------------------------------------------------------------------|
   | `community-name` | The user defined name for this community.                                                    |
   | `access-mode`    | The access level for this community. Can be `ro` for read-only or `rw` for read-write access |

### Example

The following command configures a read-only SNMP community called "public".

```text
snmp-server community public ro
```

When successful this command returns no output.

### Show configured SNMP community

The following command displays information about any SNMP community that may have been configured.

```console
show snmp community
```

Example output:

```text
Community      : public
Access         : read-only
```

## Expected Results

1. Administrators can configure the community name.
2. Administrators can bind the SNMP server to the default VRF.
3. Administrators can connect from the workstation using the community name.

[Back to Index](../README.md)
