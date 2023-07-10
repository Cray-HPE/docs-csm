# Configure BMC and Controller Parameters with SCSD

The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
components in liquid-cooled cabinets. These parameters are typically set during discovery, but this
tool enables parameters to be set before or after discovery. The operations to change these parameters
are available in the `cray` CLI under the `scsd` command.

The parameters which can be set are:

* SSH key
* NTP server
* Syslog server
* BMC/Controller passwords
* SSH console key

**IMPORTANT**: If the `scsd` tool is used to update the `SSHConsoleKey` value outside of ConMan, it will
disrupt the ConMan connection to the console and collection of console logs. See [ConMan](../conman/ConMan.md)
for more information about remote consoles and collecting console logs.

However, this procedure only describes how to change the SSH key to enable passwordless SSH for
troubleshooting of power down and power up logs on the node BMCs.

See [Manage Parameters with the SCSD Service](Manage_Parameters_with_the_scsd_Service.md)
for more information about these topics for changing the other parameters:

* Retrieve current information from targets
* Retrieve information from a single target
* Set parameters for targets
* Set parameters for a single BMC or controller
* Set Redfish credentials for multiple targets
* Set Redfish credentials for a single target

The NTP server and `syslog` server for BMCs in the liquid-cooled cabinet are typically set by MEDS.

## Details

1. Save the public SSH key for the root user.

   ```bash
   ncn# export SCSD_SSH_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
   ```

1. Generate a System Configuration Service configuration via the `scsd` tool.

   > The administrator must be authenticated to the Cray CLI before proceeding.
   > See [Configure the Cray CLI](../configure_cray_cli.md).

   ```bash
   ncn# cat > scsd_cfg.json <<DATA
   {
      "Force":false,
      "Targets": $(cray hsm inventory redfishEndpoints list --format=json | jq '[.RedfishEndpoints[] | .ID]' | sed 's/^/ /'),
      "Params":{
         "SSHKey":"$(echo $SCSD_SSH_KEY)"
      }
   }
   DATA
   ```

1. Inspect the generated `scsd_cfg.json` file.

   Ensure that the following are true:

   * The component name (xname) list looks valid/appropriate
   * The `SSHKey` settings match the desired public key

1. Run the CLI command.

   ```bash
   ncn# cray scsd bmc loadcfg create scsd_cfg.json
   ```

   Check the output to verify all hardware has been set with the correct keys. Passwordless SSH to the root
   user should now function as expected.

1. Test access to a node controller in the liquid-cooled cabinet.

   SSH into the node controller for the host xname. For example, if the host xname is `x1000c1s0b0n0`, then the
   node controller xname would be `x1000c1s0b0`.

   If the node controller is not powered up, then this SSH attempt will fail.

   ```bash
   ncn-w001# ssh x1000c1s0b0
   ```

1. The logs from power actions for node 0 and node 1 on this node controller are in `/var/log`.

   ```bash
   x1000c1s0b0# cd /var/log
   x1000c1s0b0# ls -l powerfault_*
   ```

   Expected output looks similar to the following:

   ```text
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node0
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node1
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node0
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node1
   ```
