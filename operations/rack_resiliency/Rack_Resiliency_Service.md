# Rack Resiliency Service (RRS)

Rack Resiliency Service has been introduced as a part of CSM 1.7.0 to to monitor critical services and provide alerts during node or rack failures.

Rack Resiliency Service comprises of the following components:

- [Zones](Zones.md)
- [ConfigMaps](ConfigMaps.md)
- [Resiliency Monitoring Service(RMS)](Resiliency_Monitoring_Service.md)
- [API Service](../../api/rrs.md)

Rack Resiliency Service monitors critical services required to run user jobs and checks whether these services are spread across zones and are balanced equally across zones.

For more information on how RRS monitors the critical services, refer to [Resiliency Monitoring Service(RMS)](Resiliency_Monitoring_Service.md)
