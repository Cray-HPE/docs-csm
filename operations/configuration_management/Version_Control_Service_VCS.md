## Version Control Service \(VCS\)

The Version Control Service \(VCS\) includes a web interface for repository management, pull requests, and a visual view of all repositories and organizations. The following URL is for the VCS web interface:

```
https://vcs.SHASTA_CLUSTER_DNS_NAME
```

On cluster nodes, the VCS service can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository \(see the "VCS Administrative User" section below\). To clone a repository in the `cray` organization, use the following command:

```bash
ncn# git clone https://api-gw-service-nmn.local/vcs/cray/REPO\_NAME.git
```

### VCS Administrative User

The Cray System Management \(CSM\) product installation creates the administrative user `crayvcs` that is used by CSM and other product installers to import their configuration content into VCS. The initial VCS credentials for the `crayvcs` user are obtained with the following command:

```bash
ncn# kubectl get secret -n services vcs-user-credentials \
--template={{.data.vcs_password}} | base64 --decode
```

The initial VCS login credentials for the `crayvcs` user are stored in three places:

-   `vcs-user-credentials` Kubernetes secret: This is used to initialize the other two locations, as well as providing a place where other users can query for the password.
-   VCS \(Gitea\):  These credentials are used when pushing to Git using the default username and password. The password should be changed through the Gitea UI.
-   Keycloak: These credentials are used to access the VCS UI. They must be changed through Keycloak.

**Warning:** These 3 sources of credentials are not synced by any mechanism. Changing the default password requires that is it changed in all three places. Changing only one may result in difficulty determining the password at a later date, or may result in losing access to VCS altogether.

To change the password in the `vcs-user-credentials` Kubernetes secret, use the following command:

```bash
ncn# kubectl create secret generic vcs-user-credentials --save-config \
--from-literal=vcs_username="crayvcs"
--from-literal=vcs_password="NEW_PASSWORD" \
--dry-run -o yaml | kubectl apply -f -
```

The `NEW_PASSWORD` value must be replaced with the updated password.

### Access the `cray` Gitea Organization

The VCS UI uses Keycloak to authenticate users on the system. However, users from external authentication sources are not automatically associated with permissions in the `cray` Gitea organization. As a result, users configured via Keycloak can login and create organizations and repositories of their own, but they cannot modify the cray organization that is created during system installation unless they are given permissions to do so.

The `crayvcs` Gitea admin user that is created during CSM installation can login to the UI via Keycloak. To allow users other than `crayvcs` to have access to repositories in the `cray` organization, use the following procedure:

1.  Login to VCS as the `crayvcs` user on the system:

    ```screen
    https://vcs.SHASTA_CLUSTER_DNS_NAME
    ```

2.  Navigate to the `cray` organization owners page at

    ```screen
    https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/cray/teams/owners
    ```

3.  Enter the username of the user who should have access to the organization in the **Search user…** text field, and click the **Add Team Member** button.

**Important:** The "Owner" role has full access to all repositories in the organization, as well as administrative access to the organization, including the ability to create and delete repositories.

For granting non-administrative access to the organization and its repositories, create a new team at the following URL:

```screen
https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams/new
```

Select the permissions appropriately, and then navigate to the following URL to add members to the newly created team:

```screen
https://vcs.SHASTA_CLUSTER_DNS_NAME/vcs/org/cray/teams
```



