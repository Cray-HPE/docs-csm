# Boot Orchestration

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

### BOS API Changes in Upcoming CSM-1.2.0 Release

This is a forewarning of changes that will be made to the BOS API in the upcoming CSM-1.2.0 release. The following changes will be made:

* The `--template-body` option for the Cray CLI `bos` command will be deprecated.
* Performing a GET on the session status for a boot set (i.e. /v1/session/{session_id}/status/{boot_set_name}) currently returns a status code of 201, but instead it should return a status code of 200. This will be corrected to return 200.
