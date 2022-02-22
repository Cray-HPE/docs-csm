## Enable Passwordless Connections to Liquid Cooled Node BMCs

Set the passwordless SSH keys for the root account and/or console of all liquid-cooled Baseboard Management Controllers \(BMCs\) on the system. This procedure will not work on BMCs for air-cooled hardware.

**Warning:** If admin uses SCSD to update the SSHConsoleKey value outside of ConMan, it will disrupt the ConMan connection to the console and collection of console logs. Refer to [ConMan](../conman/ConMan.md) for more information.

Setting up SSH keys enables administrators to view recent console messages and interact with the console device for nodes.

### Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.
- This procedure requires administrative privileges.

### Procedure

1.  Save the public SSH key for the root user.

    ```bash
    ncn-w001# export SSH_PUBLIC_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
    ```

2.  Enable passwordless SSH to the root user of the BMCs.

    Skip this step if passwordless SSH to the root user is not desired.

    ```bash
    ncn-w001# export SCSD_SSH_KEY=$SSH_PUBLIC_KEY
    ```

3.  Enable passwordless SSH to the consoles on the BMCs.

    Skip this step if passwordless SSH to the consoles is not desired.

    ```bash
    ncn-w001# export SCSD_SSH_CONSOLE_KEY=$SSH_PUBLIC_KEY
    ```

4.  Generate a System Configuration Service configuration via the scsd tool.

    The admin must be authenticated to the Cray CLI before proceeding.

    ```bash
    ncn-w001# cat > scsd_cfg.json <<DATA
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

5.  Inspect the generated scsd\_cfg.json file.

    Ensure the following are true before running the command below:

    - The xname list looks valid/appropriate
    - The `SSHKey` and `SSHConsoleKey` settings match the desired public key

    ```bash
    ncn-w001# cray scsd bmc loadcfg create scsd\_cfg.json
    ```

    Check the output to verify all hardware has been set with the correct keys. Passwordless SSH to the root user and/or the consoles should now function as expected.



