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

The NTP server and syslog server for BMCs in the liquid-cooled cabinet are typically set by MEDS.

## Details

(`ncn-mw#`) Setting the SSH keys for Mountain controllers is done by running the `/opt/cray/csm/scripts/admin_access/set_ssh_keys.py` script:

```text
Usage: set_ssh_keys.py [options]

   --debug=level    Set debug level
   --dryrun         Gather all info but do not set anything in HW.
   --exclude=list   Comma-separated list of target patterns to exclude.
                    Each item in the list is matched on the front
                    of each target component name (xname) and excluded if there is a match.
                    Example: x1000,x3000c0,x9000c1s0
                        This will exclude all BMCs in cabinet x1000,
                        all BMCs at or below x3000c0, and all BMCs
                        below x9000c1s0.
                    NOTE: --include and --exclude are mutually exclusive.
   --include=list   Comma-separated list of target patterns to include.
                    Each item in the list is matched on the front
                    of each target component name (xname) and included is there is a match.
                    NOTE: --include and --exclude are mutually exclusive.
   --sshkey=key     SSH key to set on BMCs. If none is specified, will use
```

(`ncn-mw#`) If no command line arguments are needed, SSH keys are set on all discovered Mountain controllers using the root account's public RSA key. Using an alternate key requires the `--sshkey=key` argument:

```bash
/opt/cray/csm/scripts/admin_access/set_ssh_keys.py --sshkey="AAAbbCcDddd...."
```

After the script runs, verify that it worked:

1. (`ncn-mw#`) Test access to a node controller in the liquid-cooled cabinet.

   SSH into the node controller for the host component name (xname). For example, if the host component name (xname) is `x1000c1s0b0n0`, the
   node controller component name (xname) would be `x1000c1s0b0`.

   If the node controller is not powered up, this SSH attempt will fail.

   ```bash
   ssh x1000c1s0b0
   ```

   Notice that the command prompt (`x1000c1s0b0:>`) includes the hostname for this node controller.

1. (`x1000c1s0b0#`) The logs from power actions for node 0 and node 1 on this node controller are in /var/log.

   ```bash
   cd /var/log
   ls -l powerfault_*
   ```

   Expected output looks similar to the following:

   ```text
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node0
   -rw-r--r--    1 root     root           306 May 10 15:32 powerfault_dn.Node1
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node0
   -rw-r--r--    1 root     root          5781 May 10 15:36 powerfault_up.Node1
   ```

## Debugging if script fails

If this script does not achieve the goal of setting SSH keys, then check the following:

* Make sure the SSH key is correct.
* If `--exclude=` or `--include=` was used with the script, ensure the correct component names (xnames) were specified.
* Re-run the script with `--debug=3` for verbose debugging output. Look for things like missing BMCs, bad authentication token, or bad communications with BMCs.

If this script fails, then the SSH keys can be set manually using the [Manual SSH Key Setting Process](../../troubleshooting/BMC_SSH_key_manual_fixup.md).
