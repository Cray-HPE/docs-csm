# Spine-Leaf Architecture

The network design used in majority of HPE Cray EX installations is spine leaf architecture.
In more sizeable systems, super-spine is also utilized to accommodate the number of spines
that connect the network to provide additional HA capabilities.

## What is spine-leaf architecture?

A spine-leaf architecture is data center network topology that consists of two switching layers: a spine and leaf.
The leaf layer consists of access switches that aggregate traffic from servers and connect directly into the spine
or network core. Spine switches interconnect all leaf switches in a full-mesh topology.
