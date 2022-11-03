# Configuration Management of System Components

The configuration of individual system components is managed with the `cray cfs components` command. The Configuration Framework Service \(CFS\) contains a database of the configuration state of available hardware known to the Hardware State Manager \(HSM\). When new nodes are added to the HSM database, a CFS Hardware Sync Agent enters the component into the CFS database with a null state of configuration.

Administrators are able to set a desired CFS configuration for each component, and the CFS Batcher ensures the desired configuration state and the current configuration state match.

## Automatic Configuration

Whenever CFS detects that the desired configuration does not match the current configuration state, CFS Batcher will automatically start a CFS session to apply the necessary configuration. See [Configuration Management with CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

There are several situations that will cause automatic configuration:

* When rebooted, components that have the `cfs-state-reporter` package installed will register a null current configuration, resulting in a full configuration.
* When a configuration is updated, all components with that desired configuration will automatically get updates for the layers of the configuration that have changed.
* If a configuration is only partially applied because of a previous failed configuration session and the component has not exceeded its maximum retries, it will be configured with any layers of the configurations that have not yet been successfully applied.
* When a user manually resets the configuration state of a component, it will force reconfiguration without rebooting a node.
* If a manual CFS session applies a version of a playbook that conflicts with the version in the desired configuration, CFS will re-apply the desired version after the manual session is completed.
* Any other situation that causes the desired state to not match with the current state of a component will trigger automatic configuration. CFS only tracks the current state of components as they are configured by CFS sessions. It does not track configuration state created or modified by other tooling on the system.

## View Component Configuration

Configuration status of a given component \(using the component name (xname)\) is available through the `cray cfs components describe` command. The following fields are provided to determine the status and state of the component:

* **configurationStatus**

  The status of the component's configuration. Valid status values are unconfigured, failed, pending, and configured.

* **desiredConfig**

  The CFS configurations entry assigned to this component.

* **enabled**

  Indicates whether the component will be configured by CFS or not.

* **errorCount**

  The number of times configuration sessions have failed to configure this component.

* **retryPolicy**

  The number of times the configuration will be attempted if it fails. If errorCount \>= retryPolicy, CFS will not continue attempts to apply the desiredConfig.

* **state**

  The list of configuration layers that have been applied to the component from the desiredConfig.

To view the configuration state of a given component, use the `describe` command for a given component name (xname):

```bash
ncn# cray cfs components describe XNAME --format json
```

Example output:

```json
{
  "configurationStatus": "configured",
  "desiredConfig": "configurations-example",
  "enabled": true,
  "errorCount": 0,
  "id": "x3000c0s13b0n0",
  "retryPolicy": 3,
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example.git",
      "commit": "f6a2727a70fdd6d95df6ad9c883188e694d5b37f",
      "lastUpdated": "2021-07-28T03:26:00Z",
      "playbook": "site.yml",
      "sessionName": "batcher-6c95df62-2fe3-451b-8cc5-21d3cf748f83"
    },
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/another-example.git",
      "commit": "282a9bfbf802d7b5c4d9bb5549b6e77957ec37f0",
      "lastUpdated": "2021-07-28T03:26:10Z",
      "playbook": "ncn.yml",
      "sessionName": "batcher-6c95df62-2fe3-451b-8cc5-21d3cf748f83"
    }
  ]
}
```

When a layer fails to configure, CFS will append a \_failed status to the commit field. CFS Batcher will continue to attempt to configure this component with this configuration layer unless the errorCount has reached the retryPolicy limit.

```json
{
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/another-example.git",
  "commit": "282a9bfbf802d7b5c4d9bb5549b6e77957ec37f0_failed",
  "lastUpdated": "2021-07-28T03:26:20",
  "playbook": "ncn.yml",
  "sessionName": "batcher-74f83dad-9f90-4f5e-bf45-0498ffde8795"
}
```

In the event that a playbook is specified in the configuration that does not apply to the specific component, CFS will append \_skipped to the commit field.

```json
{
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/another-example.git",
  "commit": "a8b132fa5ca04cbe1716501d7be38d9b34532a44_skipped",
  "lastUpdated": "2021-07-28T03:26:30",
  "playbook": "site.yml",
  "sessionName": "batcher-e3152e08-77df-4719-9b15-4fd5ad696730"
}
```

If a playbook exits early because of the Ansible any\_errors\_fatal setting, CFS will append \_incomplete to the commit field for all components that did not cause the failure. This situation would most likely occur only when using an Ansible linear playbook execution strategy.

```json
{
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/another-example.git",
  "commit": "282a9bfbf802d7b5c4d9bb5549b6e77957ec37f0_incomplete",
  "lastUpdated": "2021-07-28T03:26:40",
  "playbook": "site.yml",
  "sessionName": "batcher-6c95df62-2fe3-451b-8cc5-21d3cf748f83"
}
```

## Force Component Reconfiguration

To force a component which has a specific desiredConfig to a different configuration, use the `update` subcommand to change the configuration:

```bash
ncn# cray cfs components update XNAME --desired-config new-config
```

> **IMPORTANT:** Ensure that the new configuration has been created with the `cray cfs configurations update new-config` command before assigning the configuration to any components.

To force a component to retry its configuration again after it failed, change the errorCount to less than the retryPolicy, or raise the retryPolicy. If the errorCount has not reached the retry limit, CFS will automatically keep attempting the configuration and no action is required.

```bash
ncn# cray cfs components update XNAME --error-count 0
```

## Disable Component Configuration

To disable CFS configuration of a component, use the `--enabled` option:

> **WARNING:** When a node reboots and the state-reporter reports in to CFS, it will automatically enable configuration. The following command only disables configuration until a node reboots.

```bash
ncn# cray cfs components update XNAME --enabled false
```

Use `--enabled true` to re-enable the component.

