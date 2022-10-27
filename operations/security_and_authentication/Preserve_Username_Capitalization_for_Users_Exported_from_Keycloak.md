# Preserve Username Capitalization for Users Exported from Keycloak

Keycloak converts all characters in a username to lowercase when users are exported. Use this procedure to update the `keycloak-users-localize` tool with a configuration option that enables
administrators to preserve the username letter case when users are exported from Keycloak.

The LDAP server that provides password resolution and user account federation supports mixed case usernames. If the usernames are changed to lowercase when exported from Keycloak, it can cause issues.

## Prerequisites

- The `kubectl` command is installed.
- Each user's `homeDirectory` attribute has the exact username as the last element of the path.

## Procedure

1. (`ncn-mw#`) Update the user export setting in the `customizations.yaml` file.

    Set the `userExportNameSource` field to `homeDirectory` in the `spec.kubernetes.services.cray-keycloak-users-localize` field in the `customizations.yaml` file.

    ```bash
    vi customizations.yaml
    ```

1. Re-apply the `cray-keycloak-users-localize` Helm chart with the updated `customizations.yaml` file.

1. (`ncn-mw#`) Upload the modified `customizations.yaml` file to Kubernetes.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```
