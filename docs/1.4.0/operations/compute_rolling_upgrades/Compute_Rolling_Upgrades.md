# Compute Rolling Upgrades

> **`NOTE`** CRUS was deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
> See the following links for more information:
>
> - [Rolling Upgrades with BOS V2](../boot_orchestration/Rolling_Upgrades.md)
> - [Deprecated features](../../introduction/differences.md#deprecated-features)

The Compute Rolling Upgrade Service \(CRUS\) upgrades sets of compute nodes without requiring an entire set of nodes to be out of service at once. CRUS manages the workload
management status of nodes, handling each of the following steps required to upgrade compute nodes:

1. Quiesce each node before taking the node out of service.
1. Upgrade the node.
1. Reboot the node into the upgraded state.
1. Return the node to service within its respective workload manager.

CRUS enables administrators to limit the impact on production caused from upgrading compute nodes by working through one step of the upgrade process at a time. The nodes in each
step are first taken out of service in the workload manager to prevent work from being scheduled. They are then upgraded, rebooted, and put back into service in the workload manager.

CRUS is built upon a few basic features of the system:

- The grouping of nodes by label provided by the Hardware State Manager \(HSM\) groups mechanism.
- Workload management that can gracefully take nodes out of service \(quiesce nodes\), declare nodes as failed, and return nodes to service.
- The Boot Orchestration Service \(BOS\) and boot session templates.
