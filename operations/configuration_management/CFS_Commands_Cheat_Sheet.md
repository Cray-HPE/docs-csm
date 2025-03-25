# CFS Commands Cheat Sheet

This page is a quick reference for common CFS commands in the [Cray CLI](../../glossary.md#cray-cli-cray).

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.
For more information about the CFS API, see [Configuration Framework Service](../../api/cfs.md).

* [Managing configurations](#managing-configurations)
* [Managing components](#managing-components)
* [Managing sessions](#managing-sessions)
* [Debugging](#debugging)

## Managing configurations

* (`ncn-mw#`) Create or update a configuration:

    ```bash
    cray cfs v3 configurations update <example-config> --file <./example-config.json>
    ```

  See [CFS Configurations](CFS_Configurations.md) for more information.

## Managing components

* (`ncn-mw#`) Enable or disable automatic configuration for a component:

    ```bash
    cray cfs v3 components update <xname> --enabled <true/false>
    ```

* (`ncn-mw#`) Set the desired configuration for a component:

    ```bash
    cray cfs v3 components update <xname> --desired-config <example-config>
    ```

* (`ncn-mw#`) Clear the state of a component:

    > If this component has a desired configuration set, then this will trigger automatic configuration.
    > See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more details.

    ```bash
    cray cfs v3 components update <xname> --enabled true --state []
    ```

* (`ncn-mw#`) View basic information about component status:

    ```bash
    cray cfs v3 components describe <xname>
    ```

* (`ncn-mw#`) View the list of all playbooks applied to a component:

    ```bash
    cray cfs v3 components describe <xname> --state-details true
    ```

## Managing many components

With `CSM` release `1.6.2` or later and `craycli` version `0.90.1` or later, users can update multiple components at once by using the `updatemany` command.
To check the version of the installed `craycli` run following command.

```bash
rpm -q craycli
```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components:

    ```bash
    cray cfs v3 components updatemany --filter-ids <xname1>,<xname2>,... --enabled <true/false>
    ```

* (`ncn-mw#`) Set the desired configuration for a list of components:

    ```bash
    cray cfs v3 components updatemany --filter-ids <xname1>,<xname2>,... --desired-config <example-config>
    ```

* (`ncn-mw#`) Clear the state on a list of components:

    > For any of these components with a desired configuration set, this will trigger automatic configuration.
    > See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more details.

    ```bash
    cray cfs v3 components updatemany --filter-ids <xname1>,<xname2>,... --enabled true --state []
    ```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components based on status:

    ```bash
    cray cfs v3 components updatemany --filter-status <status> --enabled <true/false>
    ```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components based on their configuration flag:

    ```bash
    cray cfs v3 components updatemany --filter-enabled <true/false> --enabled <true/false>
    ```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components based on their tag:

    ```bash
    cray cfs v3 components updatemany --filter-tags <key1=value1>,<key2=value2>,... --enabled <true/false>
    ```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components based on configuration name:

    ```bash
    cray cfs v3 components updatemany --filter-config-name <configuration name> --enabled <true/false>
    ```

* (`ncn-mw#`) Enable or disable automatic configuration for a list of components based on ID and their configuration flag:

    ```bash
    cray cfs v3 components updatemany --filter-ids <xname1>,<xname2>,... --filter-enabled <true/false> --enabled <true/false>
    ```

See [CFS Components](CFS_Components.md) for more information.

## Managing sessions

* (`ncn-mw#`) Create a node personalization session:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name <config name> --ansible-limit <xname1,xname2,...>
    ```

* (`ncn-mw#`) Customize an image:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name <config name> --target-definition image --target-group <group name, e.g. Compute> <source image id>
    ```

* (`ncn-mw#`) Customize an image and specify the name of the resulting image:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name <config name> --target-definition image --target-group <group name, e.g. Compute> <source image id> --target-image-map <source image id> <resulting image name>
    ```

* (`ncn-mw#`) View session status:

    ```bash
    cray cfs v3 sessions describe <session name>
    ```

* (`ncn-mw#`) Delete a session:

    ```bash
    cray cfs v3 sessions delete <session name>
    ```

See [CFS Sessions](CFS_Sessions.md) for more information.

## Debugging

* (`ncn-mw#`) Create a session that will remain after failure:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name <config name> --ansible-limit <xname1,xname2,...> --debug-on-failure true
    ```

* (`ncn-mw#`) Customize an image customization session that will remain after failure:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name <config name> --target-definition image --target-group <group name, e.g. Compute> <source image id> --debug-on-failure true
    ```

* (`ncn-mw#`) Create a test session for debugging from an Ansible container:

    ```bash
    cray cfs v3 sessions create --name <session name> --configuration-name debug_fail --debug-on-failure true
    ```

See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.
