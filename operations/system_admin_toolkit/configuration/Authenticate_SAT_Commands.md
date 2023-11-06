# Authenticate SAT Commands

To run SAT commands on the Kubernetes control plane (`ncn-m`) nodes, first set up authentication to
the API gateway. For more information on authentication types and authentication credentials, see
[SAT Command Authentication](about_sat/command_authentication.md).

The admin account used to authenticate with `sat auth` must be enabled in
Keycloak and must have its *assigned role* set to *admin*. For more information
on Keycloak accounts and changing *Role Mappings*, refer to the following sections:

* [Configure Keycloak Account](operations/CSM_product_management/Configure_Keycloak_Account.md)
* [Create Internal User Accounts in the Keycloak Shasta Realm](operations/security_and_authentication/Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md)

## Prerequisites

* CSM has been installed

## Procedure

The following is the procedure to globally configure the username used by SAT and
authenticate to the API gateway.

1. (`ncn-m001#`) Generate a default SAT configuration file if one does not exist.

   ```bash
   sat init
   ```

   Example output:

   ```text
   Configuration file "/root/.config/sat/sat.toml" generated.
   ```

   **Note:** If the configuration file already exists, it will print out the
   following error.

   ```text
   ERROR: Configuration file "/root/.config/sat/sat.toml" already exists.
   Not generating configuration file.
   ```

1. (`ncn-m001#`) Edit `~/.config/sat/sat.toml` and set the username option in the `api_gateway`
   section of the configuration file.

   ```toml
   username = "crayadmin"
   ```

1. (`ncn-m001#`) Run `sat auth`. Enter the password when prompted.

   ```bash
   sat auth
   ```

   Example output:

   ```text
   Password for crayadmin:
   Succeeded!
   ```

1. (`ncn-m001#`) Other `sat` commands are now authenticated to make requests to the API gateway.

   ```bash
   sat status
   ```
