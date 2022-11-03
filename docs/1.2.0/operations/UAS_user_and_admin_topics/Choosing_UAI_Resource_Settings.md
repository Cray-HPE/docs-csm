# Choosing UAI Resource Settings

The [Resource Specifications](Resource_Specifications.md) and [UAI Classes](UAI_Classes.md) sections describe how to set up resource specifications to be used with UAIs.
Refer to those sections for all procedures and specific data structures associated with resources. In this section the question of how and why to configure UAI resources is addressed.
While Kubernetes resource requests and limits can be used for other things, this section focuses on memory requests and limits and CPU requests and limits. Other resource types are outside the scope of this discussion.

Before discussing why custom resource specifications might be used, it is worthwhile to understand how Kubernetes behaves with respect to resources.

Kubernetes uses resource requests and limits on all of its pods (a UAI is, at its most basic, a Kubernetes pod) to determine where and whether to schedule the pod.
Kubernetes will not schedule work on a host node if the pod containing that work requests more CPU or memory (or any other resource) than the host node has available.
Once a request for resources has been granted by the scheduler, and the pod (UAI in this case) has been scheduled there, the available resources on the host node are reduced by the requested amount.
It is possible for a resource specification to set a high limit and a low request, in which case many pods (UAIS) may be scheduled on the available host nodes.
In this case, there is a risk of oversubscription as these pods grow into their limits. When Kubernetes detects resource pressure on a host node, it starts evicting pods from that node.
If Kubernetes can find another host node with available space, it will reschedule an evicted pod (UAI) on that node. If not, the pod will remain evicted until a host node with sufficient resources becomes available.

The most common reason to set custom resource limits on a class of UAIs is that the workflows within those UAIs are more computationally or memory intensive than the default namespace resources support.
In this case, the site should determine what the bottleneck is (memory or CPU) and experiment with larger settings. Note that by increasing a resource request or limit on a UAI Class you decrease the capacity of the UAI host nodes for UAIs of that class.
Also note that, while it may be tempting to set low request values and higher limit values, the resulting potential oversubscription of nodes can make UAIs unstable and difficult to use.

Another reason for setting custom resource limits on a class of UAIs is that the UAIs are very lightweight and do not need the default namespace resource requests / limits.
This can increase the capacity of the pool of available UAI host nodes, for UAIs of that class. The caveat here is that Kubernetes will terminate any pod (UAI) that tries to grow past its resource limits.
Making the resource limits on UAI Classes too small can lead to instability of UAIs of that class.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Setting End-User UAI Timeouts](Setting_UAI_Timeouts.md)
