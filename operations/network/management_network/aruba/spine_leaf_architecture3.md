# Why are spine-leaf architectures becoming more popular?

Given the prevalence of cloud and containerized infrastructure in modern data centers, east-west traffic continues to increase. East-west traffic moves laterally, from server to server. This shift is primarily explained by modern applications having components that are distributed across more servers or VMs.

With east-west traffic, having low-latency, optimized traffic flows is imperative for performance, especially for time-sensitive or data-intensive applications. A spine-leaf architecture aids this by ensuring traffic is always the same number of hops from its next destination, so latency is lower and predictable.

Capacity also improves because STP is no longer required or at least the impact zones of STP can be limited to the edge. While STP enables redundant paths between two switches, only one can be active at any time. As a result, paths often become oversubscribed. Conversely, spine-leaf architectures rely on protocols such as Equal-Cost Multipath (ECMPM) routing to load balance traffic across all available paths while still preventing network loops.

In addition to higher performance, spine-leaf topologies provide better scalability. Additional spine switches can be added and connected to every leaf, increasing capacity. Likewise, new leaf switches can be seamlessly inserted when port density becomes a problem. In either case, this "scale-out" of infrastructure does not require any re-architecting of the network, and there is no downtime.

<<<<<<< HEAD
[Back to Index](./index.md)
=======
[Back to Index](../index.md)
>>>>>>> release/1.2
