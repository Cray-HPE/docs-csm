## Pod Resource Limits

Kubernetes uses resource requests and Quality of Service \(QoS\) for scheduling pods. Resource requests can be provided explicitly for pods and containers, whereas pod QoS is implicit, based on the resource requests and limits of the containers in the pod. There are three types of QoS:

- Guaranteed: All containers in a pod have explicit memory and CPU resource requests and limits. For each resource, the limit equals the request.
- Burstable: Does not meet Guaranteed requirements, but some of the containers have explicit memory and CPU resource requests or limits.
- BestEffort: None of the containers specify any resources.

Kubernetes will best be able to schedule pods when there are resources associated with each container in each pod.

### Resource Limits

For systems, all containers should have explicit resource requests and limits. Most pods should fall into the Burstable category. Containers that have resource requests equal to the resource limits should be reserved for very well behaved containers, and will usually be simple, single-function containers. One example of this could be an init container that is waiting for another resource to become available.

Resource limits are set by default at the namespace level, but pods within that namespace can increase or decrease their limits depending on the nature of the workload.



