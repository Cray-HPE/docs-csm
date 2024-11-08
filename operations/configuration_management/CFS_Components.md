# CFS Components

The Configuration Framework Service \(CFS\) contains a database of the configuration state of available hardware known to the Hardware State Manager \(HSM\).
When new nodes are added to the HSM database, the `CFS-Hardware-Sync-Agent` enters the component into the CFS database with an empty state of configuration.

Administrators are able to set a desired CFS configuration for each component, and the `CFS-Batcher` ensures the desired configuration state and the current configuration state match.
See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information.

- [Component data](#component-data)
- [View components](#view-components)
- [Set a desired component configuration](#set-a-desired-component-configuration)
- [Disable component configuration](#disable-component-configuration)
- [Force component reconfiguration](#force-component-reconfiguration)
- [Update components in bulk](#update-components-in-bulk)
- [Component with zero-length ID](#component-with-zero-length-id)

## Component data

The following fields are tracked for each component to determine the status and state of the component:

- **`configuration_status`**

    The status of the component's configuration. Valid status values are:

    - **`unconfigured`** - The component has no recorded state and no desired configuration or no valid desired configuration.
    - **`failed`** - One of the configuration layers for the component has failed and the retry limit has been exceeded.
    - **`pending`** - The component's desired state and actual state do not match. The component will be configured automatically if enabled.
    - **`configured`** - The component's desired state and actual state match.

- **`desired_config`**

    The CFS configuration assigned to this component.

- **`enabled`**

    Indicates whether the component will be automatically configured by CFS or not.

- **`error_count`**

    The number of times configuration sessions have failed to configure this component.

- **`retry_policy`**

    The number of times the configuration will be attempted if it fails. If `error_count` \>= `retry_policy`, CFS will not continue attempts to apply the `desired_config`.

- **`state`**

    The list of configuration layers that have been applied to the component. This information is not returned by default but can be requested by adding `--state-details true` to any components query.
    For each layer in the component state the status can be one of the following:

    - **`applied`** - The playbook completed successfully.
    - **`failed`** - The playbook encountered an error while configuring this component.
    - **`incomplete`** - The playbook exited due to an error on another component and will be re-run against this component.
    - **`skipped`** - The playbook completed, but this component was not a valid target.

- **`desired_state`**

    The list of configuration layers that should be applied to the component based on the `desired_config`, and the status of each of these layers.
    This information is not returned by default but can be requested by adding `--config-details true` to any components query.

- **`logs`**

    A link to the ARA UI for all Ansible logs related to this component.

## View components

(`ncn-mw#`) To view the configuration state of a given component, use the `describe` command for a given component name (`xname`):

```bash
cray cfs v3 components describe <xname> --format json
```

Example output:

```json
{
  "configuration_status": "configured",
  "desired_config": "example-config",
  "enabled": true,
  "error_count": 0,
  "id": "x3000c0s11b0n0",
  "logs": "ara.cmn.example.site/hosts?name=x3000c0s11b0n0",
  "tags": {}
}
```

(`ncn-mw#`) To view the configuration state details of a given component, use the `describe` command for a given component name (`xname`) with `--state-details true`:

```bash
cray cfs v3 components describe <xname> --state-details true --format json
```

Example output:

```json
{
  "configuration_status": "configured",
  "desired_config": "example-config",
  "enabled": true,
  "error_count": 0,
  "id": "x3000c0s11b0n0",
  "logs": "ara.cmn.example.site/hosts?name=x3000c0s11b0n0",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example.git",
      "commit": "e230aae4ecd4cc0aa3c5fe5835f2c896e15fd8ab",
      "last_updated": "2023-07-18T14:54:57Z",
      "playbook": "site.yml",
      "session_name": "batcher-f3c378fa-186e-4b41-a56e-ffbffb540554",
      "status": "applied"
    }
  ],
  "tags": {}
}
```

## Set a desired component configuration

(`ncn-mw#`) To disable CFS configuration of a component, use the `--desired-config` option with the name of a CFS configuration:

> **IMPORTANT:** Ensure that the new configuration has been created with the `cray cfs v3 configurations update <config_name>` command before assigning the configuration to any components.

```bash
cray cfs v3 components update <xname> --desired-config <config_name>
```

## Disable component configuration

(`ncn-mw#`) To disable CFS configuration of a component, use the `--enabled` option:

> **WARNING:** When a node reboots and the state-reporter reports in to CFS, it will automatically enable configuration. The following command only disables configuration until a node reboots.

```bash
cray cfs v3 components update <xname> --enabled false
```

Use `--enabled true` to re-enable the component.

## Force component reconfiguration

(`ncn-mw#`) To force a component which has a specific `desired_config` to a different configuration, use the `update` subcommand to change the configuration:

```bash
cray cfs v3 components update <xname> --desired-config new-config --enabled true
```

> **IMPORTANT:** Ensure that the new configuration has been created with the `cray cfs v3 configurations update <config_name>` command before assigning the configuration to any components.

(`ncn-mw#`) To force a component to retry its configuration again after it failed, change the `error_count` to less than the `retry_policy`, or raise the `retry_policy`.
If the `error_count` has not reached the retry limit, CFS will automatically keep attempting the configuration and no action is required.

```bash
cray cfs v3 components update <xname> --error-count 0 --enabled true
```

(`ncn-mw#`) To force a component to reapply the same configuration after it succeeded, clear the recorded state for the component.

```bash
cray cfs v3 components update <xname> --state [] --enabled true
```

## Update components in bulk

Updating multiple components at once is not currently available in the CLI due to limitations with the CLI.
However for those programmatically interacting with the CFS API, it is possible to update multiple components at once by calling `/v3/components` with a `PATCH` operation.
It is possible to either provide patches for multiple components in a list, or to provide a single patch and filters for which components to apply the patch to. See the [CFS API specification](../../api/cfs.md) for more information.

## Component with zero-length ID

It is possible for CFS to end up with an invalid component whose ID field is a zero-length string. See
[CFS Component With Zero-Length ID](../../troubleshooting/known_issues/CFS_Component_With_Zero_Length_ID.md)
for more details.
