# Kubernetes Storage

Data belonging to micro-services in the management cluster is managed through persistent storage,
which provides reliable and resilient data protection for containers running in the Kubernetes cluster.

The backing storage for this service is currently provided by JBOD disks that are spread across several
nodes of the management cluster. These node disks are managed by Ceph, and are exposed to containers in
the form of persistent volumes.
