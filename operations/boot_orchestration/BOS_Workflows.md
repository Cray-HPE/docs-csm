# BOS Workflows

The following workflows present a high-level overview of common Boot Orchestration Service \(BOS\) operations. These workflows depict how services interact with each other when booting, configuring, or shutting down nodes. They also help provide a quicker and deeper understanding of how the system functions.

The following workflows are included in this section:

  - [Boot and Configure Nodes](#boot-and-configure)
  - [Reconfigure Nodes](#reconfigure)
  - [Power Off Nodes](#power-off)

<a name="boot-and-configure"></a>

### Boot and Configure Nodes

**Use Case:** Administrator powers on and configures select compute nodes.

**Components:** This workflow is based on the interaction of the BOS with other services during the boot process:

Mentioned in this workflow:

-   Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. The Boot Orchestration Service has the following components:
    -   Boot Orchestration Session Template is a collection of one or more boot set objects. A boot set defines a collection of nodes and the information about the boot artifacts and parameters.
    -   Boot Orchestration Session carries out an operation. The possible operations in a session are boot, shutdown, reboot, and configure.
    -   Boot Orchestration Agent \(BOA\) is automatically launched to execute the session. A BOA executes the given operation, and if the operation is a boot or a reboot, it also configures the nodes post-boot \(if configure is enabled\).
-   Cray Advanced Platform and Monitoring Control \(CAPMC\) service provides system-level power control for nodes in the system. CAPMC interfaces directly with the Redfish APIs to the controller infrastructure to effect power and environmental changes on the system.
-   Hardware State Manager \(HSM\) tracks the state of each node and their group and role associations.
-   Boot Script Service \(BSS\) stores per-node information about iPXE boot script. Nodes consult BSS for boot artifacts \(kernel, initrd, image root\) and boot parameters when nodes boot or reboot.
-   The Simple Storage Service \(Ceph S3\) is an artifact repository that stores boot artifacts.
-   Configuration Framework Service \(CFS\) configures nodes using configuration framework. Launches and aggregates the status from one or more Ansible instances against nodes \(node personalization\) or images \(image customization\).

![Boot and Configure Nodes](../../img/operations/bos_boot.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1.  **Administrator creates a configuration**

    Add a configuration to CFS.

    ```bash
    # cray cfs configurations update sample-config --file configuration.json
    ```

    Example output:
    
    ```
    {
    "lastUpdated": "2020-09-22T19:56:32Z",
    "layers": [
    {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/configmanagement.
    git",
    "commit": "01b8083dd89c394675f3a6955914f344b90581e2",
    "playbook": "site.yaml"
    }
    ],
    "name": "sample-config"
    }
    ```

2.  **Administrator creates a session template**

    A session template is a collection of metadata for a group of nodes and their desired configuration. A session template can be created from a JSON structure. It returns a SessionTemplate ID if successful.

    See [Manage a Session Template](Manage_a_Session_Template.md) for more information.

3.  **Administrator creates a session**

    Create a session to perform the operation specified in the operation request parameter on the boot set defined in the session template. For this use case, Administrator creates a session with operation as Boot and specifies the session template ID. The set of allowed operations are:

    -   Boot – Boot nodes that are powered off
    -   Configure – Reconfigure the nodes using the Configuration Framework Service \(CFS\)
    -   Reboot – Gracefully power down nodes that are on and then power them back up
    -   Shutdown – Gracefully power down nodes that are on

    ```bash
    # cray bos session create \
    --template-uuid SESSIONTEMPLATE_NAME \
    --operation Boot
    ```

4.  **Launch BOA**

    The creation of a session results in the creation of a Kubernetes BOA job to complete the operation. BOA coordinates with other services to complete the requested operation.

5.  **BOA to HSM**

    BOA coordinates with HSM to validate node group and node status.

6.  **BOA to S3**

    BOA coordinates with S3 to verify boot artifacts like kernel, initrd, and root file system.

7.  **BOA to BSS**

    BOA updates BSS with boot artifacts and kernel parameters for each node.

8.  **BOA to CAPMC**

    BOA coordinates with CAPMC to power-on the nodes.

9.  **CAPMC boots nodes**

    CAPMC interfaces directly with the Redfish APIs and powers on the selected nodes.

10. **BSS interacts with the nodes**

    BSS generates iPXE boot scripts based on the image content and boot parameters that have been assigned to a node. Nodes download the iPXE boot script from BSS.

11. **S3 interacts with the nodes**

    Nodes download the boot artifacts. The nodes boot using the boot artifacts pulled from S3.

12. **BOA to HSM**

    BOA waits for the nodes to boot up and be accessible via SSH. This can take up to 30 minutes. BOA coordinates with HSM to ensures that nodes are booted and Ansible can SSH to them.

13. **BOA to CFS**

    BOA directs CFS to apply post-boot configuration.

14. **CFS applies configuration**

    CFS runs Ansible on the nodes and applies post-boot configuration \(also called node personalization\). CFS then communicates the results back to BOA.

<a name="reconfigure"></a>

### Reconfigure Nodes

**Use Case:** Administrator reconfigures compute nodes that are already booted and configured.

**Components:** This workflow is based on the interaction of the BOS with other services during the reconfiguration process.

Mentioned in this workflow:

-   Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. The Boot Orchestration Service has the following components:
    -   Boot Orchestration Session Template is a collection of one or more boot set objects. A boot set defines a collection of nodes and the information about the boot artifacts and parameters.
    -   Boot Orchestration Session carries out an operation. The possible operations in a session are boot, shutdown, reboot, and configure.
    -   Boot Orchestration Agent \(BOA\) is automatically launched to execute the session. A BOA executes the given operation, and if the operation is a boot or a reboot, it also configures the nodes post-boot \(if configure is enabled\).
-   Configuration Framework Service \(CFS\) configures nodes using configuration framework. Launches and aggregates the status from one or more Ansible instances against nodes \(node personalization\) or images \(image customization\).
-   Hardware State Manager \(HSM\) tracks the state of each node and their group and role associations.

![Reconfigure Nodes](../../img/operations/bos_reconfigure.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1.  **Administrator creates a session template**

    A session template is a collection of metadata for a group of nodes and their desired configuration. A session template can be created from a JSON structure. It returns a SessionTemplate ID if successful.

    See [Manage a Session Template](Manage_a_Session_Template.md) for more information.

2.  **Administrator creates a session**

    Create a session to perform the operation specified in the operation request parameter on the boot set defined in the session template. For this use case, Administrator creates a session with operation as Boot and specifies the session template ID. The set of allowed operations are:

    -   Boot – Boot nodes that are powered off
    -   Configure – Reconfigure the nodes using the Configuration Framework Service \(CFS\)
    -   Reboot – Gracefully power down nodes that are on and then power them back up
    -   Shutdown – Gracefully power down nodes that are on

    ```bash
    # cray bos session create \
    --template-uuid SESSIONTEMPLATE_NAME \
    --operation Configure
    ```

3.  **Launch BOA**

    The creation of a session results in the creation of a Kubernetes BOA job to complete the operation. BOA coordinates with the underlying subsystem to complete the requested operation.

4.  **BOA to HSM**

    BOA coordinates with HSM to validate node group and node status.

5.  **BOA to CFS**

    BOA directs CFS to apply post-boot configuration.

6.  **CFS applies configuration**

    CFS runs Ansible on the nodes and applies post-boot configuration \(also called node personalization\).

7.  **CFS to BOA**

    CFS then communicates the results back to BOA.

<a name="power-off"></a>

### Power Off Nodes

**Use Cases:** Administrator powers off selected compute nodes.

**Components:** This workflow is based on the interaction of the Boot Orchestration Service \(BOS\) with other services during the node shutdown process:

Mentioned in this workflow:

-   Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. The Boot Orchestration Service has the following components:
    -   Boot Orchestration Session Template is a collection of one or more boot set objects. A boot set defines a collection of nodes and the information about the boot artifacts and parameters.
    -   Boot Orchestration Session carries out an operation. The possible operations in a session are boot, shutdown, reboot, and configure.
    -   Boot Orchestration Agent \(BOA\) is automatically launched to execute the session. A BOA executes the given operation, and if the operation is a boot or a reboot, it also configures the nodes post-boot \(if configure is enabled\).
-   Cray Advanced Platform and Monitoring Control \(CAPMC\) service provides system-level power control for nodes in the system. CAPMC interfaces directly with the Redfish APIs to the controller infrastructure to effect power and environmental changes on the system.
-   Hardware State Manager \(HSM\) tracks the state of each node and their group and role associations.

![Shutdown Nodes](../../img/operations/bos_shutdown.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1.  **Administrator creates a session template**

    A session template is a collection of metadata for a group of nodes and their desired configuration. A session template can be created from a JSON structure. It returns a SessionTemplate ID if successful.

    See [Manage a Session Template](Manage_a_Session_Template.md) for more information.

2.  **Administrator creates a session**

    Create a session to perform the operation specified in the operation request parameter on the boot set defined in the session template. For this use case, Administrator creates a session with operation as Boot and specifies the session template ID. The set of allowed operations are:

    -   Boot – Boot nodes that are powered off
    -   Configure – Reconfigure the nodes using the Configuration Framework Service \(CFS\)
    -   Reboot – Gracefully power down nodes that are on and then power them back up
    -   Shutdown – Gracefully power down nodes that are on

    ```bash
    # cray bos session create \
    --template-uuid SESSIONTEMPLATE_NAME \
    --operation Shutdown
    ```

3.  **Launch BOA**

    The creation of a session results in the creation of a Kubernetes BOA job to complete the operation. BOA coordinates with the underlying subsystem to complete the requested operation.

4.  **BOA to HSM**

    BOA coordinates with HSM to validate node group and node status.

5.  **BOA to CAPMC**

    BOA directs CAPMC to power off the nodes.

6.  **CAPMC to the nodes**

    CAPMC interfaces directly with the Redfish APIs and powers off the selected nodes.

7.  **CAPMC to BOA**

    CAPMC communicates the results back to BOA.

