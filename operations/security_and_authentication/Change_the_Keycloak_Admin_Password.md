# Change the Keycloak Admin Password

Update the default password for the admin Keycloak account using the Keycloak user interface (UI). After updating the password in Keycloak, encrypt it on the system and verify that the change was made successfully.

This procedure uses SYSTEM\_DOMAIN\_NAME as an example for the DNS name of the non-compute node (NCN). Replace this name with the actual NCN's DNS name while executing this procedure.

## Procedure

1. Log in to Keycloak with the default admin credentials.

    Point a browser at `https://auth.SYSTEM_DOMAIN_NAME/keycloak/admin`, replacing SYSTEM\_DOMAIN\_NAME with the actual NCN's DNS name.

    The following is an example URL for a system:

   ```screen
    auth.cmn.system1.us.cray.com/keycloak/admin
    ```

    Use the following admin login credentials:

    - Username: admin
    - The password can be obtained with the following command:

    ```bash
    ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```

1. Click the **Admin** drop-down menu in the upper-right corner of the page.
1. Select **Manage Account**.
1. Click the **Password** tab on the left side of the page.
1. Enter the existing password, new password and confirmation, and then click **Save**.
1. Log on to `ncn-w001`.
1. Download and extract the CSM tarball if you have not already done so.
1. Change your current directory to be where you've extracted the CSM install tarball
1. Save a local copy of the customizations.yaml file

    ```bash
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
    ```

1. Change the password in the customizations.yaml file.

    The Keycloak master admin password is also stored in the keycloak-master-admin-auth Secret in the services namespace. This needs to be updated so that clients that need to make requests as the master admin can authenticate with the new password.

    In the customizations.yaml file, set the values for the keycloak\_master\_admin\_auth keys in the spec.kubernetes.sealed\_secrets field. The value in the data element where the name is password needs to be changed to the new Keycloak master admin password. The section below will replace the existing sealed secret data in the customizations.yaml.

    For example:

    ```bash
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

1. Encrypt the values after changing the customizations.yaml file.

    ```bash
    ./utils/secrets-seed-customizations.sh customizations.yaml
    ```

    If the above command complaints that it cannot find certs/sealed_secrets.crt then you can run the following commands to create it

    ```bash
    mkdir -p certs
    ./utils/bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > certs/sealed_secrets.crt
    ```

1. Create a local copy of the platform.yaml file

    ```bash
    kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
    ```

1. Edit the platform.yaml to only include the cray-keycloak chart and all its current data.

    Example:

    ```bash
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
    ...
    ```

1. Generate the manifest that will be used to redeploy the chart with the modified resources.

    ```bash
    manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
    ```

1. Re-apply the cray-keycloak Helm chart with the updated customizations.yaml file.

    This will update the keycloak-master-admin-auth SealedSecret which will cause the SealedSecret controller to update the Secret.

    ```bash
    loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
    ```

1. Verify that the Secret has been updated.

    Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

    ```bash
    kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```

1. Save an updated copy of customizations.yaml to the site-init secret in the loftsman kubernetes namespace

    ```bash
    CUSTOMIZATIONS=$(base64 < customizations.yaml  | tr -d '\n')
    kubectl get secrets -n loftsman site-init -o json | \
    jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" | kubectl apply -f -
    ```
