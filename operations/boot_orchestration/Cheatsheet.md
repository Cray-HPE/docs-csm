# BOS Commands Cheat Sheet

This page is a quick reference for common BOS commands in the [Cray CLI](../../glossary.md#cray-cli-cray).

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.

## Full system commands

* (`ncn-mw#`) Boot all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Boot
    ```

* (`ncn-mw#`) Reboot all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Reboot
    ```

* (`ncn-mw#`) Shutdown all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Shutdown
    ```

* (`ncn-mw#`) Stage a reboot for all nodes in a template:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Reboot --staged True
    ```

## Single node commands

* (`ncn-mw#`) Boot a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Boot --limit <node's xname>
    ```

* (`ncn-mw#`) Reboot a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Reboot --limit <node's xname>
    ```

* (`ncn-mw#`) Shutdown a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Shutdown --limit <node's xname>
    ```

* (`ncn-mw#`) Stage a reboot for a single node:

    ```bash
    cray bos v2 sessions create --template-name SESSION_TEMPLATE_NAME --operation Reboot --staged True --limit <node's xname>
    ```

* (`ncn-mw#`) Monitor the overall boot progress of a single node:

    ```bash
    watch "cray bos v2 components describe <node's xname>"
    ```
