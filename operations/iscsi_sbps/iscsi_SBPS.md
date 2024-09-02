# iSCSI SBPS (Scalable Boot Content Projection Service)

iSCSI based content projection is named as Scalable Boot Content Projection service (SBPS). The core software running on worker nodes (iSCSI target/ server) is known as "SBPS Marshal Agent". 
Marshal Agent scans IMS and S3 for rootfs and PE images respectively. The rootfs image to be projected is tagged by BOS (Boot Orchestration Service). Marshal Agent creates a fileio backing store 
for this rootfs image and is mounted onto the worker node. Creates iSCSI LUN and mapped to an image. The worker node is preconfigured with LIO (Linux IO) software and targetcli command  which is used to 
manage iSCSI devices like creating luns, listing luns, creating fileio backing store etc., 

Worker node(s) personalization is done via CFS Ansible plays in order to provision worker nodes as iSCSI targets with LIO services, configuration and enablement of required components for SBPS.

The BOS session template is used to boot the compute node where it is filled with SBPS related parameters. DNS SRV records are used by iSCSI client/ initiator nodes (Compute/ UAN(User Access Nodes) 
to discover iSCSI targets (worker nodes) during compute node boot.

# Steps to achieve SBPS

## Node Personalisation
As part of iSCSI SBPS solution, we need to setup/ configure worker nodes as iSCSI targets (servers) with necessary provisioning, configuration and enablement of required components.

See https://github.com/Cray-HPE/docs-csm/blob/CASMPET-6934-SBPS-Node-Personalization/operations/configuration_management/iSCSI_SBPS_Node_Customization.md for more info.

## Creation of BOS session template
 
 https://github.com/Cray-HPE/docs-csm/blob/release/1.6/operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md

 ## IMS images tagging

    Rootfs images needs to be tagged to determine which rootfs image to be projected for compute/UAN node(s) as there will be many rootfs images.
    SBPS Marshal agent uses key/value pair of sbps-project/true to identify the image(s) tagged.
    IMS images (rootfs) tagging is supported from IMS initially which requires to be done manually using craycli. 

    Command to tag an IMS image using craycli 
    ```
    cray ims images update < Image id > --metadata-operation set --metadata-key < key > --metadata-value < value >
    e.g.
    cray ims images update bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb --metadata-operation set --metadata-key sbps-project --metadata-value true
    ```
    
    Command to untag an IMS image using craycli
    ```
    cray ims images update < Image id > --metadata-operation remove --metadata-key < key >
    e.g.
    cray ims images update a506a6f6-54d9-4e5a-9e8d-1fc052d62504 --metadata-operation remove --metadata-key sbps-project
    ```
    IMS image tagging is done automatically by BOS in the latest fix. BOS tags the IMS images when the boot is triggered using BOS session template with SBPS support. But we need to use above craycli command to untag an image as untagging is not supported by BOS.

 ## Steps to boot compute/UAN node

    cray bos sessions create --template-name <Bos session template name> --operation reboot --limit < xname of the node> 
    e.g.
    cray bos sessions create --template-name sbps-bos-template --operation reboot --limit x3000c0s19b2n0
     
    sbps-bos-template - BOS session template name
    x3000c0s19b2n0 - Xname of the compute node 

    This command triggers the boot of the single node x3000c0s19b2n0, using --limit option. Below command triggers the boot of all the compute nodes in the cluster. 

    cray bos sessions create --template-name <BOS session template name> --operation reboot

    Command to view console of the compute/uan node:

    kubectl -n services exec -it cray-console-node-0 -c cray-console-node -- conman -j x3000c0s19b2n0
    
    When the compute/uan nodes boot is triggered without '--limit' option, we need to open the console for each node separately.

## Steps to configure and run  GOSS tests 
https://github.com/Cray-HPE/docs-csm/blob/CASMPET-7153-iSCSI-SBPS-doc/operations/iscsi_sbps/GOSS%20Tests%20for%20SBPS.md

## Steps to retrieve iSCSI (LIO) metrics
https://github.com/Cray-HPE/docs-csm/blob/CASMPET-7153-iSCSI-SBPS-doc/operations/iscsi_sbps/iSCSI_metrics.md
