# Version Control Service \(VCS\)

* [VCS overview](#vcs-overview)
* [Cloning a VCS repository](#cloning-a-vcs-repository)
* [Git Operations](Git_Operations.md)
* [VCS Branching Strategy](VCS_Branching_Strategy.md)
* [Create and Populate a VCS Configuration Repository](Create_and_Populate_a_VCS_Configuration_Repository.md)
* [Update the Privacy Settings for Gitea Configuration Content Repositories](Update_the_Privacy_Settings_for_Gitea_Configuration_Content_Repositories.md)
* [VCS administrative user](#vcs-administrative-user)
  * [Change VCS administrative user password](#change-vcs-administrative-user-password)
* [Access the `cray` Gitea organization](#access-the-cray-gitea-organization)
* [Backup and Restore VCS Data](Backup_and_Restore_VCS_Data.md)

## VCS overview

The Version Control Service \(VCS\) includes a web interface for repository management, pull requests, and a visual view of all repositories and organizations. The following URL is for the VCS web interface:

`https://vcs.ext.system.domain.com`

To look up the external system domain name, run the following command:

```bash
ncn-mw# kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | grep "external:"
```

Example output:

```yaml
      external: ext.system.domain.com
```

## Cloning a VCS repository

On cluster nodes, the VCS service can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository \(see
[VCS administrative user](#vcs-administrative-user) below\).

To clone a repository in the `cray` organization, use the following command:

```bash
ncn# git clone https://api-gw-service-nmn.local/vcs/cray/REPO_NAME.git
```

<a name="vcs_administrative_user"></a>

## VCS administrative user

The Cray System Management \(CSM\) product installation creates the administrative user `crayvcs` that is used by CSM and other product installers to import their configuration
content into VCS.

The initial VCS credentials for the `crayvcs` user are obtained with the following command:

```bash
ncn-mw# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
```

### Change VCS administrative user password

The initial VCS login credentials for the `crayvcs` user are stored in three places:

* `vcs-user-credentials` Kubernetes secret: This is used to initialize the other two locations, as well as providing a place where other users can query for the password.
* VCS \(Gitea\): These credentials are used when pushing to Git using the default username and password. The password should be changed through the Gitea UI.
* Keycloak: These credentials are used to access the VCS UI. They must be changed through Keycloak. For more information on accessing Keycloak, see
  [Access the Keycloak User Management UI](../security_and_authentication/Access_the_Keycloak_User_Management_UI.md).

> **WARNING:** These three sources of credentials are not synced by any mechanism. Changing the default password requires that is it changed in all three places. Changing only
> one may result in difficulty determining the password at a later date, or may result in losing access to VCS altogether.

To change the password in the `vcs-user-credentials` Kubernetes secret, use the following procedure:

1. Log in to Keycloak with the default `admin` credentials.

   Point a browser at `https://auth.SYSTEM_DOMAIN_NAME/keycloak/admin`, replacing `SYSTEM_DOMAIN_NAME` with the actual NCN's DNS name.

   The following is an example URL for a system: `https://auth.system1.us.cray.com/keycloak/admin`

   Use the following `admin` login credentials:

   * Username: `admin`
   * The password can be obtained with the following command:

     ```bash
     ncn-mw# kubectl get secret -n services keycloak-master-admin-auth \
                     --template={{.data.password}} | base64 --decode
     ```

1. Ensure the selected Realm is `Shasta` from the top-left dropdown in the left sidebar.

1. From the left sidebar, under the `Manage` section, select `Users`.

1. In the `Search...` textbox, type in `crayvcs` and click the search icon.

1. In the filtered table below, click on the ID for the row that shows `crayvcs` in the `Username` column.

1. Go to the `Credentials` tab and change the password.

   Enter the new password in the `Reset Password` form. Ensure `Temporary` is switched **off**. Click on `Reset Password` button.

1. Log in to Gitea with the default `admin` credentials.

   Point the browser at `https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/user/settings/account`.

   If presented with Keycloak login, use `crayvcs` as the username and the new VCS password. Wait to be redirected to the Gitea login page before continuing to the next step.

1. Use the following Gitea login credentials:

   * Username: `crayvcs`
   * The old VCS password, which can be obtained with the following command:

     ```bash
     ncn-mw# kubectl get secret -n services vcs-user-credentials \
                     --template={{.data.vcs_password}} | base64 --decode
     ```

1. Enter the existing password (from previous step), new password, and confirmation, and then click `Update Password`.

1. SSH into `ncn-w001` or `ncn-m001`.

1. Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   * Name of chart to be redeployed: `gitea`
   * Base name of manifest: `sysmgmt`
   * When reaching the step to update customizations, perform the following steps:

      **Only follow these steps as part of the previously linked chart redeploy procedure.**

      1. Clone the CSM repository.

         ```bash
         ncn-mw# git clone https://github.com/Cray-HPE/csm.git
         ```

      1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

         ```bash
         ncn-mw# cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
         ```

      1. Change the password in the `customizations.yaml` file.

         The Gitea `crayvcs` password is stored in the `vcs-user-credentials` Kubernetes Secret in the `services` namespace. This must be updated so that clients which need to make requests can authenticate with the new password.

         In the `customizations.yaml` file, set the values for the `gitea` keys in the `spec.kubernetes.sealed_secrets` field.
         The value in the data element where the name is `password` needs to be changed to the new Gitea password. The section
         below will replace the existing sealed secret data in the `customizations.yaml` file.

         For example:

         ```yaml
         gitea:
            generate:
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
         ncn-mw# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
         ```

      1. Run a VCS health check.

         ```bash
         /usr/local/bin/cmsdev test -q vcs
         ```

         For more details on this test, including known issues and other command line options, see [Software Management Services health checks](../validate_csm_health.md#3-software-management-services-health-checks).

   * **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**

## Access the `cray` Gitea organization

The VCS UI uses Keycloak to authenticate users on the system. However, users from external authentication sources are not automatically associated with permissions in the `cray`
Gitea organization. As a result, users configured via Keycloak can log in and create organizations and repositories of their own, but they cannot modify the `cray` organization
that is created during system installation, unless they are given permissions to do so.

The `crayvcs` Gitea `admin` user that is created during CSM installation can log in to the UI via Keycloak. To allow users other than `crayvcs` to have access to repositories in
the `cray` organization, use the following procedure:

1. Log in to VCS as the `crayvcs` user on the system.

   URL: `https://vcs.SHASTA_CLUSTER_DNS_NAME`

1. Navigate to the `cray` organization owners page.

   URL: `https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/cray/teams/owners`

1. Enter the username of the user who should have access to the organization in the `Search user...` text field, and click the `Add Team Member` button.

> **IMPORTANT** The `Owner` role has full access to all repositories in the organization, as well as administrative access to the organization, including the ability to create and delete repositories.

For granting non-administrative access to the organization and its repositories, create a new team at the following URL:

`https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams/new`

Select the permissions appropriately, and then navigate to the following URL to add members to the newly created team:

`https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams/NEWTEAM`

[`operations/configuration_management/Version_Control_Service_VCS.md`](#backup-and-restore-data)

[`operations/configuration_management/Version_Control_Service_VCS.md`](#vcs-administrative-user)
