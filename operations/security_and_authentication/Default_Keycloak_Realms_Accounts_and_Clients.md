# Default Keycloak Realms, Accounts, and Clients

This page details the default Keycloak realms, accounts, and clients that are created when the system software is installed.

- [Default realms](#default-realms)
- [Default accounts](#default-accounts)
- [Default clients](#default-clients)
  - [Private clients](#private-clients)
  - [Public clients](#public-clients)

## Default realms

- `Master`
- `Shasta`

## Default accounts

Username: `admin`

(`ncn-mw#`) The password can be obtained with the following command:

```bash
kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
```

The password for the `admin` account can be changed. See [Change the Keycloak `admin` Password](Change_the_Keycloak_Admin_Password.md).

## Default clients

Users authenticate to Keycloak on behalf of a client. Keycloak clients own configurations, such as the mapping of Keycloak user information to data available to either the
`userinfo` endpoint, or in the JWT token. Keycloak clients also own resources, such as URIs.

### Private clients

- `admin-client`
  - The `admin-client` client represents a service account that is used during the install to register the services with the API gateway. The secret for this account is
    generated during the software installation process.
- `oauth2-proxy-*`
  - The `oauth2-proxy-*` clients are used by the `oauth2-proxies` to authenticate web UIs using OAUTH.
- `system-compute-client`
  - The `system-compute-client` client is used by the Cray Operating System \(COS\) for compute nodes and some NCN services for boot orchestration and management.
- `system-pxe-client`
  - The `system-pxe-client` client is used by the `cray-ipxe` service to communicate with `cray-bss` to prepare boot scripts and other boot-related content.
- `system-nexus-client`
  - The `system-nexus-client` client is used by the `cray-nexus` service to login to Nexus with Keycloak users. The `system-nexus-client` has two roles created for
  authorization: `nx-admin` and `nx-anonymous` that can be added to any account to give permissions to that user in Nexus.

### Public clients

- `shasta`
  - The `shasta` client is meant to be a generic client that can be used to access any Cray micro-service. The software install process creates the `shasta` client in the `Shasta` realm.
    The `shasta` client is public and has mappers set up so that the `uidNumber`, `gidNumber`, `homeDirectory`, and `loginShell` user attributes are included in the `userinfo` response.
    The `shasta` client has two roles created for authorization: `admin` and `user`.
