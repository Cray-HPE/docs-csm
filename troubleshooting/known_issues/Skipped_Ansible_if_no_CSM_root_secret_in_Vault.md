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
    Take note of the most recent, which should look similar to the following:

    ```yaml
    1.6.0:
      configuration:
        clone_url: https://vcs.cmn.wasp.dev.cray.com/vcs/cray/csm-config-management.git
        commit: 98c1b481dcaad5fc645f6e0d50411d88a23b6888
        import_branch: cray/csm/1.27.2
        import_date: 2024-10-31 19:41:50.149479
        ssh_url: git@vcs.cmn.wasp.dev.cray.com:cray/csm-config-management.git
      images:
        compute-csm-1.6-6.2.25-aarch64:
          id: 77fd5282-0a22-44ac-a3cb-60efb6e36035
        compute-csm-1.6-6.2.25-x86_64:
          id: 3a507f20-db8b-475a-851c-214a5acda6e4
        cray-shasta-csm-sles15sp6-barebones-csm-1.6:
          id: 7c8061d1-301d-4a27-8a5c-d837acc5392e
        secure-kubernetes-6.2.30-x86_64.squashfs:
          id: 7b3cb5e3-736c-4722-98c2-6081af2c0a95
        secure-storage-ceph-6.2.30-x86_64.squashfs:
          id: 75ebcd9f-6091-4377-b3d8-3667ba0b23dc
      recipes:
        cray-shasta-csm-sles15sp6-barebones-csm-1.6-aarch64:
          id: e2bd9671-9ba3-465b-a1fb-d2ad25b7926c
        cray-shasta-csm-sles15sp6-barebones-csm-1.6-x86_64:
          id: 93b33c0f-4e5d-4289-903a-68284c67e8fc
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

    See [CFS Configurations](../../operations/configuration_management/CFS_Configurations.md) for details.
