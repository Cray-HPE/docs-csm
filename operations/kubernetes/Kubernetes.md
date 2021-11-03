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

### Table of Contents

Reference the following procedures when working with Kubernetes on the system:

-   [About kubectl](About_kubectl.md)
    -   [Configure kubectl Credentials to Access the Kubernetes APIs](Configure_kubectl_Credentials_to_Access_the_Kubernetes_APIs.md)
-   [About Kubernetes Taints and Labels](About_Kubernetes_Taints_and_Labels.md)
-   [Kubernetes Storage](Kubernetes_Storage.md)
-   [Kubernetes Networking](Kubernetes_Networking.md)
-   [Containerd](Containerd.md)
-   [Retrieve Cluster Health Information Using Kubernetes](Retrieve_Cluster_Health_Information_Using_Kubernetes.md)
-   [Pod Resource Limits](Pod_Resource_Limits.md)
    -   [Determine if Pods are Hitting Resource Limits](Determine_if_Pods_are_Hitting_Resource_Limits.md)
    -   [Increase Pod Resource Limits](Increase_Pod_Resource_Limits.md)
    -   [Increase Kafka Pod Resource Limits](Increase_Kafka_Pod_Resource_Limits.md)
-   [About etcd](About_etcd.md)
    -   [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md)
    -   [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md)
    -   [Backups for etcd-operator Clusters](Backups_for_etcd-operator_Clusters.md)
    -   [Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md)
    -   [Restore an etcd Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md)
    -   [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md)
    -   [Restore Bare-Metal etcd Clusters from an S3 Snapshot](Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md)
    -   [Rebalance Healthy etcd Clusters](Rebalance_Healthy_etcd_Clusters.md)
    -   [Check for and Clear etcd Cluster Alarms](Check_for_and_Clear_etcd_Cluster_Alarms.md)
    -   [Report the Endpoint Status for etcd Clusters](Report_the_Endpoint_Status_for_etcd_Clusters.md)
    -   [Clear Space in an etcd Cluster Database](Clear_Space_in_an_etcd_Cluster_Database.md)
-   [About Postgres](About_Postgres.md)
    -   [Troubleshoot Postgres Database](Troubleshoot_Postgres_Database.md)
    -   [Restore Postgres](Restore_Postgres.md)
    -   [View Postgres Information for System Databases](View_Postgres_Information_for_System_Databases.md)
