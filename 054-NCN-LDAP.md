# Configuring Cray Datacenter LDAP

This is an INTERNAL process to configure our dev systems to use LDAP for users and groups.

Add or change the `keycloak_users_localize` sealed secret in the `customizations.yaml` file for the system:

```
spec:
  kubernetes:
    sealed_secrets:
      keycloak_users_localize:
        generate:
          name: keycloak-users-localize
          data:
          - type: static
            args:
              name: ldap_connection_url
              value: ldap://172.30.79.134
```

Run `utils/secrets-seed-customizations.sh customizations.yaml` to generate the encrypted value.

Configure non-secret options by adding the following fields to the `cray-keycloak-users-localize` chart customizations:

```
spec:
  kubernetes:
    services:
      cray-keycloak-users-localize:
        ldapSearchBase: "dc=datacenter,dc=cray,dc=com"
        localRoleAssignments:
        - {"group": "criemp", "role": "admin", "client": "shasta"}
        - {"group": "criemp", "role": "admin", "client": "cray"}
        - {"group": "craydev", "role": "admin", "client": "shasta"}
        - {"group": "craydev", "role": "admin", "client": "cray"}
        - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
        - {"group": "shasta_admins", "role": "admin", "client": "cray"}
        - {"group": "shasta_users", "role": "user", "client": "shasta"}
        - {"group": "shasta_users", "role": "user", "client": "cray"}
```
