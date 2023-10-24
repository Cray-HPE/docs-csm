# Enable Passwordless Connections to Liquid Cooled Node BMCs

Set the passwordless SSH keys for the root account and/or console of all liquid-cooled Baseboard Management Controllers \(BMCs\) on the system. This procedure will not work on BMCs for air-cooled hardware.

**Warning:** If administrator uses SCSD to update the `SSHConsoleKey` value outside of ConMan, it will disrupt the ConMan connection to the console and collection of console logs. Refer to [ConMan](../conman/ConMan.md) for more information.

Setting up SSH keys enables administrators to view recent console messages and interact with the console device for nodes.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.
  See [Configure the Cray CLI](../configure_cray_cli.md).
- This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Save the public SSH key for the root user.

    ```bash
    export SSH_PUBLIC_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
    ```

1. (`ncn-mw#`) Enable passwordless SSH to the root user of the BMCs.

    Skip this step if passwordless SSH to the root user is not desired.

    ```bash
    export SCSD_SSH_KEY=$SSH_PUBLIC_KEY
    ```

1. (`ncn-mw#`) Enable passwordless SSH to the consoles on the BMCs.

    Skip this step if passwordless SSH to the consoles is not desired.

    ```bash
    export SCSD_SSH_CONSOLE_KEY=$SSH_PUBLIC_KEY
    ```

1. (`ncn-mw#`) Generate a System Configuration Service configuration using the `scsd` tool.

    The administrator must be authenticated to the Cray CLI before proceeding.

    ```bash
    cat > scsd_cfg.json <<DATA
    {
       "Force":false,
       "Targets":
    $(cray hsm inventory redfishEndpoints list --format=json | jq '[.RedfishEndpoints[] | .ID]' | sed 's/^/   /'),
       "Params":{
          "SSHKey":"$(echo $SCSD_SSH_KEY)",
          "SSHConsoleKey":"$(echo $SCSD_SSH_CONSOLE_KEY)"
       }
    }
    DATA
    ```

1. Inspect the generated `scsd_cfg.json` file.

    Ensure that the following are true before running the command below:

    - The component name (xname) list looks valid/appropriate.
    - The `SSHKey` and `SSHConsoleKey` settings match the desired public key.

1. (`ncn-mw#`) Load the configuration from the file to the System Configuration Service.

    ```bash
    cray scsd bmc loadcfg create scsd_cfg.json
    ```

    Check the output to verify all hardware has been set with the correct keys. Passwordless SSH to the root user and/or the consoles should now function as expected.
