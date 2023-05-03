# Manage System Passwords

Many system services require login credentials to gain access to them. The information below is a comprehensive list of system passwords and how to change them.

Contact HPE Cray service in order to obtain the default usernames and passwords for any of these components or services.

## Keycloak

Default Keycloak admin user login credentials:

- Username: admin
- The password can be obtained with the following command:

  ```bash
  kubectl get secret -n services keycloak-master-admin-auth \
  --template={{.data.password}} | base64 --decode
  ```

To update the default password for the admin account, refer to [Change the Keycloak Admin Password](Change_the_Keycloak_Admin_Password.md).

To create new accounts, refer to [Create Internal User Accounts in the Keycloak Shasta Realm](Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md).

## Gitea

The default Gitea user credentials is `crayvcs`. The password is randomly generated at install time
and can be found in the vcs-user-credentials secret.

```bash
kubectl get secret -n services vcs-user-credentials \
--template={{.data.vcs_password}} | base64 --decode
```

For more information on Gitea, including how to change the password, see [Version Control Service VCS](../configuration_management/Version_Control_Service_VCS.md).

## System Management Health Service

The default username is admin.

> **`NOTE`** Contact HPE Cray service in order to obtain the default password for Grafana and Kiali.

## Management Network Switches

Each rack type includes a different set of passwords. During different stages of installation, these passwords are subject to change.

> **`NOTE`** Contact HPE Cray service in order to obtain the default passwords.

The tables below include the default login credentials for each rack type. These passwords can be changed by going into the console on a given switch and changing it.
However, if the user gets locked out attempting to change the password or the configuration gets corrupted for an individual switch, it can wipe out the entire network configuration for the system.

> **`NOTE`** IP addresses can be found from the generated SLS file.

**Liquid-Cooled Cabinet:**

| Name     | Role      | Switch          |  Login |
| -----    | --------- | --------------- |  ----- |
| sw-leaf-bmc | Leaf-BMC/Mgmt | Dell S3048-ON   |  admin |
| sw-spine | Spine | Mellanox SN2100 |  admin |
| sw-leaf-bmc | Leaf-BMC/Mgmt | Aruba 6300   |  admin |
| sw-spine | Spine | Aruba 8325 |  admin |
| sw-leaf | Leaf | Aruba 8325 |  admin |

**Air-Cooled Cabinet:**

| Name    | Role      | Switch        |  Login |
| ------- | --------- | ------------- |  ----- |
| sw-leaf-bmc | Leaf/Mgmt | Dell S3048-ON |  admin |
| sw-leaf-bmc | Leaf-BMC/Mgmt | Aruba 6300   |  admin |

**Coolant Distribution Unit (CDU):**

| Name   | Role | Switch         |  Login |
| ------ | ---- | -------------- |  ----- |
| sw-cdu | CDU/Leaf | Dell S4048T-ON |  admin |
| sw-cdu | CDU/Leaf | Aruba 8360 |  admin |

**ClusterStor:**

| Name     | Role                  | Switch         | IP Address    | Login |
| -------- | --------------------- | -------------- | ------------- | ----- |
| Arista   |                       | DCS-7060CX-32S | 172.16.249.10 | admin |
| Sonexion | Entry point to Arista | CS-L300        | 172.30.49.178 | admin |
| E1000    |                       | CS-E1000       |               | admin |

## Redfish Credentials

Redfish accounts are only valid with the Redfish API. They do not allow system logins via `ssh` or serial console.

Three accounts are created by default:

- Root - Administrative account
  - Username: root

- Operator - Power components on/off, read values, and configure accounts
  - Username: operator

- ReadOnly - Log in, configure self, and read values
  - Username: guest

> **`NOTE`** Contact HPE Cray service in order to obtain the default passwords.

The System Configuration Service (SCSD) is used to set the credentials for Redfish BMCs.
Refer to [Set BMC Credentials](../system_configuration_service/Set_BMC_Credentials.md) for more information.

The account database is automatically saved to the non-volatile settings partition
\(/nvram/redfish/redfish-accounts\) any time an account or account policy is modified.
The file is stored as a redis command dump and is replayed \(if it exists\) anytime the core Redfish
schema is loaded via the init script. If default accounts must be restored,
delete the redis command dump and reboot the controller.

**List accounts:**

Use the following API path to list all accounts:

```bash
GET /redfish/v1/AccountService/Accounts

    {
        "@odata.context": "/redfish/v1/$metadata#ManagerAccountCollection.ManagerAccountCollection",
        "@odata.etag": "W/\"1559675674\"",
        "@odata.id": "/redfish/v1/AccountService/Accounts",
        "@odata.type": "#ManagerAccountCollection.ManagerAccountCollection",
        "Description": "Collection for Manager Accounts",
        "Members": [
        {
            "@odata.id": "/redfish/v1/AccountService/Accounts/1"
        },
        {
            "@odata.id": "/redfish/v1/AccountService/Accounts/2"
        }
        ],
        "Members@odata.count": 2,
        "Name": "Accounts Collection"
    }

```

Use the following API path to list a single account:

```bash
GET /redfish/v1/AccountService/Accounts/1

    {
        "@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount(*)",
        "@odata.etag": "W/"1559675272"",
        "@odata.id": "/redfish/v1/AccountService/Accounts/1",
        "@odata.type": "#ManagerAccount.v1_1_1.ManagerAccount",
        "Description": "Default Account",
        "Enabled": true,
        "Id": "1",
        "Links": {
            "Role": {
                "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
            }
        },
        "Locked": false,
        "Name": "Default Account",
        "RoleId": "Administrator",
        "UserName": "root"
    }
```

