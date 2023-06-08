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

1. Log in to Keycloak with the default admin credentials.

    Point a browser at `https://auth.cmn.SYSTEM_DOMAIN_NAME/keycloak/admin`, replacing SYSTEM\_DOMAIN\_NAME with the actual NCN's
    DNS name. Use of the `auth.cmn.` sub-domain is required for administrative access to Keycloak.

    The following is an example URL for a system: `https://auth.cmn.system1.us.cray.com/keycloak/admin`

    Use the following admin login credentials:

    - Username: `admin`
    - (`ncn-mw#`) The password can be obtained with the following command:

    ```bash
    kubectl get secret -n services keycloak-master-admin-auth \
                 --template={{.data.password}} | base64 --decode
    ```

1. Click the `Admin` drop-down menu in the upper-right corner of the page.

1. Select `Manage Account`.

1. Click the `Password` tab on the left side of the page.

1. Enter the existing password, new password and confirmation, and then click `Save`.

1. Log on to `ncn-w001`.

1. (`ncn-w001#`) Run `git clone https://github.com/Cray-HPE/csm.git`.

1. (`ncn-w001#`) Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` to your desired working directory, and
   run the following commands from that work directory (not the `utils` directory).

1. (`ncn-w001#`) Save a local copy of the `customizations.yaml` file.

    ```bash
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' |
         base64 -d > customizations.yaml
    ```

1. (`ncn-w001#`) Change the password in the `customizations.yaml` file.

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

1. (`ncn-w001#`) Encrypt the values after changing the `customizations.yaml` file.

    ```bash
    ./utils/secrets-seed-customizations.sh customizations.yaml
    ```

    If the above command complains that it cannot find `certs/sealed_secrets.crt` then you can run the following commands to create it:

    ```bash
    mkdir -p certs &&
         ./utils/bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > certs/sealed_secrets.crt
    ```

1. (`ncn-w001#`) Upload the modified `customizations.yaml` file to Kubernetes.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. (`ncn-w001#`) Create a local copy of the `platform.yaml` file.

    ```bash
    kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
    ```

1. (`ncn-w001#`) Edit the `platform.yaml` to only include the `cray-keycloak` chart and all its current data.

    Example:

    ```yaml
    apiVersion: manifests/v1beta1
      metadata:
        name: platform
      spec:
        charts:
        - name: cray-keycloak
          namespace: services
          source: csm-algol60
          values:
            internalTokenUrl: https://api-gw-service-nmn.local/keycloak/realms/master/protocol/openid-connect/token
            sealedSecrets:
            - apiVersion: bitnami.com/v1alpha1
              kind: SealedSecret
              metadata:
                annotations:
                  sealedsecrets.bitnami.com/cluster-wide: 'true'
    ```

1. (`ncn-w001#`) Generate the manifest that will be used to redeploy the chart with the modified resources.

    ```bash
    manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
    ```

1. (`ncn-w001#`) Re-apply the `cray-keycloak` Helm chart with the updated `customizations.yaml` file.

    This will update the `keycloak-master-admin-auth` SealedSecret which will cause the SealedSecret controller to update the Secret.

    ```bash
    loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ./manifest.yaml
    ```

1. (`ncn-w001#`) Verify that the Secret has been updated.

    Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

    ```bash
    kubectl get secret -n services keycloak-master-admin-auth \
                 --template={{.data.password}} | base64 --decode
    ```

1. (`ncn-w001#`) Save an updated copy of `customizations.yaml` to the `site-init` secret in the `loftsman` Kubernetes namespace.

    ```bash
    CUSTOMIZATIONS=$(base64 < customizations.yaml  | tr -d '\n')
    kubectl get secrets -n loftsman site-init -o json |
            jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" |
            kubectl apply -f -
    ```
