# Manual SSH Key Setting Process
If for whatever reason this script fails, SSH keys can be set manually using the following process:


1. Save the public SSH key for the root user.

   ```bash
   ncn# export SCSD_SSH_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
   ```

   If a different SSH key is to be used (for example from conman) set the
   SCSD_SSH_KEY environment variable to that key value.

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

   * The component name (xname) list looks valid/appropriate
   * The SSHKey settings match the desired public key

   ```bash
   ncn# cray scsd bmc loadcfg create scsd_cfg.json
   ```

   Check the output to verify all hardware has been set with the correct keys. Passwordless SSH to the root
   user should now function as expected.

1. Verify access to a node controller in a liquid-cooled cabinet.

   SSH into the node controller for the host component name (xname). For example, if the host component name (xname) is x1000c1s0b0n0, the
   node controller component name (xname) would be x1000c1s0b0.

   If the node controller is not powered up, this SSH attempt will fail.

   ```bash
   ncn-w001# ssh x1000c1s0b0
   x1000c1s0b0:>
   ```

   Notice that the command prompt includes the hostname for this node controller


