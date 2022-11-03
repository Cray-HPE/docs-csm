# About Kubernetes Taints and Labels

Kubernetes labels control node affinity, which is the property of pods that attracts them to a set of nodes. On the other hand, Kubernetes taints enable a node to repel a set of pods. In addition, pods can have tolerances for taints to allow them to run on nodes with certain taints.

Taints are controlled with the `kubectl taint nodes` command, while node labels for various nodes can be customized with a configmap that contains the desired values. For a description of how to modify the default node labels, refer to the Customer Access Network (CAN) documentation.

The list of existing labels can be retrieved using the following command:

```bash
ncn# kubectl get nodes --show-labels
```

To learn more, refer to [https://kubernetes.io/](https://kubernetes.io/).

