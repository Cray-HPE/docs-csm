# Access the Keycloak User Management UI

This procedure can be used to access the interface to manage Keycloak users. Users can be added with this interface.
See [Create Internal User Accounts in the Keycloak Shasta Realm](Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md).

## Prerequisites

- This procedure uses `SYSTEM_DOMAIN_NAME` as an example for the DNS name of the non-compute node \(NCN\). Replace this name with the actual NCN's DNS name while executing this procedure.
- This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process.
  - (`ncn-mw#`) The password can be obtained with the following command:

      ```bash
      kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
      ```

## Procedure

1. Point a browser at `https://auth.cmn.SYSTEM_DOMAIN_NAME/keycloak/`, replacing `SYSTEM_DOMAIN_NAME` with the actual NCN's DNS name.

    The following is an example URL for a system: `https://auth.cmn.system1.us.cray.com/keycloak/`

    The browser may return an error message similar to the following when `auth.cmn.SYSTEM_DOMAIN_NAME/keycloak` is launched for the first time:

    ```text
    This Connection Is Not Private

    This website may be impersonating "hostname" to steal your personal or financial information.
    You should go back to the previous page.
    ```

    See [Make HTTPS Requests from Sources Outside the Management Kubernetes Cluster](Make_HTTPS_Requests_from_Sources_Outside_the_Management_Kubernetes_Cluster.md)
    for more information on getting the Certificate Authority \(CA\) certificate on the system.

1. Click the `Administration Console` link.

1. Log in as the `admin` user for the `Master` realm.

1. Ensure that the selected `Realm` is `Shasta`.

1. Click the `Users` link under the `Manage` menu on the left side of the screen.

    New users can be added with this interface. See [Create Internal User Accounts in the Keycloak Shasta Realm](Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md).
