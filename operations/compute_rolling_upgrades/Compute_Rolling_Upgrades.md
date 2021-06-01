## Compute Rolling Upgrades

The Compute Rolling Upgrade Service \(CRUS\) upgrades sets of compute nodes without requiring an entire set of nodes to be out of service at once. CRUS manages the workload management status of nodes, handling each of the following steps required to upgrade compute nodes:

1.  Quiesce each node before taking the node out of service.
2.  Upgrade the node.
3.  Reboot the node into the upgraded state.
4.  Return the node to service within its respective workload manager.

CRUS enables administrators to limit the impact on production caused from upgrading compute nodes by working through one step of the upgrade process at a time. The nodes in each step are taken out of service in the workload manager to prevent work from being scheduled, upgraded, rebooted, and put back into service in the workload manager.

CRUS is built upon a few basic features of the system:

-   The grouping of nodes by label provided by the Hardware State Manager \(HSM\) groups mechanism.
-   Workload management that can gracefully take nodes out of service \(quiesce nodes\), declare nodes as failed, and return nodes to service.
-   The Boot Orchestration Service \(BOS\) and boot session templates.

### Table of Contents

The following procedures are required to upgrade compute nodes with CRUS.

- [CRUS Workflow](CRUS_Workflow.md)
- [Upgrade Compute Nodes with CRUS](Upgrade_Compute_Nodes_with_CRUS.md)
- [Troubleshoot Nodes Failing to Upgrade in a CRUS Session](Troubleshoot_Nodes_Failing_to_Upgrade_in_a_CRUS_Session.md)
- [Troubleshoot a Failed CRUS Session Due to Unmet Conditions](Troubleshoot_a_Failed_CRUS_Session_Due_to_Unmet_Conditions.md)
- [Troubleshoot a Failed CRUS Session Due to Bad Parameters](Troubleshoot_a_Failed_CRUS_Session_Due_to_Bad_Parameters.md)