# UAI Host Node Selection

When selecting UAI host nodes, it is a good idea to take into account the amount of combined load users and system services will bring to those nodes.
UAIs run by default at a lower priority than system services on worker nodes which means that, if the combined load exceeds the capacity of the nodes, Kubernetes will eject UAIs and/or refuse to schedule them to protect system services.
This can be disruptive or frustrating for users. This section explains how to identify the currently configured UAI host nodes and how to adjust that selection to meet the needs of users.

## Identify UAI Host Nodes

UAI host node identification is an exclusive activity, not an inclusive one, so it starts by identifying the nodes that could potentially be UAI host nodes by their Kubernetes role:

1. Identify nodes that could potentially be UAI host nodes by their Kubernetes role.

   ```bash
   ncn-m001-pit# kubectl get nodes | grep -v master
   ```

   Example output:

   ```bash
   NAME       STATUS   ROLES    AGE   VERSION
   ncn-w001   Ready    <none>   10d   v1.20.13
   ncn-w002   Ready    <none>   25d   v1.20.13
   ncn-w003   Ready    <none>   23d   v1.20.13
   ```

   In this example, there are three nodes known by Kubernetes that are not running as Kubernetes master nodes.
   These are all potential UAI host nodes.

2. Identify the nodes that are excluded from eligibility as UAI host nodes.

   ```bash
   ncn-m001-pit# kubectl get no -l uas=False
   ```

   Example output:

   ```bash
   NAME       STATUS   ROLES    AGE   VERSION
   ncn-w001   Ready    <none>   10d   v1.20.13
   ```

   **NOTE:** Given the fact that labels are textual not boolean, it is a good idea to try various common spellings of false.
   The ones that will prevent UAIs from running are 'False', 'false' and 'FALSE'. Repeat the above with all three options to be sure.

   Of the non-master nodes, there is one node in this example that is configured to reject UAIs, `ncn-w001`. So, `ncn-w002` and `ncn-w003` are UAI host nodes.

## Specify UAI Host Nodes

UAI host nodes are determined by labeling the nodes to reject UAIs. For example:

```bash
ncn-m001-pit# kubectl label node ncn-w001 uas=False --overwrite
```

Please note here that setting `uas=True` or any variant of that, while potentially useful for local book keeping purposes, does NOT transform the node into a UAS host node.
With that setting the node will be a UAS node because the value of the `uas` flag is not in the list `False`, `false` or `FALSE`, but unless the node previously had one of the false values, it was a UAI node all along.
Perhaps more to the point, removing the `uas` label from a node labeled `uas=True` does not take the node out of the list of UAI host nodes.
The only way to make a non-master Kubernetes node not be a UAS host node is to explicitly set the label to `False`, `false` or `FALSE`.

## Maintain an HSM Group for UAI Host Nodes

When it comes to customizing non-compute node (NCN) contents for UAIs, it is useful to have a Hardware State Manager (HSM) node group containing the NCNs that are UAI hosts nodes.
The `hpe-csm-scripts` package provides a script called `make_node_groups` that is useful for this purpose. This script is normally installed as `/opt/cray/csm/scripts/node_management/make_node_groups`.
It can create and update node groups for management master nodes, storage nodes, management worker nodes, and UAI host nodes.

The following summarizes its use:

```bash
ncn-m001# /opt/cray/csm/scripts/node_management/make_node_groups --help
```

Example output:

```bash
getopt: unrecognized option '--help'
usage: make_node_groups [-m][-s][-u][w][-A][-R][-N]
Where:
  -m - creates a node group for management master nodes

  -s - creates a node group for management storage nodes

  -u - creates a node group for UAI worker nodes

  -w - creates a node group for management worker nodes

  -A - creates all of the above node groups

  -N - executes a dry run, showing commands not running them

  -R - deletes existing node group(s) before creating them
```

Here is an example of a dry-run that will create or update a node group for UAI host nodes:

```bash
ncn-m001# /opt/cray/csm/scripts/node_management/make_node_groups -N -R -u
```

Example output:

```bash
(dry run)cray hsm groups delete uai
(dry run)cray hsm groups create --label uai
(dry run)cray hsm groups members create uai --id x3000c0s4b0n0
(dry run)cray hsm groups members create uai --id x3000c0s5b0n0
(dry run)cray hsm groups members create uai --id x3000c0s6b0n0
(dry run)cray hsm groups members create uai --id x3000c0s7b0n0
(dry run)cray hsm groups members create uai --id x3000c0s8b0n0
(dry run)cray hsm groups members create uai --id x3000c0s9b0n0
```

Notice that when run in dry-run (`-N` option) mode, the script only prints out the CLI commands it will execute without actually executing them.
When run with the `-R` option, the script removes any existing node groups before recreating them, effectively updating the contents of the node group.
The `-u` option tells the script to create or update only the node group for UAI host nodes. That node group is named `uai` in the HSM.

So, to create a new node group or replace an existing one, called `uai`, containing the list of UAI host nodes, use the following command:

```bash
# /opt/cray/csm/scripts/node_management/make_node_groups -R -u
```

## Use Kubernetes Taints and Tolerations to Make NCNs Exclusive UAI Hosts

If a site has the NCN resources to host UAIs exclusively on a set of NCNs without impacting the operation of the HPE Cray EX System Management Plane, it is recommended to isolate UAIs on NCNs that do not also host Management Plane services.
This can be done using [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration).
By default, UAIs tolerate running on nodes where the `uai_only` taint has been set, while management services beyond the minimal set required to make the node a functioning Kubernetes Worker node on HPE Cray EX do not tolerate that taint.
By adding that taint to nodes in the Kubernetes cluster, sites can keep management services away from those nodes while allowing UAIs to run there.
By further adding the `uas=False` label to all worker nodes in the Kubernetes cluster where UAIs are _not_ allowed, sites can ensure that UAIs only run on exclusive UAI hosts.

Further selection of UAI hosts can be achieved by any site by adding further taints to Kubernetes nodes, and configuring tolerations for those taints into specific [UAI Classes](UAI_Classes.md).

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI `macvlans` Network Attachments](UAI_macvlans_Network_Attachments.md)