**Add accounts:**

If an account is successfully created, then the account information data structure will be returned.
The most important bit returned is the Id because it is part of the URL used for any further manipulation of the account.

Use the following API path to add accounts:

```bash
POST /redfish/v1/AccountService/Accounts

    Content-Type: application/json
    {
        "Name": "Test Account",
        "RoleId": "Administrator",
        "UserName": "test",
        "Password": "test123",
        "Locked": false,
        "Enabled": true
    }

    Response:
    {
        "@odata.context": "/redfish/v1/$metadataAccountService/Members/Accounts",
        "@odata.etag": "W/"1559679136"",
        "@odata.id": "/redfish/v1/AccountService/Accounts",
        "@odata.type": "#ManagerAccount.v1_1_1.ManagerAccount",
        "Description": "Collection of Account Details",
        "Id": "5",  **<<-- Note this value**
        "Links": {
            "Role": {
                "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
            }
        },
        "Enabled": true,
        "Locked": false,
        "Name": "Test",
        "RoleId": "Administrator",
        "UserName": "test"
    }
```

**Delete accounts:**

Delete an account with the `curl` command:

```bash
# curl -u root:xxx -X DELETE https://x0c0s0b0/redfish/v1/AccountService/Accounts/ACCOUNT_ID
```

**Update passwords:**

Update the password for an account with the `curl` command:

> **WARNING**: Changing Redfish credentials outside of Cray System Management (CSM) services may cause the Redfish device to be no longer manageable under CSM.
> If the credentials for other devices need to be changed, refer to the following device-specific credential changing procedures:
>
> - To change liquid-cooled BM≥C credentials, refer to [Change Cray EX Liquid-Cooled Cabinet Global Default Password](../security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md).
> - To change air-cooled node BMC credentials, refer to [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md).
> - To change Slingshot switch BMC credentials, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.

```bash
# curl -u root:xxx -X PATCH \
-H 'Content-Type: application/json' \
-d '{"Name": "Test"}' \
https://x0c0s0b0/redfish/v1/AccountService/Accounts/ACCOUNT_ID
```

## System Controllers

For SSH access, the system controllers have the following default credentials:

- Node controller \(nC\)
  - Username: root

- Chassis controller \(cC\)
  - Username: root

- Switch controller \(sC\)
  - Username: root

- sC minimal recovery firmware image \(rec\)
  - Username: root

> **`NOTE`** Contact HPE Cray service in order to obtain the default passwords.

Passwords for nC, cC, and sC controllers are all managed with the following process. The cfgsh tool is a configuration shell that can be used interactively or scripted. Interactively, it may be used as follows after logging in as root via `ssh`:

```bash
config
x0c1(conf)# CURRENT_PASSWORD root NEW_PASSWORD
x0c1(conf)# exit
copy running-config startup-config
exit
```

It may be used non-interactively as well. This is useful for separating out several of the commands used for the initial setup. The shell utility returns non-zero on error.

```bash
# cfgsh --config CURRENT_PASSWORD root NEW_PASSWORD
# cfgsh copy running-config startup-config
```

In both cases, a `running-config` must be saved out to non-volatile storage in a startup configuration file. If it is not, the password will revert to default on the next boot. This is the exact same behavior as standard managed Ethernet switches.

## SNMP Credentials

To adjust the SNMP credentials, perform the following tasks:

1. Update the default credentials specified in the customizations.yaml file.

- See [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md)

1. Update the credentials actively being used for existing leaf switches.

- See For more information on SNMP credentials, see [Configuring SNMP in CSM]( ../../operations/network/management_network/configure_snmp.md)

## HPE Cray EX Liquid-Cooled Cabinet Hardware

Change the global default credential on HPE Cray EX liquid-cooled cabinet embedded controllers (BMCs).
The chassis management module (CMM) controller (cC), node controller (nC), and Slingshot switch controller (sC) are generically referred to as "BMCs" in these procedures.

- See [Change EX Liquid-Cooled Cabinet Global Default Password](Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md)

Provision a Glibc compatible SHA-512 administrative password hash to a cabinet environmental controller (CEC). This password becomes the Redfish default global credential to access the CMM controllers and node controllers (BMCs).

- See [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md)

Change the credential for HPE Cray EX liquid-cooled cabinet chassis controllers and node controller (BMCs) used by CSM services after the CECs have been set to a new global default credential.

- See [Updating the Liquid-Cooled EX Cabinet CEC with Default Credentials after a CEC Password Change](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md)

## Gigabyte

The default username is admin.

> **`NOTE`** Contact HPE Cray service in order to obtain the default password for Gigabyte.

## Passwords Managed in Other Product Streams

Refer to the following product stream documentation for detailed procedures about updating passwords for compute nodes and User Access Nodes (UANs).

**Cray Operating System (COS):** To update the root password for compute nodes, refer to "Set Root Password for Compute Nodes" in the COS product stream documentation for more information.

**User Access Node (UAN):** Refer to "Create UAN Boot Images" in the UAN product stream documentation for the steps required to change the password on UANs.
The "uan_shadow" header in the "UAN Ansible Roles" section includes more context on setting the root password on UANS.
