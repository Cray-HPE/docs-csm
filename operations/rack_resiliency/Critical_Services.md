# Critical Services

In the context of Rack Resiliency, the term "critical services" refers to those Kubernetes
services which RR is monitoring and trying to make resilient. RR supports Kubernetes
Deployments and StatefulSets as critical services.

HPE has prepopulated the RR critical services with the set of services necessary for the successful
execution of user jobs. Note that this does not include all services that could
reasonably be considered critical to the system overall. For example, the
[Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) and the
[Power Control Service (PCS)](../../glossary.md#power-control-service-pcs) are both necessary for
booting compute nodes. However, because they are not necessary for executing user jobs, they are not
included in the default RR critical services list. It possible to add additional critical services
to the list. For more information on managing the critical services, see
[Manage Critical Service](Manage_Critical_Services.md).

Internally, the RR API service and the [Resiliency Monitoring Service](Resiliency_Monitoring_Service.md)
manage the critical services using a set of Kubernetes ConfigMaps. For more details, see
[ConfigMaps](ConfigMaps.md).
