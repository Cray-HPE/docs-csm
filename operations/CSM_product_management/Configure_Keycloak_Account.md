# Configure Keycloak Account

Installation of CSM software includes a default account for administrative access to keycloak.

Depending on choices made during the installation, there may be a federated connection to
an external Identity Provider (IdP), such as an LDAP or AD server, which enables the use
of external accounts in keycloak.

However, if the external accounts are not available, then an "internal user account" could be
created in keycloak. Having a usable account in keycloak with administrative authorization
enables the use of the `cray` CLI for many administrative commands, such as those used to
[Validate CSM Health](../../validate_csm_health.md) and general operation of the management services
via the API gateway.

See [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md)
in the "Default Keycloak Realms, Accounts, and Clients" section for more information about these topics.

   * Certificate Types
   * Change the Keycloak Admin Password
   * Create a Service Account in Keycloak
   * Retrieve the Client Secret for Service Accounts
   * Get a Long-Lived Token for a Service Account
   * Access the Keycloak user Management UI
   * Create Internal User Accounts in the Keycloak Shasta Realm
   * Delete Internal User Accounts in the Keycloak Shasta Realm
   * Remove the Email Mapper from the LDAP User Federation
   * Re-Sync Keycloak Users to Compute Nodes
   * Configure Keycloak for LDAP/AD Authentication
   * Configure the RSA Plugin in Keycloak
   * Preserve Username Capitalization for Users Exported from Keycloak
   * Change the LDAP Server IP Address for Existing LDAP Server Content
   * Change the LDAP Server IP Address for New LDAP Server Content
   * Remove the LDAP User Federation from Keycloak
   * Add LDAP User Federation
