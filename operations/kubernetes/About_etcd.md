# About etcd

The system uses etcd for storing all of its cluster data. It is an open source database that is excellent for maintaining the state of Kubernetes.
Failures in the etcd cluster at the heart of Kubernetes will cause a failure of Kubernetes.
To mitigate this risk, the system is deployed with etcd on dedicated disks and with a specific configuration to optimize Kubernetes workloads.
The system also provides additional etcd cluster\(s\) as necessary to help maintain an operational state of services.
These additional clusters are managed by a Kubernetes operator and do not interact with the core Kubernetes etcd service.

To learn more about etcd, refer to the following links:

- General documentation - [https://github.com/etcd-io/etcd](https://github.com/etcd-io/etcd)
- README - [https://github.com/etcd-io/etcd/tree/master/etcdctl](https://github.com/etcd-io/etcd/tree/master/etcdctl)
- etcd upstream performance - [https://etcd.io/docs/v3.5/benchmarks/](https://etcd.io/docs/v3.5/benchmarks/)

## Usage of etcd on the System

Communication between etcd machines is handled via the Raft consensus algorithm. Latency from the etcd leader is the most important metric to track because severe latency will introduce instability within the cluster.
Raft is only as fast as the slowest machine in the majority. This problem can be mitigated by properly tuning the cluster.

`Etcd` is a highly available key value store that runs on the three non-compute nodes \(NCNs\) that act as Kubernetes worker nodes.
The three node cluster size deployment is used to meet the minimum requirements for resiliency. Scaling to more nodes will provide more resiliency, but it will not provide more speed.
For example, one write to the cluster is actually three writes, so one to each instance. Scaling to five or more instances in a cluster would mean that one write will actually equal five writes to the cluster.

The system utilizes etcd in two major ways:

- etcd running on bare-metal with a dedicated disk partition
  - Supports only Kubernetes
  - Includes a dedicated partition to provide the best throughput and scalability
    - Enables the Kubernetes services to be scaled, as well as the physical nodes running those services
    - Run on the Kubernetes master nodes and will not relocate
      - Handles replication and instance re-election in the event of a node failure
    - Backed up to a Ceph Rados Gateway \(S3 compatible\) bucket
- etcd running via a helm chart
  - Services utilize this to deploy an etcd cluster on the worker nodes
  - The etcd pods are mobile and will relocate in the event of a pod or node failure
  - Each etcd cluster can be backed up to a Ceph Rados Gateway \(S3 compatible\) bucket
    - This option is decided by the service owner or developer as some information has an extremely short lifespan, and by the time the restore could be performed, the data would be invalid
