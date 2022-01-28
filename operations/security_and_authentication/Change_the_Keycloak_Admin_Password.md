## Change the Keycloak Admin Password

Update the default password for the admin Keycloak account using the Keycloak user interface \(UI\). After updating the password in Keycloak, encrypt it on the system and verify that the change was made successfully.

This procedure uses SYSTEM\_DOMAIN\_NAME as an example for the DNS name of the non-compute node \(NCN\). Replace this name with the actual NCN's DNS name while executing this procedure.

### Procedure

1.  Log in to Keycloak with the default admin credentials.

    Point a browser at https://auth.SYSTEM_DOMAIN_NAME/keycloak/admin, replacing SYSTEM\_DOMAIN\_NAME with the actual NCN's DNS name.

    The following is an example URL for a system:

    ```
    auth.system1.us.cray.com/keycloak/admin
    ```

    Use the following admin login credentials:

    -   Username: admin
    -   The password can be obtained with the following command:

        ```bash
        ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
        --template={{.data.password}} | base64 --decode
        ```

2.  Click the **Admin** drop-down menu in the upper-right corner of the page.

3.  Select **Manage Account**.

4.  Click the **Password** tab on the left side of the page.

5.  Enter the existing password, new password and confirmation, and then click **Save**.

6.  Log on to `ncn-w001`.

7.  Change the password in the customizations.yaml file.

    The Keycloak master admin password is also stored in the keycloak-master-admin-auth Secret in the services namespace. This needs to be updated so that clients that need to make requests as the master admin can authenticate with the new password.

    In the customizations.yaml file, set the values for the keycloak\_master\_admin\_auth keys in the spec.kubernetes.sealed\_secrets field. The value in the data element where the name is password needs to be changed to the new Keycloak master admin password.

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

8.  Encrypt the values after changing the customizations.yaml file.

    ```bash
    ncn-w001# utils/secrets-seed-customizations.sh customizations.yaml
    ```

9.  Re-apply the cray-keycloak Helm chart with the updated customizations.yaml file.

    This will update the keycloak-master-admin-auth SealedSecret which will cause the SealedSecret controller to update the Secret.

10. Verify that the Secret has been updated.

    Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

    ```bash
    ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```



