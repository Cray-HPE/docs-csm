# Resource Specifications

**NOTE:** UAS and UAI are deprecated in CSM 1.5.2 and will be removed in CSM 1.6.

Kubernetes uses [resource limits and resource requests](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource), to manage the system resources available to pods.
Because UAIs run as pods under Kubernetes, UAS takes advantage of Kubernetes to manage the system resources available to UAIs.

In the UAS configuration, resource specifications contain that configuration. A UAI that is assigned a resource specification will use that instead of the default resource limits or requests on the Kubernetes namespace containing the UAI.
This can be used to fine-tune resources assigned to UAIs.

[Top: User Access Service (UAS)](README.md)

[Next Topic: List UAI Resource Specifications](List_UAI_Resource_Specifications.md)
