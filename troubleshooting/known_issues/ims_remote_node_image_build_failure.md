# Known Issue: IMS remote node build failure

In CSM 1.6.0, there is a failure in building the IMS barebones builder image while following
these steps: [Create a barebones IMS builder image](../../operations/image_management/Configure_a_Remote_Build_Node.md#create-a-barebones-ims-builder-image)

When this happens, the CFS pod customizing the image may contain this error:

```text
TASK [csm.packages : Install RPMs (SLES-based)] ********************************
fatal: [3a507f20-db8b-475a-851c-214a5acda6e4]: FAILED! =>
{
  "changed": false,
  "cmd": ["/usr/bin/zypper", "--quiet", "--non-interactive", "--xmlout", "install", "--type", "package",
  "--auto-agree-with-licenses", "--no-recommends", "--oldpackage", "--", "+podman", "+cfs-debugger", "+cfs-state-reporter",
  "+cfs-trust", "+craycli", "+csm-auth-utils", "+csm-node-heartbeat", "+csm-node-identity", "+hpe-yq",
  "+spire-agent>=1.5.0", "+tpm-provisioner-client"],
  "msg": "No provider of '+tpm-provisioner-client' found.", 
  "rc": 104, "stderr": "", 
  "stderr_lines": [], "stdout": "<?xml version='1.0'?>\n<stream>\n<message type=\"error\">
  No provider of &apos;+hpe-yq&apos; found.</message>\n<message type=\"error\">
  No provider of &apos;+tpm-provisioner-client&apos; found.</message>\n</stream>\n", 
  "stdout_lines": ["<?xml version='1.0'?>", "<stream>", 
  "<message type=\"error\">No provider of &apos;+hpe-yq&apos; found.</message>", 
  "<message type=\"error\">No provider of &apos;+tpm-provisioner-client&apos; found.</message>", "</stream>"]}
```

## Fix

The fix is to update the Ansible code in the playbook that customizes the default barebones compute image.
Prior to following the steps listed in [Create a barebones IMS builder image](../../operations/image_management/Configure_a_Remote_Build_Node.md#create-a-barebones-ims-builder-image),
do the following:

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

    Set a variable for the `configuration.import_branch` value from the most recent installed version,
    in this example `cray/csm/1.27.2`.

    ```bash
    CSM_IMPORT_BRANCH="cray/csm/1.27.2"
    ```

1. (`ncn-mw#`) Create the patch file

    Create a file named `fix.patch` and paste the below text into the file:

    ```text
    diff --git a/ims_computes.yml b/ims_computes.yml
    index 048090e..4547446 100644
    --- a/ims_computes.yml
    +++ b/ims_computes.yml
    @@ -34,8 +34,10 @@
         - vars/csm_packages.yml
       roles:
         - role: csm.ca_cert
    +    - role: csm.password
    +    - role: csm.ssh_keys
         - role: csm.packages
           vars:
    -        packages: "{{ ims_compute_sles_packages + common_csm_sles_packages }}"
    +        packages: "{{ ims_csm_sles_packages + compute_csm_sles_packages }}"
         - role: csm.ims-remote
         - role: csm.rebuild-initrd
    diff --git a/vars/csm_ims_repos.yml b/vars/csm_ims_repos.yml
    index 257130d..56fa83b 100644
    --- a/vars/csm_ims_repos.yml
    +++ b/vars/csm_ims_repos.yml
    @@ -29,13 +29,25 @@ csm_sles_repositories:
     - name: SUSE-SLE-Module-Basesystem-${releasever_major}-SP${releasever_minor}-aarch64-Pool
       description: "SUSE Basesystem Modules (added by Ansible)"
       repo: https://packages.local/repository/SUSE-SLE-Module-Basesystem-${releasever_major}-SP${releasever_minor}-aarch64-Pool
    -- name: csm-sle
    -  description: "CSM SLE Packages (added by Ansible)"
    -  repo: 'https://packages.local/repository/csm-sle-${releasever_major}sp${releasever_minor}'
     - name: SUSE-SLE-Module-Containers-${releasever_major}-SP${releasever_minor}-x86_64-Pool
       description: "Suse container modules (added by Ansible)"
       repo: https://packages.local/repository/SUSE-SLE-Module-Containers-${releasever_major}-SP${releasever_minor}-x86_64-Pool
     - name: SUSE-SLE-Module-Basesystem-${releasever_major}-SP${releasever_minor}-x86_64-Pool
       description: "SUSE Basesystem Modules (added by Ansible)"
       repo: https://packages.local/repository/SUSE-SLE-Module-Basesystem-${releasever_major}-SP${releasever_minor}-x86_64-Pool
    +- name: csm-sle
    +  description: "CSM SLE Packages (added by Ansible)"
    +  repo: 'https://packages.local/repository/csm-sle-${releasever_major}sp${releasever_minor}'
    +- name: csm-noos
    +  description: "CSM No-OS Packages (added by Ansible)"
    +  repo: https://packages.local/repository/csm-noos
    +- name: csm-sle
    +  description: "CSM SLE Packages (added by Ansible)"
    +  repo: 'https://packages.local/repository/csm-sle-${releasever_major}sp${releasever_minor}'
    +- name: csm-noos
    +  description: "CSM No-OS Packages (added by Ansible)"
    +  repo: https://packages.local/repository/csm-noos
    +- name: csm-embedded
    +  description: "CSM Embedded NCN Packages (added by Ansible)"
    +  repo: https://packages.local/repository/csm-embedded
    
    diff --git a/vars/csm_packages.yml b/vars/csm_packages.yml
    index 8c9c67e..8fb8fe2 100644
    --- a/vars/csm_packages.yml
    +++ b/vars/csm_packages.yml
    @@ -77,6 +77,14 @@ compute_csm_sles_packages:
       - cray-uai-util
       - cray-spire-dracut>=2.0.0
    
    -# IMS Remote Compute Nodes:
    -ims_compute_sles_packages:
    -  - podman
    +ims_csm_sles_packages:
    +  - cfs-debugger
    +  - cfs-state-reporter
    +  - cfs-trust
    +  - craycli
    +  - csm-auth-utils
    +  - csm-node-heartbeat
    +  - csm-node-identity
    +  - spire-agent>=1.5.0
    +  - tpm-provisioner-client
    +  - cni-plugins=1.1.1-150500.3.2.1
    ```

1. (`ncn-mw#`) Check out the `csm-config` Ansible plays

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

    Now set up a temporary branch based on the branch for the installed version of CSM:

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

1. (`ncn-mw#`) Apply a fix via a git patch operation

    ```bash
    git apply ../fix.patch
    git commit -a -m "Fixed bare bones CFS error with missing package."
    git push -u origin patch_branch
    ```

    Expected output will be something like:

    ```text
    # git apply ../fix.patch
    # git commit -a -m "Apply WAR patch."
    [patch_branch adc9dca] Apply WAR patch.
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

1. (`ncn-mw#`) Record the new commit id for the patch changes

    There is now a new commit id for the patched version that needs to be used for customizing
    the remote build image. To get this new commit id:

    ```bash
    git rev-parse HEAD
    ```

    Expected output will look something like:

    ```text
    adc9dca4255fea61402013c4b7a2089f61e95421
    ```

1. Continue with the directions

    Now follow the directions in [Create a barebones IMS builder image](../../operations/image_management/Configure_a_Remote_Build_Node.md#create-a-barebones-ims-builder-image)
    but use the `COMMIT_ID` from the previous step in Step 3.
