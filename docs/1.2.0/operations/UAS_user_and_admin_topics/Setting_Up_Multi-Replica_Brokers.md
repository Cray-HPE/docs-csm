# Broker UAI Resiliency and Load Balancing

Broker UAI resiliency and load balancing is achieved through the use of Multi-Replica Broker UAIs.
The procedures and data involved in configuring a UAI Class to create Multi-Replica Broker UAIs can be found in [UAI Classes](UAI_Classes.md).
This page describes some of the reasons to use Multi-Replica Broker UAIs and some of the implications of doing so.

When a Broker UAI runs with multiple replicas, access to the broker remains channeled through a single external IP address, but the connections are load balanced and dispatched to multiple Kubernetes pods where the Broker UAI functionality is running.
This has two beneficial effects:

* SSH Connections to Broker UAIs are load balanced so that no single broker carries all of the weight of users logged into or copying data to UAIs of a given class
* Individual Broker UAI pods can be evicted or restarted by Kubernetes without interrupting access to End-User UAIs

**NOTE:** When a Broker UAI pod terminates for any reason, all SSH sessions going through that pod are dropped. This is because the Broker UAI pods forward SSH sessions to the End-User UAIs, so they are always an active part of the connection.

The number of replicas a Multi-Replica UAI Broker should have is dictated primarily by the number of host nodes on which Broker UAIs can be deployed.
From a load-balancing perspective, it makes sense to make the number of replicas equal to the number of available host nodes.
From a resiliency perspective, that number could be considerably smaller (3 for example) on the assumption that multi-node failures or evictions are unlikely, and brokers that are evicted or restarted will start up relatively quickly elsewhere.
It does not make sense from either perspective, however, to over-subscribe the available number of host nodes (except, perhaps during a temporary outage)
since that will result in no additional resiliency and the potential for network traffic and resource consumption hot spots.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Broker Mode UAI Management](Broker_Mode_UAI_Management.md)
