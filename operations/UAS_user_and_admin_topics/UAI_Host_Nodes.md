
## UAI Host Nodes

UAIs run on Kubernetes worker nodes. There is a mechanism using Kubernetes labels to prevent UAIs from running on a specific worker node, however. Any Kubernetes node that is not labeled to prevent UAIs from running on it is considered to be a UAI host node. The administrator of a given site may control the set of UAI host nodes by labeling Kubernetes worker nodes appropriately.
