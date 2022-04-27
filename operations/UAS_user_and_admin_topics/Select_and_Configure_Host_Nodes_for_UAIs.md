# Select and Configure Host Nodes for UAIs

Site administrators can control the set of UAI host nodes by labeling Kubernetes worker nodes appropriately.

UAIs run on NCNs that function as Kubernetes worker nodes. Use Kubernetes labels to prevent UAIs from running on one or more specific worker nodes. Any Kubernetes node that is not labeled to prevent UAIs from running on it is considered to be a UAI host node. In other words, UAI host node selection is an exclusive activity, not an inclusive one.

This procedure explains both how to identify and modify the list of current UAI host nodes to meet the needs of users.

### Procedure

**Identify Current UAI Host Nodes**

1.  Identify the nodes that could potentially be UAI host nodes.

    Kubernetes master NCNs cannot host UAIs.

    ```bash
    ncn-m001-pit# kubectl get no | grep -v master
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-w001   Ready    <none>   10d   v1.18.6
    ncn-w002   Ready    <none>   25d   v1.18.6
    ncn-w003   Ready    <none>   23d   v1.18.6
    ```

2.  Identify the nodes that are currently excluded from hosting UAIs.

    In the following example one NCN, ncn-w001, is configured to not host UAIs. Therefore, ncn-w002 and ncn-w003 are UAI host nodes.

    ```bash
    ncn-m001-pit# kubectl get no -l uas=False
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-w001   Ready    <none>   10d   v1.18.6
    ```

3.  Repeat the previous command with alternative capitalizations of False \(for example, false and FALSE\).

    Hewlett Packard Enterprise recommends this step to identify all labeled NCNs, because labels are case-sensitive text strings and not boolean values.

**Configure the NCNs that will Host UAIs**

4.  Determine which and how many worker NCNs will host UAIs.

    Consider the amount of combined load that users and system services will bring to those nodes. UAIs run by default at a lower priority than system services on worker NCNs. Therefore, if the combined load exceeds the capacity of the nodes, Kubernetes will eject UAIs, refuse to schedule them, or both to protect system services. These actions can be disruptive or frustrating for users.

5.  Exclude the appropriate NCNs from hosting UAIs by labeling those NCNs.

    Site administrators may set `uas=True`, or any capitalization variant of that, for local bookkeeping purposes. Such a setting does **not** transform the node into a UAS host node. Any node that does not have a `uas` label value of either `False`, `false`, or `FALSE` is a UAI host node.

    Therefore, removing the uas label from a node labeled uas=True does not take the node out of the list of UAI host nodes. The only way to prevent a non-master NCN from hosting UAIs is to explicitly set the uas label to False, false, or FALSE.

    ```bash
    ncn-m001-pit# kubectl label node ncn-w001 uas=False --overwrite
    ```

