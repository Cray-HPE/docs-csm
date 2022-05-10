# Version Control Service \(VCS\)

The Version Control Service \(VCS\) includes a web interface for repository management, pull requests, and a visual view of all repositories and organizations. The following URL is for the VCS web interface:

`https://vcs.SHASTA_CLUSTER_DNS_NAME`

On cluster nodes, the VCS service can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository \(see the "VCS Administrative User" section below\). To clone a repository in the `cray` organization, use the following command:

```bash
ncn# git clone https://api-gw-service-nmn.local/vcs/cray/REPO_NAME.git
```

## VCS Administrative User

The Cray System Management \(CSM\) product installation creates the administrative user `crayvcs` that is used by CSM and other product installers to import their configuration content into VCS. The initial VCS credentials for the `crayvcs` user are obtained with the following command:

```bash
ncn# kubectl get secret -n services vcs-user-credentials \
--template={{.data.vcs_password}} | base64 --decode
```

The initial VCS login credentials for the `crayvcs` user are stored in three places:

* `vcs-user-credentials` Kubernetes secret: This is used to initialize the other two locations, as well as providing a place where other users can query for the password.
* VCS \(Gitea\): These credentials are used when pushing to Git using the default username and password. The password should be changed through the Gitea UI.
* Keycloak: These credentials are used to access the VCS UI. They must be changed through Keycloak. For more information on accessing Keycloak, see [Access the Keycloak User Management UI](../security_and_authentication/Access_the_Keycloak_User_Management_UI.md).

> **WARNING:** These three sources of credentials are not synced by any mechanism. Changing the default password requires that is it changed in all three places. Changing only one may result in difficulty determining the password at a later date, or may result in losing access to VCS altogether.

To change the password in the `vcs-user-credentials` Kubernetes secret, use the following command:

```bash
ncn# kubectl create secret generic vcs-user-credentials --save-config \
--from-literal=vcs_username="crayvcs" \
--from-literal=vcs_password="NEW_PASSWORD" \
--dry-run=client -o yaml | kubectl apply -f -
```

The `NEW_PASSWORD` value must be replaced with the updated password.

## Access the `cray` Gitea Organization

The VCS UI uses Keycloak to authenticate users on the system. However, users from external authentication sources are not automatically associated with permissions in the `cray` Gitea organization. As a result, users configured via Keycloak can log in and create organizations and repositories of their own, but they cannot modify the cray organization that is created during system installation unless they are given permissions to do so.

The `crayvcs` Gitea admin user that is created during CSM installation can log in to the UI via Keycloak. To allow users other than `crayvcs` to have access to repositories in the `cray` organization, use the following procedure:

1. Log in to VCS as the `crayvcs` user on the system:

   `https://vcs.SHASTA_CLUSTER_DNS_NAME`

2. Navigate to the `cray` organization owners page at the following location:

   `https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/cray/teams/owners`

3. Enter the username of the user who should have access to the organization in the **Search user...** text field, and click the **Add Team Member** button.

> **IMPORTANT** The "Owner" role has full access to all repositories in the organization, as well as administrative access to the organization, including the ability to create and delete repositories.

For granting non-administrative access to the organization and its repositories, create a new team at the following URL:

```text
https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams/new
```

Select the permissions appropriately, and then navigate to the following URL to add members to the newly created team:

```text
https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams
```

## Backup and Restore Data

Data for Gitea is stored in two places. Git content is stored directly in a PVC, while structural data, such as Gitea users and the list and attributes of repos, is stored in a Postgres database. Because of this, both sources must be backed up and restored together.

### Backup Postgres Data

1. Determine which Postgres member is the leader and exec into the leader pod to dump the data to a local file:

    ```bash
    ncn-w001# kubectl exec gitea-vcs-postgres-0 -n services -c postgres -it -- patronictl list
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

    ```bash
    ncn-w001# POSTGRES_LEADER=gitea-vcs-postgres-0

    ncn-w001# kubectl exec -it ${POSTGRES_LEADER} -n services -c postgres -- pg_dumpall -c -U postgres > gitea-vcs-postgres.sql
    ```

2. Determine what secrets are associated with the postgresql credentials:

    ```bash
    ncn-w001# kubectl get secrets -n services | grep gitea-vcs-postgres.credentials
    ```

    Example output:

    ```text
    postgres.gitea-vcs-postgres.credentials                   Opaque                                2      13d
    service-account.gitea-vcs-postgres.credentials            Opaque                                2      13d
    standby.gitea-vcs-postgres.credentials                    Opaque                                2      13d
    ```

3. Export each secret to a manifest file:

    ```bash
    ncn# SECRETS="postgres service-account standby"
    ncn# echo "---" > gitea-vcs-postgres.manifest
    ncn# for secret in $SECRETS; do
        kubectl get secret "${secret}.gitea-vcs-postgres.credentials" -n services -o yaml >> gitea-vcs-postgres.manifest
        echo "---" >> gitea-vcs-postgres.manifest
    done
    ```

4. Edit the manifest file to remove creationTimestamp, resourceVersion, selfLink, uid for each entry. Then, copy all files to a safe location.

### Backup PVC Data

The VCS postgres backups should be accompanied by backups of the VCS PVC. The export process can be run at any time while the service is running using the following commands:

Backup (save the resulting tar file to a safe location):

```bash
ncn# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn# kubectl -n services exec ${POD} -- tar -cvf vcs.tar /var/lib/gitea/
ncn# kubectl -n services cp ${POD}:vcs.tar ./vcs.tar
```

### Restore Postgres Data

Restoring VCS from Postgres is documented here: [Restore_Postgres.md](../../operations/kubernetes/Restore_Postgres.md#restore-postgres-for-vcs)

### Restore PVC Data

When restoring the VCS postgres database, the PVC should also be restored to the same point in time. The restore process can be run at any time while the service is running using the following commands:

Restore:

```bash
ncn# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn# kubectl -n services cp ./vcs.tar ${POD}:vcs.tar
ncn# kubectl -n services exec ${POD} -- tar -xvf vcs.tar
ncn# kubectl -n services rollout restart deployment gitea-vcs
```

### Alternative Backup/Restore Strategy

An alternative to the separate backups of the postgres and pvc data is to backup the git data. This has the advantage that only one backup is needed and that the git backups can be imported into any git server, not just gitea, but has the disadvantage that some information about the gitea deployment is lost (such as user/org information) and may need to be recreated manually if the VCS deployment is lost.

The following scripts create/use a `vcs-content` directory that contains all git data. This should be copied to a safe location after export, and moved back to the system before import.

Export:

```bash
ncn# RESULTS=vcs-content
ncn# mkdir $RESULTS
ncn# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn# git config --global credential.helper store
ncn# echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials
ncn# for repo in $(curl -s https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos -u ${VCS_USER}:${VCS_PASSWORD}| jq -r '.[] | .name') ; do
    git clone --mirror https://api-gw-service-nmn.local/vcs/cray/${repo}.git
    cd ${repo}.git
    git bundle create ${repo}.bundle --all
    cp ${repo}.bundle ../$RESULTS
    cd ..
    rm -r $repo.git
done
```

Import:

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

Prior to import, the repo structure may need to be recreated if it has not already been by an install. (Adjust the repo list as necessary if any additional are present. Repo settings such as public/private will also need to be manually set if this is used.)

```bash
ncn# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn# REPOS="analytics-config-management cos-config-management cpe-config-management slurm-config-management sma-config-management uan-config-management csm-config-management"
ncn# for repo in $REPOS ; do
   curl -X POST https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos -u ${VCS_USER}:${VCS_PASSWORD} -d name=${repo}
done
```
