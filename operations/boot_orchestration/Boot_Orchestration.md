## Boot Orchestration 

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. This is accomplished using BOS components, such as boot orchestration session templates and sessions, as well as launching a Boot Orchestration Agent \(BOA\) that fulfills boot requests.

BOS users create a BOS session template via the REST API. A session template is a collection of metadata for a group of nodes and their desired boot artifacts and configuration. A BOS session can then be created by applying an action to a session template. The available actions are boot, reboot, shutdown, and configure. BOS will create a Kubernetes BOA job to apply an action. BOA coordinates with the underlying subsystems to complete the action requested. The session can be monitored to determine the status of the request.

BOS depends on each of the following services to complete its tasks:

-   BOA - Handles any action type submitted to the BOS API. BOA jobs are created and launched by BOS.
-   Boot Script Service \(BSS\) - Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when nodes boot or reboot.
-   Configuration Framework Service \(CFS\) - BOA launches CFS to apply configuration to the nodes in its boot sets \(node personalization\).
-   Cray Advanced Platform Monitoring and Control \(CAPMC\) - Used to power on and off the nodes.
-   Hardware State Manager \(HSM\) - Tracks the state of each node and what groups and roles nodes are included in.


### Use the BOS Cray CLI Commands

BOS utilizes the Cray CLI commands. The latest API information can be found with the following command:

```bash
ncn-m001# cray bos list
[[results]]
major = "1"
minor = "0"
patch = "0"
[[results.links]]
href = "https://api-gw-service-nmn.local/apis/bos/v1"
rel = "self"
```

### Table of Contents

The procedures in this section include the information required to boot, configure, and shut down collections of nodes with BOS.

- [BOS Workflows](BOS_Workflows.md)
- [BOS Session Templates](Session_Templates.md)
    - [Manage a Session Template](Manage_a_Session_Template.md)
    - [Create a Session Template to Boot Compute Nodes with CPS](Create_a_Session_Template_to_Boot_Compute_Nodes_with_CPS.md)
    - [Boot UANs](Boot_UANs.md)
- [BOS Sessions](Sessions.md)
    - [Manage a BOS Session](Manage_a_BOS_Session.md)
    - [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md)
    - [Boot Compute Nodes with a Kubernetes Customized Image](Boot_Compute_Nodes_with_a_Kubernetes_Customized_Image.md)
    - [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md)
    - [Configure the BOS Timeout When Booting Compute Nodes](Configure_the_BOS_Timeout_When_Booting_Nodes.md)
    - [Check the Progress of BOS Session Operations](Check_the_Progress_of_BOS_Session_Operations.md)
    - [Clean Up Logs After a BOA Kubernetes Job](Clean_Up_Logs_After_a_BOA_Kubernetes_Job.md)
    - [Clean Up After a BOS/BOA Job is Completed or Cancelled](Clean_Up_After_a_BOS-BOA_Job_is_Completed_or_Cancelled.md)
    - [Troubleshoot UAN Boot Issues](Troubleshoot_UAN_Boot_Issues.md)
    - [Troubleshoot Compute Node Boot Issues Related to Slow Boot Times](Troubleshoot_Compute_Node_Boot_Issues_Related_to_Slow_Boot_Times.md)
    - [Troubleshoot Booting Nodes with Hardware Issues](Troubleshoot_Booting_Nodes_with_Hardware_Issues.md)
- [BOS Limitations for Gigabyte BMC Hardware](Limitations_for_Gigabyte_BMC_Hardware.md)
