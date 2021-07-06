## Reset Credentials on Redfish Devices

Before re-installing or upgrading the system the credentials need to be changed back to their defaults for any devices that had their credentials changed post-install. This is necessary for the installation process to properly discover and communicate with these devices.

### Prerequisites

Administrative privileges are required.

### Procedure

1.  Create a SCSD payload file with the default credentials for the redfish devices that have been changed from the defaults.

    The following example shows a payload file that will set the devices \`x0c0s0b0\` and \`x0c0s1b0\` back to the default redfish credentials.

    ```json
    {
        "Force": false,
        "Username": "root",
        "Password": "<BMC root password>",
        "Targets": [
            "x0c0s0b0",
            "x0c0s1b0"
        ]
    }
    ```

2.  Set credentials for multiple targets.

    ```bash
    ncn-m001# cray scsd bmc globalcreds create PAYLOAD_FILE --format json
    {    "Targets": [
            {
                "Xname": "x0c0s0b0",
                "StatusCode": 200,
                "StatusMsg": "OK"
            },
            {
                "Xname": "x0c0s1b0",
                "StatusCode": 200,
                "StatusMsg": "OK"
            },   
        ]
    }
    ```


For more information about using the System Configuration Service, refer to [System Configuration Service](../system_configuration_service/System_Configuration_Service.md)

