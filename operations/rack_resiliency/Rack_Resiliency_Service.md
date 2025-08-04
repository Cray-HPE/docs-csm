# Rack Resiliency Service(RRS)

Rack Resiliency Service has been introduced as a part of CSM 1.7.0 to provide tolerance against single rack failures. The management plane of CSM is discovered as part of setting up rack resiliency and the management plane is divided into management failure doimains(`MFDs`). Each MFD consists of a minimum hardware configuration as described in [Zones](/docs-csm/operations/rack_resiliency/Zones.md).

Rack Resiliency Service comprises of the following components:
- [Zones](/docs-csm/operations/rack_resiliency/Zones.md)
- [ConfigMaps](/docs-csm/operations/rack_resiliency/ConfigMaps.md)
- [Resiliency Monitoring Service(RMS)](/docs-csm/operations/rack_resiliency/Resiliency_Monitoring_Service.md)
- [API Service](../../api/rrs.md)

Rack Resiliency Service ensures that critical services required to run user jobs are spread across zones and monitors whether these services are running and continued to be balanced across zones.

For information on how RRS spreads the critical services, refer to [kyverno policy](../rack_resiliency/kyverno.md).
For more information on how RRS monitors the critical services, refer to [Resiliency Monitoring Service(RMS)](/docs-csm/operations/rack_resiliency/Resiliency_Monitoring_Service.md)
