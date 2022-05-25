# Default Keycloak Realms, Accounts, and Clients

The following default realms, accounts, and clients are created when the system software is installed:

### Default Realms

-   `Master`
-   `Shasta`

### Default Keycloak Accounts

Username: `admin`

The password can be obtained with the following command:

```bash
ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
--template={{.data.password}} | base64 --decode
```

The password for the `admin` account can be changed. See [Change the Keycloak Admin Password](Change_the_Keycloak_Admin_Password.md).

### Default Keycloak Clients

Users authenticate to Keycloak on behalf of a client. Keycloak clients own configurations, such as the mapping of Keycloak user information to data available to either the `userinfo` endpoint, or in the JWT token. Keycloak clients also own resources, such as URIs.

|Client|Type|Descriptions|
|------|----|------------|
|`admin-client`|Private|The `admin-client` client represents a service account that is used during the install to register the services with the API gateway. The secret for this account is generated during the software installation process.|
|`shasta`|Public|The `shasta` client is meant to be a generic client that can be used to access any Cray micro-service. The SMS install process creates the `shasta` client in the `Shasta` realm. The `shasta` client is public and has mappers set up so that the `uidNumber`, `gidNumber`, `homeDirectory`, and `loginShell` user attributes are included in the `userinfo` response. The `shasta` client has 2 roles created for authorization: `admin` and `user`.|
|`gatekeeper`|Private|The `gatekeeper` client is used by the `keycloak-gatekeeper` to authenticate web UIs using OAUTH.|
|`system-compute-client`|Private|The `system-compute-client` client is used by the Cray Operating System \(COS\) for compute nodes and some NCN services for boot orchestration and management.|
|`system-pxe-client`|Private|The `system-pxe-client` client is used by the cray-ipxe service to communicate with cray-bss to prepare boot scripts and other boot-related content.|

