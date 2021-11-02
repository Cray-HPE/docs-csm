## Kubernetes

The system management components are broken down into a series of micro-services. Each service is independently deployable, fine-grained, and uses lightweight protocols. As a result, the system's micro-services are modular, resilient, and can be updated independently. Services within this architecture communicate via REST APIs.

### About Kubernetes

Kubernetes is a portable and extensible platform for managing containerized workloads and services. Kubernetes serves as a micro-services platform on the system that facilitates application deployment, scaling, and management. The system uses Kubernetes for container orchestration.

### Resiliency

The resiliency feature of Kubernetes ensures that the desired number of deployments of a micro-service are always running on one or more NCNs. In addition, Kubernetes ensures that if one NCN becomes unresponsive, the micro-services that were running on it are migrated to another NCN that is up and meets the requirements of the micro-services.

### Kubernetes Components

Kubernetes components can be divided into:

-   **Master components** - Kubernetes master components provide the cluster's control plane. These components make global decisions about the cluster, such as scheduling, and responding to cluster events.
-   **Worker components** - A Kubernetes worker is a node that provides services necessary to run application containers. It is managed by the Kubernetes master. Node components run on every node and keep pods running, while providing the Kubernetes runtime environment.

An etcd cluster is used for storage and state management of the Kubernetes cluster.



