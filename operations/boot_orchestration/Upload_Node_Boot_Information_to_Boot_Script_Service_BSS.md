
## Upload Node Boot Information to Boot Script Service \(BSS\)

The following information must be uploaded to BSS as a prerequisite to booting a node via iPXE:

-   The location of an initrd image in the artifact repository
-   The location of a kernel image in the artifact repository
-   Kernel boot parameters
-   The node(s) associated with that information, using either host name or NID

BSS manages the iPXE boot scripts that coordinate the boot process for nodes, and it enables basic association of boot scripts with nodes. The boot scripts supply a booting node with a pointer to the necessary images \(kernel and initrd\) and a set of boot-time parameters.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Boot Script Service \(BSS\) is running in containers on a non-compute node \(NCN\).
-   An initrd image and kernel image for one or more nodes have been uploaded to the artifact repository \(see [Manage Artifacts with the Cray CLI](../artifact_management/Manage_Artifacts_with_the_Cray_CLI.md)\).

### Procedure

Because the parameters that must be specified in the PUT command are lengthy, this procedure shows a simple bash script \(not to be confused with iPXE boot scripts\) to enter the boot information into BSS. The first step creates a script that can use either node ID \(NID\) or host name to identify the node\(s\) with which to associate the boot information.

1.  Create a bash script to enter the following boot information into BSS in preparation for booting one or more nodes identified by NID or host name.

    -   `NCN` = the host name of a non-compute node \(NCN\) that is a Kubernetes master node. This procedure uses `api-gw-service-nmn.local`, the API service name on the Node Management Network \(NMN\). For more information, see [Access to System Management Services](../network/Access_to_System_Management_Services.md).
    -   `KERNEL` = the download URL of the kernel image artifact that was uploaded to S3, which is in the s3://s3\_BUCKET/S3\_OBJECT\_KEY/kernel format.
    -   `INITRD` = the download URL of the initrd image artifact that was uploaded to S3, which is in the s3://s3\_BUCKET/S3\_OBJECT\_KEY/initrd format.
    -   `PARAMS` = the boot kernel parameters.

        **IMPORTANT:** The PARAMS line must always include the substring `crashkernel=360M`. This enables node dumps, which are needed to troubleshoot node crashes.

    -   `NIDS` = a list of node IDs of the nodes to be booted.
    -   `HOSTS` = a list of strings identifying by host name the nodes to be booted.

    The following script is generic. A script with specific values is below this one.

    ```
    #!/bin/bash
    NCN=api-gw-service-nmn.local
    KERNEL=s3://S3_BUCKET/S3_OBJECT_KEY/initrd
    INITRD=s3://S3_BUCKET/S3_OBJECT_KEY/kernel
    PARAMS="STRING_WITH_BOOT_PARAMETERS crashkernel=360M"
    #
    # By NID
    NIDS=NID1,NID2,NID3
    cray bss bootparameters create --nids $NIDS --kernel $KERNEL --initrd $INITRD --params $PARAMS
    #
    # By host name
    #HOSTS="STRING_IDENTIFYING_HOST1","STRING_IDENTIFYING_HOST2"
    #cray bss bootparameters create --hosts $HOSTS --kernel $KERNEL --initrd $INITRD --params $PARAMS
    ```

    BSS supports a mechanism that allows for a default boot setup, rather than needing to specify boot details for each specific node. The `HOSTS` value should be set to "Default" in order to utilize the default boot setup. This feature is particular useful with larger systems.

    The following script has specific values for the kernel/initrd image names, the kernel parameters, and the list of NIDS and hosts.

    ```
    #!/bin/bash
    NCN=api-gw-service-nmn.local
    KERNEL=s3://boot-images/97b548b9-2ea9-45c9-95ba-dfc77e5522eb/kernel
    INITRD=s3://boot-images/97b548b9-2ea9-45c9-95ba-dfc77e5522eb/initrd
    PARAMS="console=ttyS0,115200n8 console=tty0 initrd=97b548b9-2ea9-45c9-95ba-dfc77e5522eb root=nfs:$NCN:/var/lib/nfsroot/cmp000001_image rw nofb selinux=0 rd.net.timeout.carrier=20 crashkernel=360M"
    PARAMS="console=ttyS0,115200n8 console=tty0 initrd=${INITRD##*/} \
    root=nfs:10.2.0.1:$NFS_IMAGE_ROOT_DIR rw nofb selinux=0 rd.shell crashkernel=360M \
    ip=dhcp rd.neednet=1 htburl=https://10.2.100.50/apis/hbtd/hmi/v1/heartbeat"
    #
    # By NID
    NIDS=1
    cray bss bootparameters create --nids $NIDS --kernel $KERNEL --initrd $INITRD --params $PARAMS
    #
    # By host name
    #HOSTS="nid000001-nmn"
    #cray bss bootparameters create --hosts $HOSTS --kernel $KERNEL --initrd $INITRD --params $PARAMS
    ```

2.  Run the bash script to upload the boot information to BSS for the identified nodes.

    ```bash
    localhost# chmod +x script.sh && ./script.sh
    ```

3.  View the boot script.

    This will show the specific boot script that will be passed to a given node when requesting a boot script. This is useful for debugging boot problems and to verify that BSS is configured correctly.

    ```bash
    localhost# cray bss bootscript list --nid NODE_ID
    ```

4.  Confirm that the information has been uploaded to BSS.

    - If nodes identified by host name:

        ```bash
        localhost# cray bss bootparameters list --hosts HOST_NAME
        ```

        For example:

        ```bash
        localhost# cray bss bootparameters list --hosts Default
        ```

    - If nodes identified by NID:

        ```bash
        localhost# cray bss bootparameters list --nids NODE_ID
        ```

        For example:

        ```bash
        localhost# cray bss bootparameters list --nids 1
        ```

5.  View entire contents of BSS, if desired.

    ```bash
    localhost# cray bss dumpstate list
    ```

    To view the information retrieved from the HSM:

    ```bash
    localhost# cray bss hosts list
    ```

    To view the view the configured boot parameter information:

    ```bash
    localhost# cray bss bootparameters list
    ```


Boot information has been added to BSS in preparation for iPXE booting all nodes in the list of host names or NIDs.

As part of power up the nodes in the host name or NID list, the next step is to reboot the nodes.

