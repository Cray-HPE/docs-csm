# Change the Keycloak Admin Password

Update the default password for the admin Keycloak account using the Keycloak user interface (UI). After updating the password in
Keycloak, encrypt it on the system and verify that the change was made successfully.

- [System domain name](#system-domain-name)
- [Procedure](#procedure)

## System domain name

The `SYSTEM_DOMAIN_NAME` value found in some of the URLs on this page is expected to be the system's fully qualified domain name (FQDN).

(`ncn-mw#`) The FQDN can be found by running the following command on any Kubernetes NCN.

```bash
kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | yq r - spec.network.dns.external
```

Example output:

```text
system..hpc.amslabs.hpecorp.net
```

Be sure to modify the example URLs on this page by replacing `SYSTEM_DOMAIN_NAME` with the actual value found using the above command.

## Procedure

1. (`ncn-mw#`) Retrieve the `admin` user's password for Keycloak.

   ```bash
   kubectl get secret -n services keycloak-master-admin-auth -ojsonpath='{.data.password}' | base64 -d
   ```

1. Point a browser at `https://auth.cmn.SYSTEM_DOMAIN_NAME/keycloak/`, replacing `SYSTEM_DOMAIN_NAME` with the actual NCN's DNS name. Login using the `admin` user and password obtained in the previous step.

   Use of the `auth.cmn.` sub-domain is required for administrative access to Keycloak.

1. Click the `Admin` drop-down menu in the upper-right corner of the page.

1. Select `Signing in`, under `Account security`.

1. Click the `Update` button on the left side of the page.

1. Enter the new password and confirmation, and then click `Submit`.

1. (`ncn-w001#`) Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   - Name of chart to be redeployed: `cray-keycloak`
   - Base name of manifest: `platform`
   - When reaching the step to update customizations, perform the following steps:

      **Only follow these steps as part of the previously linked chart redeploy procedure.**

      1. Run `git clone https://github.com/Cray-HPE/csm.git`.

      1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

         ```bash
         cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
         ```

      1. Change the password in the `customizations.yaml` file.

         The Keycloak master admin password is also stored in the `keycloak-master-admin-auth` Kubernetes Secret in the `services`
         namespace. This must be updated so that clients which need to make requests as the master admin can authenticate with the new
         password.

         In the `customizations.yaml` file, set the values for the `keycloak_master_admin_auth` keys in the
         `spec.kubernetes.sealed_secrets` field. The value in the data element where the name is `password` needs to be changed to the
         new Keycloak master admin password. The section below will replace the existing sealed secret data in the `customizations.yaml`
         file.

         For example:

         ```yaml
               keycloak_master_admin_auth:
                 generate:
                   name: keycloak-master-admin-auth
                   data:
                   - type: static
                     args:
                       name: client-id
                       value: admin-cli
                   - type: static
                     args:
                       name: user
                       value: admin
                   - type: static
                     args:
                       name: password
                       value: my_secret_password
                   - type: static
                     args:
                       name: internal_token_url
                       value: https://api-gw-service-nmn.local/keycloak/realms/master/protocol/openid-connect/token
         ```

      1. Encrypt the values after changing the `customizations.yaml` file.

         ```bash
         ./utils/secrets-seed-customizations.sh customizations.yaml
         ```

         If the above command complains that it cannot find `certs/sealed_secrets.crt` then you can run the following commands to create it:

         ```bash
         mkdir -pV certs && ./utils/bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > certs/sealed_secrets.crt
         ```

   - (`ncn-w001#`) When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      Verify that the Secret has been updated.

      Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

      ```bash
      kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
      ```

   - **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**
