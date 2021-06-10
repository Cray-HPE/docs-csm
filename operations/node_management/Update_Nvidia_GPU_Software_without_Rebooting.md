## Update Nvidia GPU Software without Rebooting

Manually update Nvidia GPU software to a new version without rebooting the GPUs. This procedure can be used for compute nodes and User Access Nodes \(UANs\).

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Nvidia GPU support has been enabled. Refer to [Enable Nvidia GPU Support](Enable_Nvidia_GPU_Support.md).

### Procedure

1.  Create a new Content Projection Service \(CPS\) bind image with a new version of Nvidia GPU software.

    Follow the process for manually installing and making Nvidia Cuda support available via a CPS bind image. Refer to the [Enable Nvidia GPU Support](Enable_Nvidia_GPU_Support.md) procedure and complete the following tasks:

    -   Download a new version of Nvidia GPU software
    -   Create a repository
    -   Create a new CPS bind image
    -   Create a new Configuration Framework Service \(CFS\) branch with the new bind image

2.  Remove the currently deployed cudatookit and drivers.

    This step is required only if the existing version needs to be removed. Otherwise, this step can be skipped.

    Refer to [Configuration Management](../configuration_management/Configuration_Management.md) to create a node personalization CFS session using the Git branch created for node personalization of the older version CPS bind image during the install process.

    Instead of running the default site.yml file, the session should run the do\_nvidia\_undeploy.yml playbook by using the `--ansible-playbook` option. The node inventory to run the CFS session on should be all the Grizzly Peak nodes. There should be a boot session template to boot Grizzly Peak nodes. Use the static inventory mentioned in [Ansible Inventory](../configuration_management/Ansible_Inventory.md), listing all Grizzly Peak under the Compute section of the hosts file of the configuration manifest.

    **Important:** If deploying new Nvidia software on a UAN, use a boot session template for a UAN instead of the Grizzly Peak nodes.

    1.  Create a CFS configuration that will be used to create a CFS job.

        Create the cuda\_configuration.json file to hold data about the CFS configuration. The new configuration should reference the appropriate clone URL for either the Cray Operating System \(COS\) or UAN Version Control Service \(VCS\) config branch, the commit ID of the default Grizzly Peak VCS branch, and the do\_nvidia\_undeploy.yml playbook.

        ```bash
        ncn-m001# cat > cuda_configuration.json
        {
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
              “name”: “cuda_configuration”,
              "commit": "01b8083dd89c394675f3a6955914f344b90581e2",
              "playbook": "do_nvidia_undeploy.yml"
            }
          ]
        }
        ```

    2.  Create a CFS session to un-deploy an existing version of Nvidia software.

        ```bash
        ncn-m001# cray cfs sessions create --name CFS_SESSION_NAME --target-definition repo \
        --configuration-name NEW_CONFIGURATION_NAME
        ```

3.  Deploy the new version of Nvidia GPU software.

    Refer to the "REBOOT/RECONFIGURE GRIZZLY PEAK COMPUTE NODES" section in [Enable Nvidia GPU Support](Enable_Nvidia_GPU_Support.md).


