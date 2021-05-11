# Configure the Cray Command Line Interface (cray CLI)

TODO Add headers: About this task, Role, Objective, Limitations, New in this Release

The cray command line interface (CLI) is a framework created to integrate all of the system management REST
APIs into easily usable commands. 

Later procedures in the installation process use the 'cray' CLI to interact with multiple services.
The 'cray' CLI configuration needs to be initialized and the user running the procedure needs to be authorized. 
This section describes how to initialize the 'cray' CLI for use by a user and authorize that user.

The 'cray' CLI only needs to be initialized once per user on a node.

1. Unset CRAY_CREDENTIALS environment variable, if previously set.

   Some of the installation procedures leading up to this point use the CLI with a Kubernetes managed service
   account normally used for internal operations.  There is a procedure for extracting the OAUTH token for
   this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.  

   ```bash
   ncn# unset CRAY_CREDENTIALS
   ```

1. Initialize the 'cray' CLI for the root account.

   The 'cray' CLI needs to know what host to use to obtain authorization and what user is requesting authorization
   so it can obtain an OAUTH token to talk to the API Gateway.  This is accomplished by initializing the CLI
   configuration.  In this example, the `vers` username and its password are used. 

   If LDAP configuration has enabled, then use a valid account in LDAP instead of 'vers'.

   If LDAP configuration was not enabled, or is not working, then a keycloak local account could be created. 
   Refer to "Create a Service Account in Keycloak" in the _HPE Cray EX System Administration Guide S-8001_.

   ```bash
   ncn# cray init
   ```

   When prompted, remember to substitute your username instead of 'vers'.
   Expected output (including your typed input) should look similar to the following:
   ```
   Cray Hostname: api-gw-service-nmn.local
   Username: vers
   Password:
   Success!

   Initialization complete.
   ```

## Troubleshooting

   If initialization fails in the above step, there are several common causes:

   * DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
   * Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
   * Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
   * Istio failures may be preventing traffic from reaching Keycloak
   * Keycloak may not yet be set up to authorize you as a user

   While resolving these issues is beyond the scope of this section, you may get clues to what is failing by adding `-vvvvv` to the `cray init ...` commands.

