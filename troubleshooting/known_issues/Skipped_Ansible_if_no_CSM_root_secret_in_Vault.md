# Known Issue: Skipped Ansible if no CSM `root` secret in Vault

In CSM 1.2 through CSM 1.6, the `csm.ssh_keys` Ansible role calls
`end_play` if no CSM `root` secret is found in Vault. This causes the
rest of the play to be skipped, when really only that role should
be skipped.

## Fix

This issue is fixed and no longer exists starting in CSM 1.7.

## Workarounds

### Set CSM `root` secret

The easiest workaround is to set the CSM `root` secret in Vault. For more details, see
[Configure the `root` password and SSH keys in Vault](../../operations/CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md).

### Patch Ansible role

The other alternative is to manually patch the Ansible `csm.ssh_keys` Ansible role.
This is not recommended and should only be performed as a last resort.

1. (`ncn-mw#`) Find the latest CSM install on the system.

    ```bash
    kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
    ```

    Expected output will contain all the CSM versions that have been installed on the system.
    Take note of the most recent, which should contain a section similar to the following:

    ```yaml
      configuration:
        clone_url: https://vcs.cmn.wasp.dev.cray.com/vcs/cray/csm-config-management.git
        commit: 98c1b481dcaad5fc645f6e0d50411d88a23b6888
        import_branch: cray/csm/1.27.2
    ```

1. (`ncn-mw#`) Set a variable for the `configuration.import_branch` value from the most recent installed version,
   in this example `cray/csm/1.27.2`.

    ```bash
    CSM_IMPORT_BRANCH="cray/csm/1.27.2"
    ```

1. (`ncn-mw#`) Check out the `csm-config` Ansible plays.

    The Ansible plays for configuring images are stored in a git repository on the system. To check out
    the repository:

    ```bash
    VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
    VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    git clone https://$VCS_USER:$VCS_PASSWORD@api-gw-service-nmn.local/vcs/cray/csm-config-management.git
    ```

    Expected output will look something like:

    ```text
    Cloning into 'csm-config-management'...
    remote: Enumerating objects: 262, done.
    remote: Counting objects: 100% (262/262), done.
    remote: Compressing objects: 100% (96/96), done.
    remote: Total 262 (delta 90), reused 259 (delta 90), pack-reused 0
    Receiving objects: 100% (262/262), 64.19 KiB | 10.70 MiB/s, done.
    Resolving deltas: 100% (90/90), done.
    ```

1. (`ncn-mw#`) Set up a temporary branch based on the branch for the installed version of CSM.

    ```bash
    cd csm-config-management
    git checkout $CSM_IMPORT_BRANCH
    git checkout -b patch_branch
    ```

    Expected output will look something like:

    ```text
    # git checkout cray/csm/1.27.2
    branch 'cray/csm/1.27.2' set up to track 'origin/cray/csm/1.27.2'.
    Switched to a new branch 'cray/csm/1.27.2'
    # git checkout -b patch_branch
    Switched to a new branch 'patch_branch'
    ```

1. (`ncn-mw#`) Modify the `csm.ssh_keys` role to include
   [the bug fix from this PR](https://github.com/Cray-HPE/csm-config/pull/401/changes#diff-767152ca9403554e79a6cf82a12e09e8fd2965d261779e8411b8cac3e74f7ca3).

1. (`ncn-mw#`) Commit and push the changes.

    ```bash
    git commit -a -m "Remove inappropriate calls to end_play in csm.ssh_keys role"
    git push -u origin patch_branch
    ```

    Expected output will be something like:

    ```text
    # git commit -a -m "Remove inappropriate calls to end_play in csm.ssh_keys role"
    [patch_branch adc9dca] Remove inappropriate calls to end_play in csm.ssh_keys role
    3 files changed, 29 insertions(+), 7 deletions(-)
    # git push -u origin patch_branch
    Enumerating objects: 11, done.
    Counting objects: 100% (11/11), done.
    Delta compression using up to 32 threads
    Compressing objects: 100% (6/6), done.
    Writing objects: 100% (6/6), 755 bytes | 755.00 KiB/s, done.
    Total 6 (delta 4), reused 0 (delta 0), pack-reused 0
    remote: 
    remote: Create a new pull request for 'patch_branch':
    remote:   https://vcs.cmn.wasp.dev.cray.com/vcs/cray/csm-config-management/compare/main...patch_branch
    remote: 
    remote: . Processing 1 references
    remote: Processed 1 references in total
    To https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
    * [new branch]      patch_branch -> patch_branch
    branch 'patch_branch' set up to track 'origin/patch_branch'.
    ```

1. (`ncn-mw#`) Record the new commit ID for the patch changes.

    There is now a new commit ID for the patched version that needs to be used for customizing
    the remote build image. To get this new commit ID:

    ```bash
    git rev-parse HEAD
    ```

    Expected output will look something like:

    ```text
    adc9dca4255fea61402013c4b7a2089f61e95421
    ```

1. Modify relevant CFS configurations to use the new commit ID.

    See [Update a CFS Configuration](../../operations/configuration_management/Update_a_CFS_Configuration.md) for details.
