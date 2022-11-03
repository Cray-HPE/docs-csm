# UAI macvlans Network Attachments

UAIs need to be able to reach compute nodes across the node management network (NMN). When the compute node NMN is structured as multiple subnets, this requires routing form the UAIs to those subnets. The default route in a UAI goes to the public network through the Customer Access Network (CAN) so that will not work for reaching compute nodes. To solve this problem, UAS installs Kubernetes network attachments within the Kubernetes `user` namespace, one of which is used by UAIs.

The type of network attachment used on HPE Cray EX hardware for this purpose is a `macvlan` network attachment, so this is often referred to on HPE Cray EX systems as "macvlans". This network attachment integrates the UAI into the NMN on the UAI host node where the UAI is running and assigns the UAI an IP address on that network. It also installs a set of routes in the UAI that are used to reach the compute node subnets on the NMN.

