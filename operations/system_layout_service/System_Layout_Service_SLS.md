# System Layout Service \(SLS\)

The System Layout Service \(SLS\) holds information about the system design, such as the physical locations of network hardware, compute nodes, and cabinets. It also stores information about the network, such as which port on which switch should be connected to each compute node.

SLS stores a generalized abstraction of the system that other services can access. The Hardware State Manager \(HSM\) keeps track of information for hardware state or identifiers. SLS does not need to change as hardware within the system is replaced.

Interaction with SLS is required if the system setup changes. For example, if system cabling is altered, or if the system is expanded or reduced. SLS does not interact with the hardware. Interaction with SLS should occur only during system installation, expansion, and contraction.

SLS is responsible for the following:

-   Providing an HTTP API to access site information
-   Storing a list of all hardware
-   Storing a list of all network links
-   Storing a list of all power links

