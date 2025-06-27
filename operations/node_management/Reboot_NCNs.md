# Reboot NCNs

The following is a high-level overview of the non-compute node \(NCN\) reboot workflow:

1. Run the NCN pre-reboot checks and procedures.

   1. Ensure that `ncn-m001` is not booted to the LiveCD / PIT node.
   1. Check the `metal.no-wipe` settings for all NCNs.
   1. Run all platform health checks, including checks on the Border Gateway Protocol \(BGP\) peering sessions.
   1. [Validate the current boot order](../../background/ncn_boot_workflow.md#determine-the-current-boot-order)
      (or [specify the boot order](../../background/ncn_boot_workflow.md#setting-boot-order)).

1. Run the rolling NCN reboot procedure.

   Loop through reboots on storage nodes, worker nodes, and master nodes, where each reboot consists of the following workflow:

   1. Establish console session with node to reboot.
   1. Execute a Linux graceful shutdown or power off/on sequence to the node, allowing it to boot up to completion.
   1. Execute NCN/platform health checks and do not go on to reboot the next NCN until health has been ensured on the most recently rebooted NCN.
   1. Disconnect console session with the node that was rebooted.

1. Re-run all platform health checks.

The time duration for this procedure \(if health checks are being executed in between each boot, as recommended\) could take between two to four hours for a system with nine management nodes.

This same procedure can be used to reboot a single management node as outlined above.
Be sure to carry out the NCN pre-reboot checks and procedures before and after rebooting the node.
Execute the rolling NCN reboot procedure steps for the particular node type being rebooted.

## Reboot Options

There are two options to perform reboot of NCNs:

1. Reboot NCNs manually  
Use the manual reboot procedure to reboot NCNs. Please refer to the [Reboot NCNs manually](Reboot_NCNs_manual.md)

1. Reboot NCNs with IUF. This is used for worker and storage nodes only. Please refer to the [Reboot NCNs with IUF](Reboot_NCNs_iuf.md)  
**`NOTE`** Rebooting master nodes is not supported with IUF and must be performed manually as mentioned [here](Reboot_NCNs_manual.md#ncn-master-nodes).
