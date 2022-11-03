# Configure BMC and Controller Parameters with SCSD

The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
components in liquid-cooled cabinets. These parameters are typically set during discovery, but this
tool enables parameters to be set before or after discovery. The operations to change these parameters
are available in the `cray` CLI under the scsd command.

The parameters which can be set are:

* SSH key
* NTP server
* Syslog server
* BMC/Controller passwords
* SSH console key

   IMPORTANT: If the scsd tool is used to update the SSHConsoleKey value outside of ConMan, it will
   disrupt the ConMan connection to the console and collection of console logs. See [ConMan](../conman/ConMan.md)
   for more information about remote consoles and collecting console logs.


However, this procedure only describes how to change the SSH key to enable passwordless SSH for
troubleshooting of power down and power up logs on the node BMCs.

See [Manage Parameters with the scsd Service](Manage_Parameters_with_the_scsd_Service.md)
for more information about these topics for changing the other parameters.

   * Retrieve Current Information from Targets
   * Retrieve Information from a Single target
   * Set Parameters for Targets
   * Set Parameters for a Single BMC or Controller
   * Set Redfish Credentials for Multiple Targets
   * Set Redfish Credentials for a Single Target

The NTP server and syslog server for BMCs in the liquid-cooled cabinet are typically set by MEDS.

## Details

1. Save the public SSH key for the root user.

   ```bash
   ncn# export SCSD_SSH_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
   ```

1. Generate a System Configuration Service configuration via the scsd tool.
The admin must be authenticated to the Cray CLI before proceeding.

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

1. Inspect the generated scsd_cfg.json file.

   Ensure the following are true before running the command below:

   * The xname list looks valid/appropriate
   * The SSHKey settings match the desired public key

   ```bash
   ncn# cray scsd bmc loadcfg create scsd_cfg.json
   ```

   Check the output to verify all hardware has been set with the correct keys. Passwordless SSH to the root
   user should now function as expected.

1. Test access to a node controller in the liquid-cooled cabinet.

   SSH into the node controller for the host component name (xname). For example, if the host component name (xname) is x1000c1s0b0n0, the
   node controller component name (xname) would be x1000c1s0b0.

   If the node controller is not powered up, this SSH attempt will fail.

   ```bash
   ncn-w001# ssh x1000c1s0b0
   x1000c1s0b0:>
   ```

   Notice that the command prompt includes the hostname for this node controller

1. The logs from power actions for node 0 and node 1 on this node controller are in /var/log.

   ```bash
   x1000c1s0b0:> cd /var/log
   x1000c1s0b0:> ls -l powerfault_*
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node0
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node1
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node0
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node1
   ```

