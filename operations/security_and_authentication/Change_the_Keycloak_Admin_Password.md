# Change the Keycloak Admin Password

Update the default password for the admin Keycloak account using the Keycloak user interface (UI). After updating the password in
Keycloak, encrypt it on the system and verify that the change was made successfully.

- [System domain name](#system-domain-name)
- [Procedure](#procedure)

## System domain name

The `SYSTEM_DOMAIN_NAME` value found in some of the URLs on this page is expected to be the system's fully qualified domain name (FQDN).

The FQDN can be found by running the following command on any Kubernetes NCN.

```bash
ncn-mw# kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | yq r - spec.network.dns.external
```

Example output:

```text
system.hpc.amslabs.hpecorp.net
```

Be sure to modify the example URLs on this page by replacing `SYSTEM_DOMAIN_NAME` with the actual value found using the above command.

## Procedure

1. Log in to Keycloak with the default admin credentials.

    Point a browser at `https://auth.cmn.SYSTEM_DOMAIN_NAME/keycloak/admin`, replacing SYSTEM\_DOMAIN\_NAME with the actual NCN's
    DNS name. Use of the `auth.cmn.` sub-domain is required for administrative access to Keycloak.

    The following is an example URL for a system: `https://auth.cmn.system1.us.cray.com/keycloak/admin`

    Use the following admin login credentials:

    - Username: `admin`
    - The password can be obtained with the following command:

    ```bash
    ncn# kubectl get secret -n services keycloak-master-admin-auth \
                 --template={{.data.password}} | base64 --decode
    ```

1. Click the `Admin` drop-down menu in the upper-right corner of the page.

1. Select `Manage Account`.

1. Click the `Password` tab on the left side of the page.

1. Enter the existing password, new password and confirmation, and then click `Save`.

1. Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   - Name of chart to be redeployed: `cray-keycloak`
   - Base name of manifest: `platform`
   - When reaching the step to update customizations, perform the following steps:

      **Only follow these steps as part of the previously linked chart redeploy procedure.**

      1. Clone the CSM repository.

        ```bash
        ncn-w001# git clone https://github.com/Cray-HPE/csm.git
        ```

      1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

         ```bash
         ncn-w001# cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
         ```

      1. Change the password in the `customizations.yaml` file.

         In the `customizations.yaml` file, set the values for the `keycloak_master_admin_auth` keys in the
         `spec.kubernetes.sealed_secrets` field. The value in the data element where the name is `password` needs to be changed to the
         new Keycloak master admin password. The section below will replace the existing sealed secret data in the `customizations.yaml`
         file.

      1. Encrypt the values after changing the `customizations.yaml` file.

         ```bash
         ncn-w001# ./utils/secrets-seed-customizations.sh customizations.yaml
         ```

         If the above command complains that it cannot find `certs/sealed_secrets.crt` then you can run the following commands to create it:

         ```bash
         mkdir -pV certs && ./utils/bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > certs/sealed_secrets.crt
         ```

   - When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      Verify that the Secret has been updated.

      Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

      ```bash
      kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
      ```

   - **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**
