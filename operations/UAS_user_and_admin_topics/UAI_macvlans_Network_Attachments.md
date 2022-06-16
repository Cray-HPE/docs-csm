# UAI `macvlans` Network Attachments

UAIs need to be able to reach compute nodes across the HPE Cray EX internal networks. When the compute node networks are structured as multiple subnets, this requires routing from the UAIs to those subnets.
The default route in a UAI goes to the public network through the Customer Access Network (CAN) so that will not work for reaching compute nodes.
To solve this problem, UAS installs Kubernetes Network Attachments within the Kubernetes `user` namespace. One of these network attachments is used by UAIs.

The type of network attachment used on HPE Cray EX hardware for this purpose is a `macvlan` network attachment, so this is often referred to on HPE Cray EX systems as `macvlans`.
This network attachment integrates the UAI into the HPE Cray EX internal networks on the [UAI host node](UAI_Host_Nodes.md) where the UAI is running and assigns the UAI an IP address on the network defined by the network attachment.
The network attachment also installs a set of routes in the UAI used to reach the compute nodes in the HPE Cray EX platform.

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI Network Attachment Customization](UAI_Network_Attachments.md)
