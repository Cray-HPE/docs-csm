## Manage Parameters with the scsd Service

The System Configuration Service commands below enable administrators to set various BMC and controller parameters. These parameters are controlled with the scsd command in the Cray CLI.

### Retrieve Current Information from Targets

Get the network protocol parameters \(NTP/syslog server, SSH keys\) and boot order for the targets in the payload. All fields are only applicable to Liquid Cooled controllers. Attempts to set them for Air Cooled BMCs will be ignored, and retrieving them for Air Cooled BMCs will return empty strings.

Command line options can be used to set parameters as desired. For example, if only the NTP server info is to be set, only the "NTPServer" value has to be present.

The following is an example payload file that was used to generate the output in the command below:

```
{
    "Force": true,
    "Targets": [
        "x0c0s0b0",
        "x0c0s1b0"
    ],
    "Params": [
        "NTPServerInfo",
        "SyslogServerInfo",
        "SSHKey",
        "SSHConsoleKey",
        "BootOrder"
    ]
}
```

To retrieve information from the targets:

```
ncn-m001# cray scsd bmc dumpcfg create PAYLOAD_FILE --format json
{
    "Targets": [
    {
        "StatusCode": 200,
        "StatusMsg": "OK",
        "Xname": "x0c0s0b0",
        "Params":
        {
              "NTPServerInfo":
              {
                  "NTPServers": "sms-ncn-w001",
                  "Port": 123,
                  "ProtocolEnabled": true
              },
              "SyslogServerInfo":
              {
                  "SyslogServers": "sms-ncn-w001",
                  "Port":514,
                  "ProtocolEnabled": true
              },
              "SSHKey": "xxxxyyyyzzzz",
              "SSHConsoleKey": "aaaabbbbcccc",
              "BootOrder": ["Boot0",Boot1",Boot2",Boot3"]
        }
    },
    {
        "StatusCode": 200,
        "StatusMsg": "OK",
        "Xname": "x0c0s0b0",
        "Params":
        {
              "NTPServerInfo":
              {
                  "NTPServers": "sms-ncn-w001",
                  "Port": 123,
                  "ProtocolEnabled": true
              },
              "SyslogServerInfo":
              {
                  "SyslogServers": "sms-ncn-w001",
                  "Port":514,
                  "ProtocolEnabled": true
              },
              "SSHKey": "xxxxyyyyzzzz",
              "SSHConsoleKey": "aaaabbbbcccc",
              "BootOrder": ["Boot0",Boot1",Boot2",Boot3"]
         }
    }
    ]
}
```

### Retrieve Information from a Single Target

Retrieve NTP server information, syslog information, or the SSH key from a single target.

```
ncn-m001# cray scsd bmc cfg describe XNAME --format json
{
  "Force": false,
  "Params": {
    "SSHConsoleKey": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCg1yUfF5zPwOWjp3B/4LtuEGdbwo23L8BkQwhBz/4lVX2K2viYhGBAGwzqWMe1OQjSz3cUiSE/A6Kr7tKwB77j4U51XLbTRy5tcqzhIVFb7kFgdSqyUxfv+5s0aNLkwpI00w2TVVSp7xy8t+CLHwgdC7RXtWHOmI35NdUc8y8monn+q4mQV0ms29h1/tpHETocPQjCMwIsOtvUyS91XAn72Va1Xe8uTaAO+SqTZMYVTOxfLeLTg6QLox8PBXpVz422E4bcKZOYT68s1DxL5Rtz7HB6iKtXOvLaJSe8S5AUEe1G4eojQ/NEHcNobZkO00wSIzce2TwZV1il7410yGle1njnWLZBSpYmfH8d2joX434IEdESTwgdrYBEBAtOe7yvXu+2Qiux4AFaQwI0Aiif2Q5FndgqUiN6pD1IkVkInBYGFR5La8ZdZAgUdptvIZNJE67D3aGj0cseJFMHY4hfLEK34xne5yvL3OqpyjSS/0oPd1kLk4BgA8npGroLP+bP2GH6fMe7Wu9Sk/UUoM1W6N7127xVlvIogKxTG27zes8LSw7R/vOpVnWqJ2/BVIblTkMV45lCBQXaj4xG8ju8Zofh23BMusTthu8Q+T48k6H17g2dVlYTuUN+/i1KnSMPI2+dbOyV+X/maW+TBS8zK1pV5VTptg0UZgaZim+WIQ== ",
    "SyslogServerInfo": {
      "ProtocolEnabled": true,
      "SyslogServers": [
        "rsyslog_agg_service_hmn.local"
      ],
      "Port": 514,
      "Transport": "udp"
    },
    "NTPServerInfo": {
      "NTPServers": [
        "10.254.0.4"
      ],
      "ProtocolEnabled": true,
      "Port": 123
    },
    "SSHKey": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCg1yUfF5zPwOWjp3B/4LtuEGdbwo23L8BkQwhBz/4lVX2K2viYhGBAGwzqWMe1OQjSz3cUiSE/A6Kr7tKwB77j4U51XLbTRy5tcqzhIVFb7kFgdSqyUxfv+5s0aNLkwpI00w2TVVSp7xy8t+CLHwgdC7RXtWHOmI35NdUc8y8monn+q4mQV0ms29h1/tpHETocPQjCMwIsOtvUyS91XAn72Va1Xe8uTaAO+SqTZMYVTOxfLeLTg6QLox8PBXpVz422E4bcKZOYT68s1DxL5Rtz7HB6iKtXOvLaJSe8S5AUEe1G4eojQ/NEHcNobZkO00wSIzce2TwZV1il7410yGle1njnWLZBSpYmfH8d2joX434IEdESTwgdrYBEBAtOe7yvXu+2Qiux4AFaQwI0Aiif2Q5FndgqUiN6pD1IkVkInBYGFR5La8ZdZAgUdptvIZNJE67D3aGj0cseJFMHY4hfLEK34xne5yvL3OqpyjSS/0oPd1kLk4BgA8npGroLP+bP2GH6fMe7Wu9Sk/UUoM1W6N7127xVlvIogKxTG27zes8LSw7R/vOpVnWqJ2/BVIblTkMV45lCBQXaj4xG8ju8Zofh23BMusTthu8Q+T48k6H17g2dVlYTuUN+/i1KnSMPI2+dbOyV+X/maW+TBS8zK1pV5VTptg0UZgaZim+WIQ== "
  }
}
```

