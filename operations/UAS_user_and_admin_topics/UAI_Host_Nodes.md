# UAI Host Nodes

UAIs run as Kubernetes pods on Kubernetes worker nodes.
UAS provides a [a mechanism using Kubernetes labels](UAI_Host_Node_Selection.md) to prevent UAIs from running on a specific worker nodes, but any Kubernetes node that is not labeled to prevent UAIs from running on it is considered eligible to host UAIs.
The administrator of a given site may control the set of UAI host nodes by labeling Kubernetes worker nodes appropriately.

Certain product installation procedures call for the installation of product components on the UAI Host Nodes so that UAIs can use those resources directly from the host node (as opposed to, for example, external shared storage).
It is important to make sure that any such resources are maintained on the UAI host nodes.
If a UAI is configured to use resources from the host node that cannot be found, then the UAI will fail to start, usually remaining in a `Waiting` state.
This documentation contains procedures for diagnosing and fixing issues related to [missing host node resources](Troubleshoot_UAI_Stuck_in_ContainerCreating.md).

Nodes can also be "tainted" in Kubernetes to permit UAIs but not permit general HPE Cray EX System management plane services to run on those nodes.
Through the use of [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration),
with tolerations configured in a [UAI Class](UAI_Classes.md), it is possible to achieve fine-grained control of where UAIs of different classes are deployed on an HPE Cray EX System.

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI Host Node Selection](UAI_Host_Node_Selection.md)
