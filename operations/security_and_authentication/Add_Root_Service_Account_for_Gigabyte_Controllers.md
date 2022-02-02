## Add Root Service Account for Gigabyte Controllers

By default, Gigabyte BMC and CMC controllers have the `admin` service
account configured. In order to discover this type of hardware, the
`root` service account needs to be configured.

### Prerequisites

The `root` service account is not already configured for the controller.

1. Check which service accounts are currently configured.

   ```bash
   ncn# curl -s -k -u <user>:<password> https://<xname>/redfish/v1/AccountService/Accounts | jq ".Members"
   [
     {
       "@odata.id": "/redfish/v1/AccountService/Accounts/1"
     }
   ]
   ```

1. Verify that none of the accounts listed are for `root`.

   ```bash
   ncn# curl -s -k -u <user>:<password> https://<xname>/redfish/v1/AccountService/Accounts/1 | jq '. | { Name: .Name, UserName: .UserName, RoleId: .RoleId }'
   {
     "Name": "admin",
     "UserName": "admin",
     "RoleId": "Administrator"
   }
   ```

The `root` account is not configured in the example shown above. If `root` is already configured, do not proceed with the following steps.

<a name="add_root_service_account_gigabyte_controllers"></a>
### Procedure

1. Run the following commands to configure the `root` service account for the controller:

   ```bash
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> user set name 4 root
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> user set password 4 <root_password>
   Set User Password command successful (user 4)
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> user priv 4 4 1
   Set Privilege Level command successful (user 4)
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> user enable 4
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> channel setaccess 1 4 callin=on ipmi=on link=on
   Set User Access (channel 1 id 4) successful.
   ```

1. Additionally, if the target controller is a BMC and not a CMC, run the following command:

   ```bash
   ncn# ipmitool -U <user> -P <password> -I lanplus -H <ip> sol payload enable 1 4
   ```

1. Verify that the `root` service account is now configured.

   ```bash
   ncn# curl -s -k -u <user>:<password> https://<xname>/redfish/v1/AccountService/Accounts | jq ".Members"
   [
     {
       "@odata.id": "/redfish/v1/AccountService/Accounts/4"
     },
     {
       "@odata.id": "/redfish/v1/AccountService/Accounts/1"
     }
   ]

   ncn# curl -s -k -u <user>:<password> https://<xname>/redfish/v1/AccountService/Accounts/4 | jq '. | { Name: .Name, UserName: .UserName, RoleId: .RoleId }'
   {
     "Name": "root",
     "UserName": "root",
     "RoleId": "Administrator"
   }
   ```

Now the `root` service account is configured.