Individual parameters can be specified in the command line with the `--param` option. Multiple parameters can be specified by using a comma separated list with the `--params` option. This makes it easier to find information for certain parameters. For example, to only view the NTP server information, the following option can be used:

```
ncn-m001# cray scsd bmc cfg describe --param NTPServerInfo \
XNAME --format json
{
  "Force": false,
  "Params": {
    "NTPServerInfo": {
      "NTPServers": [
        "10.254.0.4"
      ],
      "ProtocolEnabled": true,
      "Port": 123
    }
}
```

### Set Parameters for Targets

Set syslog, NTP server information, or SSH key for a set of targets.

The following is an example payload file that was used to generate the output in the command below:

```
{
    "Force": false,
    "Targets": [
        "x0c0s0b0",
        "x0c0s1b0"
    ],
    "Params":
    {
        "NTPServerInfo":
        {
            "NTPServers": "sms-ncn-w001",
            "Port": 123,
            "ProtocolEnabled": true
        },
        "SyslogServerInfo":
        {
            "SyslogServers": "sms-ncn-w001",
            "Port":514,
            "ProtocolEnabled": true
        },
        "SSHKey": "xxxxyyyyzzzz",
        "SSHConsoleKey": "aaaabbbbcccc",
        "BootOrder": ["Boot0","Boot1","Boot2","Boot3"]
    }
}
```

To set parameters for the specified targets:

```
ncn-w001# cray scsd bmc loadcfg create PAYLOAD_FILE --format json
{
    "Targets": [
        {
            "Xname": "x0c0s0b0",
            "StatusCode": 200,
            "StatusMsg": "OK"
        },
        {
            "Xname": "x0c0s1b0",
            "StatusCode": 405,
            "StatusMsg": "Only GET operations permitted"
        }
    ]
}
```

### Set Parameters for a Single BMC or Controller

Set the BMC configuration for a single target using a specific component name (xname). If no form data is specified, all network protocol data is returned for the target; otherwise, only the requested data is returned.

The following is an example payload file that was used to generate the output in the command below:

```screen
{
    "Force": true,
    "Params":
    {
        "NTPServerInfo":
        {
            "NTPServers": "sms-ncn-w001",
            "Port": 123,
            "ProtocolEnabled": true
        },
        "SyslogServerInfo":
        {
            "SyslogServers": "sms-ncn-w001",
            "Port":514,
            "ProtocolEnabled": true
        },
        "SSHKey": "xxxxyyyyzzzz",
        "SSHConsoleKey": "aaaabbbbcccc",
        "BootOrder": ["Boot0","Boot1","Boot2","Boot3"]
    }
}
```

To set the parameters for a single BMC or controller:

```
ncn-m001# cray scsd bmc cfg create XNAME --format json
{
    "StatusMsg": "OK"
}
```

### Set Redfish Credentials for Multiple Targets

Use the following command to set Redfish credentials for BMCs and controllers. Note that this is different than SSH keys, which are only used on controllers. These credentials are for Redfish access, not SSH access into a controller.

The API allows for different credentials to be set for each target within one call. It is not possible to retrieve credentials with this command. Only setting them is allowed for security reasons.

The payload for this API is amenable to setting different credentials for different targets all in one call. To set credentials for a group of controllers, set up a group in HSM and use the group ID.

The following is an example payload file that was used to generate the output in the command below:

```
{
    "Force": false,
    "Targets": [
        {
            "Xname": "x0c0s0b0",
            "Creds": {
                "Username": "root",
                "Password": "admin-pw"
            }
        },
        {
            "Xname": "x0c0s1b0",
            "Creds": {
                "Username": "root",
                "Password": "admin-pw"
            }
        }
    ]
}
```

To set the Redfish credentials for multiple targets:

```
ncn-m001# cray scsd bmc discreetcreds create PAYLOAD_FILE --format json
{
    "Targets": [
        {
            "Xname": "x0c0s0b0",
            "StatusCode": 200,
            "StatusMsg": "OK"
        },
        {
            "Xname": "x0c0s1b0",
            "StatusCode": 200,
            "StatusMsg": "OK"
        }
    ]
}
```

### Set Redfish Credentials for a Single Target

Set Redfish credentials for a single target. This command is similar to the `cray scsd bmc discreetcreds create` command, except it cannot be used to set different credentials for multiple targets.

The following is an example payload file that was used to generate the output in the command below:

```
{
    "Force": true,
    "Creds": {
        "Username": "root",
        "Password": "admin-pw"
    }
}
```

To set the Redfish credentials for a single target:

```
ncn-m001# cray scsd bmc creds create XNAME --format json
{
    "StatusMsg": "OK"
}
```

