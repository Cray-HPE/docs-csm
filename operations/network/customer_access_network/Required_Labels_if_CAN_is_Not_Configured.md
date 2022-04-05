# Required Labels if CAN is Not Configured

Some services on the system are required to access services outside of the HPE Cray EX system. If the Customer Access Network \(CAN\) is not configured on the system, these services will need to be pinned to `ncn-m001` because that is the only node that has external access. See [Customer Access Network \(CAN\)](Customer_Access_Network_CAN.md) for more implications if CAN is not configured.

The label used for scheduling these services is `no_external_access`:

- If the `no_external_access` label is applied to a node with the value `True`, then any pods that require outside access will not be scheduled on that node.
- If the `no_external_access` label is applied to a node with the value `False`, or if the label does not exist on the node, then any pods that require outside access will be scheduled on that node.

Therefore, if CAN is not configured on the system, the label `no_external_access=True` must be applied to all NCN master and worker nodes other than `ncn-m001`.

### Before Installation

The label can be configured by setting the following values to True in the customizations.yaml file. This value needs to be set for each NCN master and worker node, excluding `ncn-m001`.

```
      cray-node-labels:
        nodeLabels:
        - ncn-m001:no_external_access=False
        - ncn-m002:no_external_access=True
        - ncn-m003:no_external_access=True
        - ncn-w001:no_external_access=False
        - ncn-w002:no_external_access=False
        - ncn-w003:no_external_access=False
```

### Post-Installation

The label can be set by editing the Kubernetes ConfigMap by running the following command:

```bash
ncn-m001# kubectl edit cm -n services cray-node-labels
```

Edit the following section as desired \(save and close by hitting the **ESC** key and typing **:wq**\):

```
  node_labels: |2-

    - ncn-m001:no_external_access=False
    - ncn-m002:no_external_access=True
    - ncn-m003:no_external_access=True
    - ncn-w001:no_external_access=False
    - ncn-w002:no_external_access=False
    - ncn-w003:no_external_access=False
```

To view the labels applied to each node:

```bash
ncn-m001# kubectl get nodes --show-labels
```

