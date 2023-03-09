# The Embedded Repository

The "embedded repo" is the complete set of packages installed on the Kubernetes and Storage Ceph NCN images,
as well as the packages found on the PIT ISO.
The list of installed packages in these images is queried when building each CSM release tarball,
and a repo is created from that list and included in the CSM release tarball.
This procedure describes how to manually install the "embedded repo" into Nexus.

## Manually import the Embedded Repository into Nexus

**Prerequisites:**

1. The `CSM_RELEASE` version is required and will be provided as the 1st parameter to the import script.
Example: `CSM_RELEASE="1.3.1"`

1. It is necessary to have an extracted copy of the CSM release tarball available at a known path in order to proceed. This path will be provided as the 2nd parameter to the import script.
Example: `PATH_TO_ROOT_OF_EXTRACTED_CSM_TARBALL_CONTENT="/mnt/pitdata/csm-1.3.1"`

Run the following command on a master node:

(`ncn-m#`)

```bash
/usr/share/doc/csm/scripts/operations/nexus/setup-embedded-repository.sh $CSM_RELEASE $PATH_TO_ROOT_OF_EXTRACTED_CSM_TARBALL_CONTENT
```

On the success, the above command will report:

```bash
+ Nexus setup complete
setup-embedded-repository.sh: OK
```

## Using the Embedded Repo

In order to access the packages in the embedded repo, it is necessary to add the repository to `zypper` on each of the NCNs it will be accessed from.

(`ncn-m#`)

```bash
zypper ar https://packages.local/repository/csm-${CSM_RELEASE}-embedded csm-embedded
```

## Using the Embedded Repo for NCN image customization and node personalization

In order to make the embedded repo available during NCN image customization and node personalization the `csm-config-management`
repository in Gitea needs a modification.

(`ncn-m#`)

1. Clone the `csm-config-management` repository

    ```bash
    VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
    VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    git clone "https://${VCS_USER}:${VCS_PASS}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    ```

1. Add the following lines to the `vars/csm_repos.yml` file in the `csm-config-management` repository:

    ```yaml
    - name: csm-embedded
      description: "CSM Embedded NCN Packages (added by Ansible)"
      repo: https://packages.local/repository/csm-embedded
    ```

1. Commit and push the change.
