# Fresh Install: Setting NodeBMC and RouterBMC Redfish Credentials

These steps are performed before the installation of Shasta System Management
or HPCM management software stacks. The goal is to set the BMC Redfish
credentials to values that the management software will be expecting so that
all software systems work smoothly with the Redfish hardware.

### Prerequisites

Before doing these operations, the following is assumed:

- There is a workstation or laptop which can access all target BMCs.
- Workstation or laptop has the `curl` command installed.
- The hostname or IP address of each BMC is known or obtainable.
- The default BMC password is obtainable for each target BMC.

### Set BMC Passwords on All Air-Cooled BMC Hardware

This involves interaction with the BMC hardware itself.

The BMC factory-default passwords are found on a sticker or card associated
with the blades themselves. Some blade enclosures also have a chassis-level
management controller (CMC) which may also have its own default password, which
would need to be changed as well.

The procedure for each blade is to obtain the factory-default password for
each blade's BMC, and then use `curl` to set the root BMC account password to
the desired password (which must match the one set in customizations.yaml).

Each Redfish BMC will have at least one "account", and often several accounts.
Each account has an ordinal number, and only one of the accounts is the `root`
account. This account is the one that must have its password changed.

#### Procedure

Use the following procedure for each BMC:

1. Get the default BMC password and the hostname or IP address of the BMC.

2. Determine which Redfish account is the root account:

   ```bash
   linux# curl -s -k -u root:<DFLTPW> https://<BLADENAME_OR_IP>/redfish/v1/AccountSystem/Accounts | jq
   ```

   Example output:

   ```
   {
     "@odata.context": "/redfish/v1/$metadata#ManagerAccountCollection.ManagerAccountCollection",
     "@odata.id": "/redfish/v1/AccountService/Accounts",
     "@odata.type": "#ManagerAccountCollection.ManagerAccountCollection",
     "Name": "Accounts Collection",
     "Description": "BMC User Accounts",
     "Members@odata.count": 4,
     "Members": [
       {
         "@odata.id": "/redfish/v1/AccountService/Accounts/1"
       },
       {
         "@odata.id": "/redfish/v1/AccountService/Accounts/2"
       },
       {
         "@odata.id": "/redfish/v1/AccountService/Accounts/3"
       },
       {
         "@odata.id": "/redfish/v1/AccountService/Accounts/4"
       }
     ]
   }
   ```

3. For each account listed, use `curl` to find the one which describes the `root` account ("UserName": "root").

   **NOTES:**
   - The `root` account can be any of the listed accounts -- no guarantees as to which one it will be.
   - If the account information contains an *etag* entry, note this number, as it will be required when setting the password.

   ```bash
   linux# curl -s -k -u root:<DFLTPW> https://<BLADENAME_OR_IP>/redfish/v1/AccountSystem/Accounts/1 | jq
   ```

   Example output:

   ```
   {
     "@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount",
     "@odata.id": "/redfish/v1/AccountService/Accounts/1",
     "@odata.type": "#ManagerAccount.v1_1_1.ManagerAccount",
     "@odata.etag": "W/\"570254F2\"",
     "Id": "3",
     "Name": "User Account",
     "Description": "User Account",
     "Enabled": true,
     "Password": null,
     "UserName": "root",
     "RoleId": "NoAccess",
     "Links": {
       "Role": {
         "@odata.id": "/redfish/v1/AccountService/Roles/NoAccess"
       }
     }
   }
   ```

4. Set the new password for this account. Use the ETAG in the header if needed.

   ```bash
   linux# curl -s -k -u root:<DFLTPW> -H "If-None-Match: 570254F2" -H "Content-Type: application/json" -X PATCH -d '{"Password":"<NEWPW>"}' https://<BLADENAME_OR_IP>/redfish/v1/AccountSystem/Accounts/1
   linux#
   ```

5. Test to be sure the new password works. If the password set operation did not work, then this will fail.

   ```bash
   linux# curl -s -k -u root:<NEWPW> https://<BLADENAME_OR_IP>/redfish/v1/AccountSystem
   ```

   Example output:

   ```
   {
     "@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount",
     "@odata.id": "/redfish/v1/AccountService/Accounts/1",
     "@odata.type": "#ManagerAccount.v1_1_1.ManagerAccount",
     "@odata.etag": "W/\"570254F2\"",
     "Id": "3",
     "Name": "User Account",
     "Description": "User Account",
     "Enabled": true,
     "Password": null,
     "UserName": "root",
     "RoleId": "NoAccess",
     "Links": {
       "Role": {
         "@odata.id": "/redfish/v1/AccountService/Roles/NoAccess"
       }
     }
   }
   ```

### Set Default Credentials for High-Speed Network (HSN) Switch BMCs

This is the exact same procedure as for node BMCs, except that the source of
the default BMC passwords is different.

The default passwords for all air-cooled high-speed network switch BMCs is a
known factory default and is outside the scope of this document.

Once this password, and any HSN BMC IP addresses or hostnames are obtained,
the procedure above can be used to set the Redfish root account passwords to
the new value.

**NOTE:** The default credentials for both air-cooled and liquid-cooled high-speed network switch BMCs should be identical.

