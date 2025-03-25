# Version Control Service \(VCS\)

* [VCS web interface](#vcs-web-interface)
* [Cloning a VCS repository](#cloning-a-vcs-repository)
* [Git Operations](Git_Operations.md)
* [VCS Branching Strategy](VCS_Branching_Strategy.md)
* [Create and Populate a VCS Configuration Repository](Create_and_Populate_a_VCS_Configuration_Repository.md)
* [Update the Privacy Settings for Gitea Configuration Content Repositories](Update_the_Privacy_Settings_for_Gitea_Configuration_Content_Repositories.md)
* [VCS Administrative User](VCS_Administrative_User.md)
* [Access the `cray` Gitea organization](#access-the-cray-gitea-organization)
* [Backup and Restore VCS Data](Backup_and_Restore_VCS_Data.md)

## VCS web interface

The Version Control Service \(VCS\) includes a web interface for repository management, pull requests, and a visual view of all repositories and organizations. The following URL is for the VCS web interface:

`https://vcs.ext.system.domain.com`

(`ncn-mw#`) To look up the external system domain name, run the following command:

```bash
kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | grep "external:"
```

Example output:

```yaml
      external: ext.system.domain.com
```

## Cloning a VCS repository

On cluster nodes, the VCS service can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository \(see
[VCS Administrative User](VCS_Administrative_User.md)\).

(`ncn#`) To clone a repository in the `cray` organization, use the following command:

```bash
git clone https://api-gw-service-nmn.local/vcs/cray/REPO_NAME.git
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
