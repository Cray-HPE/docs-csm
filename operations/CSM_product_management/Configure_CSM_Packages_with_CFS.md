# Configure CSM packages with CFS

CSM includes a playbook that should be applied to Compute and Application node images.
The `csm_packages.yml` playbook installs the packages for both the CFS and BOS reporters.
These packages are necessary for CFS and BOS to run, so a configuration layer containing the
playbook must be included in the image customization for any nodes that are expected to be
managed with CFS and BOS.

## Setting up the CSM configuration layer

To setup the compute configuration layer, first gather the following information:

* HTTP clone URL for the configuration repository in [VCS](../configuration_management/Version_Control_Service_VCS.md).
* Path to the Ansible play to run in the repository.
* Commit ID in the repository for CFS to pull and run on the nodes.

| Field       | Value                                                                 | Description                                                     |
|:------------|:----------------------------------------------------------------------|:----------------------------------------------------------------|
| `clone_url` | `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git` | CSM configuration repository                                    |
| `commit`    | **Example:** `5081c1ecea56002df41218ee39f6030c3eebdf27`               | CSM configuration commit hash                                   |
| `name`      | **Example:** `csm-<version>`                                          | CSM configuration layer name                                    |
| `playbook`  | `compute_nodes.yml`                                                   | Default Ansible playbook for CSM configuration of compute nodes |

1. (`ncn-mw#`) Retrieve the commit in the repository to use for configuration.
   * If changes have been made to the default branch that was imported during a CSM
     installation or upgrade, use the commit containing the changes.

   * If no changes have been made, the latest commit on the default branch for
     this version of CSM should be used. Find the commit in the
     `cray-product-catalog` for the current version of CSM. For example:

       ```bash
       kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
       ```

       Part of the output will be a section resembling the following:

       ```yaml
       1.2.0:
          configuration:
             clone_url: https://vcs.cmn.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
             commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
             import_branch: cray/csm/1.9.24
             import_date: 2021-07-28 03:26:01.869501
             ssh_url: git@vcs.cmn.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
       ```

     The commit will be different for each system and version of CSM. In the above
     example it is `43ecfa8236bed625b54325ebb70916f55884b3a4`.

1. Craft a new configuration layer entry for CSM using the procedure in [Update a CFS Configuration](../configuration_management/Update_a_CFS_Configuration.md):

    The following is an example entry for the JSON configuration file:

    ```json
    {
        "name": "csm-<version>",
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
        "playbook": "csm_packages.yml",
        "commit": "<retrieved git commit>"
    }
    ```
