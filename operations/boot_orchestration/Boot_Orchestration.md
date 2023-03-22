# Boot Orchestration

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes.

There are currently two supported API versions for BOS.
BOS v1 is strictly session based and launches a Boot Orchestration Agent \(BOA\) that fulfills boot requests.
BOS v2 takes a more flexible approach and relies on a number of permanent operators to guide components through state transitions in an independent manner. For more information, see [BOS Workflows](BOS_Workflows.md).

BOS users create BOS session templates via the REST API. A session template is a collection of metadata for a group of nodes and their desired boot artifacts and configuration.
A BOS session can then be created by applying an action to a session template.
The available actions are boot, reboot, shutdown. BOS coordinates with the underlying subsystems to complete the requested action, and the session can be monitored to determine the status of the request.

BOS depends on each of the following services to complete its tasks:

- Boot Script Service \(BSS\) - Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when nodes boot or reboot.
- Configuration Framework Service \(CFS\) - BOA launches CFS to apply configuration to the nodes in its boot sets \(node personalization\).
- Power Control Service \(PCS\) - Used to power nodes on and off, as well as query current power status.
- Hardware State Manager \(HSM\) - Tracks the state of each node and what groups and roles nodes are included in.

## Use the BOS Cray CLI commands

BOS commands are available using the Cray CLI.
For ease of use, BOS can be used without specifying the version and will default to v2. However, explicitly specifying the version in scripts or documentation
is **highly recommended**, because the default BOS version for the CLI may change in the future.

(`ncn-mw#`) API information, including the default API version, can be found with the following command:

```bash
cray bos list --format toml
```

Example output:

```toml
[[results]]
major = "2"
minor = "0"
patch = "0"
[[links]]
href = "https://api-gw-service-nmn.local/apis/bos/"
rel = "self"

[[links]]
href = "https://api-gw-service-nmn.local/apis/bos/v2"
rel = "versions"
```
