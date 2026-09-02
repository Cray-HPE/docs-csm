# Configure SNMPv2c community

The switch supports `SNMPv2c` community-based security for read-only and read-write access.

## Configuration commands

### Configure the SNMP community

1. (`switch#`) Enter configuration mode.

   ```console
   configure terminal
   ```

1. (`switch#`) Configure the `SNMPv2c` community name.

   ```console
   snmp-server community community-name access-mode
   ```

   Parameters:

   | Parameter        | Description                                                                                  |
   |------------------|----------------------------------------------------------------------------------------------|
   | `community-name` | The user defined name for this community.                                                    |
   | `access-mode`    | The access level for this community. Can be `ro` for read-only or `rw` for read-write access |

### Example

(`switch#`) The following command configures a read-only SNMP community called "public".

```text
snmp-server community public ro
```

When successful this command returns no output.

### Show configured SNMP community

(`switch#`) The following command displays information about any SNMP community that may have been configured.

```console
show snmp community
```

Example output:

```text
Community      : public
Access         : read-only
```

## Expected results

* Administrators can configure the community name.
* Administrators can bind the SNMP server to the default VRF.
* Administrators can connect from the workstation using the community name.

[Back to Index](../README.md)
