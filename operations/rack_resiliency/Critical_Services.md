# Critical Services

Critical services are defined as those services that are critical to execution of user jobs. These services are critical because the user plane / jobs require a timely response from these critical services for continued operations. Therefore, in the context of a rack failure, it is crucial that such critical services have replicas and resiliency across racks. This is the set of services that Rack Resiliency is trying to make resilient.

HPE provides a standard set of critical services which are needed for the successful execution of user jobs. 
However, it possible to add additional critical services to the list. For further information on managing the critical services, refer to [Manage Critical Service](Manage_Critical_Services.md)

The Resiliency Monitoring Service and the API service monitor and manage the critical services using a set of configmaps. For more details on the configmaps and its attributes refer to [ConfigMaps](ConfigMaps.md).