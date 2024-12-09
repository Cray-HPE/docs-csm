# BOS Commands Cheat Sheet

This page is a quick reference for common BOS commands in the [Cray CLI](../../glossary.md#cray-cli-cray).

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.

* [BOS v2 commands](#bos-v2-commands)
    * [Full system commands (v2)](#full-system-commands-v2)
    * [Single node commands (v2)](#single-node-commands-v2)
* [BOS v1 commands](#bos-v1-commands)
    * [Full system commands (v1)](#full-system-commands-v1)
    * [Single node commands (v1)](#single-node-commands-v1)

## BOS v2 commands

### Full system commands (v2)

* (`ncn-mw#`) Boot all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation boot
    ```

* (`ncn-mw#`) Reboot all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation reboot
    ```

* (`ncn-mw#`) Shutdown all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation shutdown
    ```

* (`ncn-mw#`) Stage a reboot for all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation reboot --staged True
    ```

### Single node commands (v2)

* (`ncn-mw#`) Boot a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation boot --limit <node's xname>
    ```

* (`ncn-mw#`) Reboot a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation reboot --limit <node's xname>
    ```

* (`ncn-mw#`) Shutdown a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation shutdown --limit <node's xname>
    ```

* (`ncn-mw#`) Stage a reboot for a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation reboot --staged True --limit <node's xname>
    ```

* (`ncn-mw#`) Monitor the overall boot progress of a single node:

    ```bash
    watch "cray bos v2 components describe <node's xname>"
    ```

## BOS v1 commands

### Full system commands (v1)

* (`ncn-mw#`) Boot all nodes in a template:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation boot
    ```

* (`ncn-mw#`) Reboot all nodes in a template:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation reboot
    ```

* (`ncn-mw#`) Shutdown all nodes in a template:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation shutdown
    ```

### Single node commands (v1)

* (`ncn-mw#`) Boot a single node:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation boot --limit <node's xname>
    ```

* (`ncn-mw#`) Reboot a single node:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation reboot --limit <node's xname>
    ```

* (`ncn-mw#`) Shutdown a single node:

    ```bash
    cray bos v1 session create --template-name SESSION_TEMPLATE_NAME --operation shutdown --limit <node's xname>
    ```
