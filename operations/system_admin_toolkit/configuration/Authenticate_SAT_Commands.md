# Authenticate SAT Commands

To run SAT commands on the Kubernetes control plane (`ncn-m`) nodes, first set up authentication to
the API gateway. For more information on which SAT commands require authentication to the API
Gateway, see [SAT Command Overview](../about_sat/SAT_Command_Overview.md).

For more general information on API gateway authentication, see
[System Security and Authentication](../../security_and_authentication/System_Security_and_Authentication.md).

The admin account used to authenticate with `sat auth` must be enabled in
Keycloak and must have its *assigned role* set to *admin*. For more information
on Keycloak accounts and changing *Role Mappings*, refer to the following sections:

* [Configure Keycloak Account](../../CSM_product_management/Configure_Keycloak_Account.md)
* [Create Internal User Accounts in the Keycloak Shasta Realm](../../security_and_authentication/Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md)

## Prerequisites

* CSM has been installed

## Background

The `sat auth` command prompts for a password for the configured username on
the command line. The username value is obtained from the following locations,
in order of higher precedence to lower precedence:

* The `--username` global command-line option.
* The `username` option in the `api_gateway` section of the configuration file
  at `~/.config/sat/sat.toml`.
* The name of currently logged in user running the `sat` command.

If credentials are entered correctly when prompted by `sat auth`, a token file
will be obtained and saved to `~/.config/sat/tokens`. Subsequent sat commands
will determine the username the same way as `sat auth` described above and will
use the token for that username if it has been obtained and saved by `sat auth`.

## Procedure

The following procedure describes how to configure the username in the SAT
configuration file and authenticate as that user to the API gateway.

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
