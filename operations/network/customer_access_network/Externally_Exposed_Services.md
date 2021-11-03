## Externally Exposed Services

The following services are exposed on the Customer Access Network \(CAN\). Each of these services requires an IP address on the CAN subnet so they are reachable on the CAN. This IP address is allocated by the MetalLB component.

Services under Istio Ingress Gateway and Keycloak Gatekeeper Ingress share an ingress, so they all use the IP allocated to the Ingress.

Each service is given a DNS name that is served by the External DNS service to make them resolvable from the site network. This makes it possible to access each of these services by name rather than finding the allocated IP. The DNS name is pre-pended to the `system-name.site-domain` specified during `csi config init`. For example, if the system is named TestSystem, and the site is example.com, the HPE Cray EX domain would be testsystem.example.com.

See [External DNS](../external_dns/External_DNS.md) for more information.

|Service|DNS Name|Address Pool|Requires CAN IP|External Port|Notes|
|-------|--------|------------|---------------|-------------|-----|
|Istio Ingress Gateway| |customer-access|Yes|80/443, 8081, 8888| |
| HPE Cray EX REST API |api|| |No| Uses the IP of<br/>Istio Ingress<br/>Gateway |
| Authentication |auth|| |No| Uses the IP of<br/>Istio Ingress<br/>Gateway |
|S3|s3|customer-access|Yes|8080| |
|External DNS| |customer-access|Yes|53| |
|Keycloak Gatekeeper Ingress| |customer-access|Yes|443| |
| Sysmgmt-health Prometheus |prometheus|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| Sysmgmt-health Alert Manager |alertmanager|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| Sysmgmt-health Grafana |grafana|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| Istio Kiali | kiali-istio      || |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| Istio Jaeger |jaeger-istio|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| VCS |vcs|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| SMA Kibana |sma-kibana|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| SMA Grafana |sma-grafana|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
| Nexus |nexus|| |No| Uses the IP of<br/>Keycloak<br/>Gatekeeper<br/>Ingress |
|Rsyslog Aggregator|rsyslog|customer-access|Yes|514/8514| |
|UAI| |customer-access|Yes \(multiple\)|22|Can be several of these each with a unique ID|
|IMS|<uid\>.ims|customer-access|Yes \(multiple\)|22|Can be several of these each with a unique ID|



