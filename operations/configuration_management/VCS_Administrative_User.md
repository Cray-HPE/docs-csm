# VCS Administrative User

> For additional information on the Version Control Service (VCS), see [Version Control Service (VCS)](Version_Control_Service_VCS.md).

* [Administrative user credentials](#administrative-user-credentials)
* [Retrieving password for administrative user](#retrieving-password-for-administrative-user)
* [Change VCS administrative user password](#change-vcs-administrative-user-password)
    1. [Prerequisites](#1-prerequisites)
    1. [Change password in Keycloak](#2-change-password-in-keycloak)
    1. [Change password in Gitea/VCS](#3-change-password-in-giteavcs)
        * [Change password in Gitea/VCS using web interface](#change-password-in-giteavcs-using-web-interface)
        * [Change password in Gitea/VCS using command line](#change-password-in-giteavcs-using-command-line)
    1. [Change password in the `vcs-user-credentials` Kubernetes secret](#4-change-password-in-the-vcs-user-credentials-kubernetes-secret)

The Cray System Management \(CSM\) product installation creates the administrative user `crayvcs` that is used by CSM and other product
installers to import their configuration content into VCS.

## Administrative user credentials

The VCS login credentials for the `crayvcs` user are stored in three places:

* `vcs-user-credentials` Kubernetes secret: This is used to initialize the other two locations, as well as providing a place where other users can query for the password.
* VCS \(Gitea\): These credentials are used when pushing to Git using the default username and password. The password should be changed through the Gitea UI or command-line.
* Keycloak: These credentials are used to access the VCS UI. They must be changed through Keycloak. For more information on accessing Keycloak, see
  [Access the Keycloak User Management UI](../security_and_authentication/Access_the_Keycloak_User_Management_UI.md).

> **WARNING:** These three sources of credentials are not synced by any mechanism. Changing the default password requires that is it changed in all three places. Changing only
> one may result in difficulty determining the password at a later date, or may result in losing access to VCS altogether.

## Retrieving password for administrative user

(`ncn-mw#`) The following command retrieves and decodes the VCS administrative user password from the `vcs-user-credentials` secret.

```bash
kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
```

## Change VCS administrative user password

The following procedure shows how to change the VCS password in all necessary locations.

### 1. Prerequisites

* Obtain the current VCS administrative user password. See [Retrieving password for administrative user](#retrieving-password-for-administrative user).
  In this procedure, this password will be referred to as the "old" password.
* Choose a new password. This password should follow the URL and filename safe base 64 alphabet: alphanumeric characters, dash/minus (`-`), and underscore (`_`).

### 2. Change password in Keycloak

> This procedure uses the Keycloak web interface to change the password. This can also be done on the command line. See the
> [Update a Local Keycloak User Credential](../security_and_authentication/Keycloak_User_Management_with_Kcadm.md#update-a-local-keycloak-user-credential)
> procedure in [Keycloak User Management with `Kcadm`](../security_and_authentication/Keycloak_User_Management_with_Kcadm.md).

1. Log in to Keycloak with the default `admin` credentials.

   See [Access the Keycloak User Management UI](../security_and_authentication/Access_the_Keycloak_User_Management_UI.md).

1. Ensure the selected Realm is `Shasta` from the top-left dropdown in the left sidebar.

1. From the left sidebar, under the `Manage` section, select `Users`.

1. In the `Search...` textbox, type in `crayvcs` and click the search icon.

1. In the filtered table below, click on the ID for the row that shows `crayvcs` in the `Username` column.

1. Go to the `Credentials` tab and change the password.

   Enter the new password in the `Reset Password` form. Ensure `Temporary` is switched **off**. Click on `Reset Password` button.

### 3. Change password in Gitea/VCS

This can be done either using the VCS web interface, or using the command line.

#### Change password in Gitea/VCS using web interface

1. Log in to Gitea with the default `admin` credentials.

   Point the browser at `https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/user/settings/account`.

   If presented with Keycloak login, use `crayvcs` as the username and the new VCS password. Wait to be redirected to the Gitea login page before continuing to the next step.

1. Use the following Gitea login credentials:

   * Username: `crayvcs`
   * The old VCS password

1. Enter the old password, new password, and confirmation, and then click `Update Password`.

#### Change password in Gitea/VCS using command line

1. (`ncn-mw#`) Identify the Gitea/VCS pod.

    ```bash
    POD=$(kubectl get pods -n services -l app.kubernetes.io/instance=gitea --no-headers | grep -w Running | awk '{ print $1 }') ; echo ${POD}
    ```

    Expected output should resemble the following:

    ```text
    gitea-vcs-6554bbd88f-fml62
    ```

1. (`ncn-mw#`) Open an interactive shell into the pod.

    ```bash
    kubectl exec -it -n services "${POD}" -- sh
    ```

1. (`pod#`) Update Gitea/VCS with the new password.

    > `read -s` is used to read the password in order to prevent it from being echoed to the screen or saved in the shell history.

    ```bash
    USERNAME=crayvcs
    cd /var/lib/gitea/custom
    read -r -s -p "Enter new Gitea/VCS administrative password: " PW1 ; echo ; if [[ -z ${PW1} ]]; then
        echo "ERROR: Password cannot be blank"
    elif ! [[ $PW1 =~ ^[-_a-zA-Z0-9]+$ ]]; then
        echo "ERROR: Password contains illegal characters. Must only contain alphanumeric, dash/minus, and underscores."
    else
        read -r -s -p "Enter again: " PW2
        echo
        if [[ ${PW1} != ${PW2} ]]; then
            echo "ERROR: Passwords do not match"
        else
            echo "Changing password for '${USERNAME}'"
            if /usr/local/bin/gitea admin user change-password --config /var/lib/gitea/app.ini --username "${USERNAME}" --password "${PW1}" ; then
                echo "SUCCESS"
            else
                echo "ERROR" 1>&2
            fi
        fi
    fi; unset PW1 PW2 USERNAME
    ```

    On success, the end of the output will resemble the following:

    ```text
    crayvcs's password has been successfully updated!
    SUCCESS
    ```

1. (`pod#`) Exit the pod.

    ```bash
    exit
    ```

### 4. Change password in the `vcs-user-credentials` Kubernetes secret

(`ncn-mw#`) Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

* Name of chart to be redeployed: `gitea`
* Base name of manifest: `sysmgmt`
* When reaching the step to update customizations, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    > This procedure gets a copy of the `shasta-cfg/stable/utils` directory from `github`. If this procedure is being followed when
    > the PIT node or expanded CSM release tarball is still available, then this directory can copied from those instead.

    1. Run `git clone https://github.com/Cray-HPE/csm.git -b release/1.5`.

    1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

        ```bash
        cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
        ```

    1. Change the password in the `customizations.yaml` file.

        The Gitea `crayvcs` password is stored in the `vcs-user-credentials` Kubernetes Secret in the `services` namespace.
        This must be updated so that clients which need to make requests can authenticate with the new password.

        > These commands make use of the `$CUSTOMIZATIONS` variable that is set earlier in the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure.

        1. Delete the current Gitea sealed secret data from `customizations.yaml`.

            ```bash
            yq delete -i "${CUSTOMIZATIONS}" spec.kubernetes.sealed_secrets.gitea
            ```

        1. Verify that the Gitea sealed secret data is not present.

            The following command should return no output.

            ```bash
            yq r "${CUSTOMIZATIONS}" spec.kubernetes.sealed_secrets.gitea
            ```

        1. Create a YAML file with the new password.

            Create a file named `new_gitea_pw.yaml` with the following contents, replacing `my_secret_password` with the new Gitea password.

            ```yaml
            name: vcs-user-credentials
            data:
              - type: static
                args:
                  name: vcs_password
                  value: my_secret_password
              - type: static
                args:
                  name: vcs_username
                  value: crayvcs
            ```

        1. Update `customizations.yaml` with the new password.

            The following command should return no output.

            ```bash
            yq w -i "${CUSTOMIZATIONS}" -f new_gitea_pw.yaml spec.kubernetes.sealed_secrets.gitea.generate
            ```

        1. Verify that updates were successfully applied.

            The following command should return the contents of the `new_gitea_pw.yaml` file.

            ```bash
            yq r "${CUSTOMIZATIONS}" spec.kubernetes.sealed_secrets.gitea.generate
            ```

        1. Delete `new_gitea_pw.yaml`.

            ```bash
            rm new_gitea_pw.yaml
            ```

    1. Encrypt the values after changing the `customizations.yaml` file.

        > This command makes use of the `$CUSTOMIZATIONS` variable that is set earlier in the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure.

        ```bash
        ./utils/secrets-seed-customizations.sh "${CUSTOMIZATIONS}"
        ```

        If the above command complains that it cannot find `certs/sealed_secrets.crt`, then run the following commands to create it:

        ```bash
        mkdir -pv ./certs && ./utils/bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > ./certs/sealed_secrets.crt
        ```

* When reaching the step to validate that the redeploy was successful, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    1. Verify that the Secret has been updated.

        Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

        ```bash
        kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
        ```

    1. Do a rolling restart of the Gitea/VCS service and wait for it to complete.

        ```bash
        kubectl rollout restart -n services deployment gitea-vcs && kubectl rollout status -n services deployment gitea-vcs && echo SUCCESS || echo ERROR
        ```

        On success, the output should end with `SUCCESS`.

    1. Run a VCS health check.

        ```bash
        /usr/local/bin/cmsdev test -q vcs
        ```

        For more details on this test, including known issues and other command line options, see [Software Management Services health checks](../../troubleshooting/known_issues/sms_health_check.md).

* **Make sure to perform the entire linked chart redeploy procedure, including the step to save the updated customizations.**
