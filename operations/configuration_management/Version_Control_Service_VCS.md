# Version Control Service \(VCS\)

The Version Control Service \(VCS\) includes a web interface for repository management, pull requests, and a visual view of all repositories and organizations. The following URL is for the VCS web interface:

`https://vcs.SHASTA_CLUSTER_DNS_NAME`

## Cloning a VCS repository

On cluster nodes, the VCS service can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository \(see
[VCS administrative user](#vcs_administrative_user) below\).

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
ncn# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
```

## Change VCS administrative user password

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

   The following is an example URL for a system: `https://auth.cmn.system1.us.cray.com/keycloak/admin`

   Use the following `admin` login credentials:

   * Username: `admin`
   * The password can be obtained with the following command:

     ```bash
     ncn# kubectl get secret -n services keycloak-master-admin-auth \
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
     ncn# kubectl get secret -n services vcs-user-credentials \
             --template={{.data.vcs_password}} | base64 --decode
     ```

1. Enter the existing password (from previous step), new password, and confirmation, and then click `Update Password`.
1. Now SSH into `ncn-w001` or `ncn-m001`.
1. Run `git clone https://github.com/Cray-HPE/csm.git`.
1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` to the desired working directory.
1. Change directories to be in the working directory set in the previous step.
1. Save a local copy of the `customizations.yaml` file.

    ```bash
    ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' |
         base64 -d > customizations.yaml
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

1. Upload the modified `customizations.yaml` file to Kubernetes.

   ```bash
   ncn# kubectl delete secret -n loftsman site-init
   ncn# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Encrypt the values after changing the `customizations.yaml` file.

    ```bash
    ncn# ./secrets-seed-customizations.sh customizations.yaml
    ```

   If the above command complains that it cannot find `certs/sealed_secrets.crt`, then you can run the following commands to create it:

    ```bash
    ncn# mkdir -p ../certs &&
         ./bin/linux/kubeseal --controller-name sealed-secrets --fetch-cert > ../certs/sealed_secrets.crt
    ```

1. Get the current cached `sysmgmt` manifest and save it into a `gitea.yaml` file.

    ```bash
    ncn# kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}'  > gitea.yaml
    ```

1. Run the following command to remove non-Gitea charts from the `gitea.yaml` file. This will also change the `metadata.name` so
   that it does not overwrite the `sysmgmt.yaml` file that is stored in the `loftsman` namespace.

   ```bash
   ncn# for i in $(yq r gitea.yaml 'spec.charts[*].name' | grep -Ev '^gitea'); do yq d -i gitea.yaml  'spec.charts(name=='"$i"')'; done
   ncn# yq w -i gitea.yaml metadata.name gitea
   ncn# yq d -i gitea.yaml spec.sources
   ncn# yq w -i gitea.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
   ncn# yq w -i gitea.yaml spec.sources.charts[0].name csm-algol60
   ncn# yq w -i gitea.yaml spec.sources.charts[0].type repo
   ```

1. Example `gitea.yaml` after the command is run:

   Example:

    ```yaml
    apiVersion: manifests/v1beta1
      metadata:
        name: sysmgmt
      spec:
        charts:
          - name: gitea
            namespace: services
            source: csm-algol60
            values:
              cray-service:
                sealedSecrets:
                - apiVersion: bitnami.com/v1alpha1
                  kind: SealedSecret
                  metadata:
                    annotations:
                      sealedsecrets.bitnami.com/cluster-wide: 'true'
                      ...
        sources:
          charts:
            - location: https://packages.local/repository/charts
              name: csm-algol60
              type: repo
    ...
    ```

1. Generate the manifest that will be used to redeploy the chart with the modified resources.

    ```bash
    ncn# manifestgen -c customizations.yaml -i gitea.yaml -o manifest.yaml
    ```

1. Validate that the `manifest.yaml` file only contains chart information for Gitea, and that the sources chart location
   points to `https://packages.local/repository/charts`.

1. Re-apply the `gitea` Helm chart with the updated `customizations.yaml` file.

   This will update the `vcs-user-credentials` SealedSecret which will cause the SealedSecret controller to update the Secret.

    ```bash
    ncn# loftsman ship --manifest-path ${PWD}/manifest.yaml
    ```

1. Verify that the Secret has been updated.

   Give the SealedSecret controller a few seconds to update the Secret, then run the following command to see the current value of the Secret:

    ```bash
    ncn# kubectl get secret -n services vcs-user-credentials \
                 --template={{.data.vcs_password}} | base64 --decode
    ```

1. Save an updated copy of `customizations.yaml` to the `site-init` secret in the `loftsman` Kubernetes namespace.

    ```bash
    ncn# CUSTOMIZATIONS=$(base64 < customizations.yaml  | tr -d '\n')
    ncn# kubectl get secrets -n loftsman site-init -o json |
            jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" |
            kubectl apply -f -
    ```

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

## Backup and restore data

Data for Gitea is stored in two places: Git content is stored directly in a PVC, while structural data, such as Gitea users and the list and attributes of repositories, is stored
in a Postgres database. Because of this, both sources must be backed up and restored together.

### Backup Postgres data

1. Determine which Postgres member is the leader.

    ```bash
    ncn# kubectl exec gitea-vcs-postgres-0 -n services -c postgres -it -- patronictl list
    ```

    Example output:

    ```text
    + Cluster: gitea-vcs-postgres (6995618180238446669) -----+----+-----------+
    |        Member        |     Host     |  Role  |  State  | TL | Lag in MB |
    +----------------------+--------------+--------+---------+----+-----------+
    | gitea-vcs-postgres-0 |  10.45.0.21  | Leader | running |  1 |           |
    | gitea-vcs-postgres-1 | 10.46.128.19 |        | running |  1 |         0 |
    | gitea-vcs-postgres-2 |  10.47.0.21  |        | running |  1 |         0 |
    +----------------------+--------------+--------+---------+----+-----------+
    ```

1. Log into the leader pod and dump the data to a local file.

    ```bash
    ncn# POSTGRES_LEADER=gitea-vcs-postgres-0
    ncn# kubectl exec -it ${POSTGRES_LEADER} -n services -c postgres -- pg_dumpall -c -U postgres > gitea-vcs-postgres.sql
    ```

1. Determine what secrets are associated with the PostgreSQL credentials:

    ```bash
    ncn# kubectl get secrets -n services | grep gitea-vcs-postgres.credentials
    ```

    Example output:

    ```text
    postgres.gitea-vcs-postgres.credentials                   Opaque                                2      13d
    service-account.gitea-vcs-postgres.credentials            Opaque                                2      13d
    standby.gitea-vcs-postgres.credentials                    Opaque                                2      13d
    ```

1. Export each secret to a manifest file:

    ```bash
    ncn# SECRETS="postgres service-account standby"
    ncn# echo "---" > gitea-vcs-postgres.manifest
    ncn# for secret in $SECRETS; do
            kubectl get secret "${secret}.gitea-vcs-postgres.credentials" -n services -o yaml >> gitea-vcs-postgres.manifest
            echo "---" >> gitea-vcs-postgres.manifest
         done
    ```

1. Edit the manifest file to remove `creationTimestamp`, `resourceVersion`, `selfLink`, and `uid` for each entry.

1. Copy all files to a safe location.

### Backup PVC data

The VCS Postgres backups should be accompanied by backups of the VCS PVC. The export process can be run at any time while the service is running using the following commands:

```bash
ncn# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn# kubectl -n services exec ${POD} -- tar -cvf vcs.tar /var/lib/gitea/
ncn# kubectl -n services cp ${POD}:vcs.tar ./vcs.tar
```

Be sure to save the resulting `tar` file to a safe location.

### Restore Postgres data

See [Restore Postgres for VCS](../../operations/kubernetes/Restore_Postgres.md#restore-postgres-for-vcs).

### Restore PVC data

When restoring the VCS Postgres database, the PVC should also be restored to the same point in time. The restore process can be run at any time while the service is running
using the following commands:

```bash
ncn# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn# kubectl -n services cp ./vcs.tar ${POD}:vcs.tar
ncn# kubectl -n services exec ${POD} -- tar -xvf vcs.tar
ncn# kubectl -n services rollout restart deployment gitea-vcs
```

### Alternative backup/restore strategy

An alternative to the separate backups of the Postgres and PVC data is to backup the Git data. This has the advantage that only one backup is needed and that the Git backups can
be imported into any Git server, not just Gitea. This has the disadvantage that some information about the Gitea deployment is lost (such as user and organization information)
and may need to be recreated manually if the VCS deployment is lost.

The following scripts create and use a `vcs-content` directory that contains all Git data. This should be copied to a safe location after export, and moved back to the system before import.

#### Export

> **WARNING:** The following example uses the VCS `admin` username and password in plaintext on the command line, meaning it will be stored in the shell history as
> well as be visible to all users on the system in the process table. These dangers can be avoided by modifying or replacing the `curl` command (such as
> supplying the credentials to `curl` using the `--netrc-file` argument instead of the `--user` argument, or replacing it with a simple Python script).

```bash
ncn# RESULTS=vcs-content
ncn# mkdir $RESULTS
ncn# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn# git config --global credential.helper store
ncn# echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials
ncn# for repo in $(curl -s https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos --user ${VCS_USER}:${VCS_PASSWORD}| jq -r '.[] | .name') ; do
        git clone --mirror https://api-gw-service-nmn.local/vcs/cray/${repo}.git
        cd ${repo}.git
        git bundle create ${repo}.bundle --all
        cp ${repo}.bundle ../$RESULTS
        cd ..
        rm -r $repo.git
     done
```

#### Import

```bash
ncn# SOURCE=vcs-content
ncn# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn# git config --global credential.helper store
ncn# echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials
ncn# for file in $(ls $SOURCE); do
        repo=$(echo $file | sed 's/.bundle$//')
        git clone --mirror ${SOURCE}/${repo}.bundle
        cd ${repo}.git
        git remote set-url origin https://api-gw-service-nmn.local/vcs/cray/${repo}.git
        git push
        cd ..
        rm -r ${repo}.git
     done
```

Prior to import, the repository structure may need to be recreated if it has not already been by an install.

Adjust the repository list as necessary, if any additional repositories are present. Repository settings such as `public` or `private` will also need to be manually set, if applicable.

For example:

> **WARNING:** The following example uses the VCS `admin` username and password in plaintext on the command line, meaning it will be stored in the shell history as
> well as be visible to all users on the system in the process table. These dangers can be avoided by modifying or replacing the `curl` command (such as
> supplying the credentials to `curl` using the `--netrc-file` argument instead of the `--user` argument, or replacing it with a simple Python script).

```bash
ncn# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn# REPOS="analytics-config-management cos-config-management cpe-config-management slurm-config-management sma-config-management uan-config-management csm-config-management"
ncn# for repo in $REPOS ; do
        curl -X POST https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos -u ${VCS_USER}:${VCS_PASSWORD} -d name=${repo}
     done
```
