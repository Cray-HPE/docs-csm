# Externally Exposed Services

The following services are exposed on one or more of the external networks \(CMN, CAN, and CHN)\. Each of these services requires an IP address in the relevant subnets so they are reachable on that network. This IP address is allocated by the MetalLB component.

Services under Istio Ingress Gateway and OAuth2 Proxy Ingress share an ingress, so they all use the IP allocated to the Ingress.

Each service is given a DNS name that is served by the PowerDNS service to make them resolvable from the site network. This makes it possible to access each of these services by name rather than finding the
allocated IP. The DNS name and network are prepended to the `system-name.site-domain` specified during `csi config init`. For example, if the system is named `TestSystem`, and the site is `example.com`, the
HPE Cray EX domain would be `testsystem.example.com`.

See [External DNS](../external_dns/External_DNS.md) for more information.

| Service                                | DNS Name       | Address Pool                           | Requires CMN/CAN/CHN IP | External Port      | Notes                                                      |
|----------------------------------------|----------------|----------------------------------------|-------------------------|--------------------|------------------------------------------------------------|
| Istio Ingress Gateway - CMN            |                | customer-management                    | Yes                     | 80/443, 8081, 8888 |                                                            |
| Istio Ingress Gateway - CAN            |                | customer-access                        | Yes                     | 80/443, 8081, 8888 |                                                            |
| Istio Ingress Gateway - CHN            |                | customer-high-speed                    | Yes                     | 80/443, 8081, 8888 |                                                            |
| HPE Cray EX REST API                   | `api`          |                                        |                         | No                 | Uses the IP address of Istio Ingress Gateway (CMN/CAN/CHN) |
| Authentication                         | `auth`         |                                        |                         | No                 | Uses the IP address of Istio Ingress Gateway (CMN/CAN/CHN) |
| S3                                     | `s3`           | customer-management                    | Yes                     | 8080               |                                                            |
| PowerDNS                               |                | customer-management                    | Yes                     | 53                 |                                                            |
| OAuth2 Proxy Ingress - CMN             |                | customer-management                    | Yes                     | 443                |                                                            |
| OAuth2 Proxy Ingress - CAN             |                | customer-access                        | Yes                     | 443                |                                                            |
| OAuth2 Proxy Ingress - CHN             |                | customer-high-speed                    | Yes                     | 443                |                                                            |
| System Management Health Prometheus    | `prometheus`   |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| System Management Health Alert Manager | `alertmanager` |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| System Management Health Grafana       | `grafana`      |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| Istio Kiali                            | `kiali-istio`  |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| VCS                                    | `vcs`          |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| SMA Kibana                             | `sma-kibana`   |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| SMA Grafana                            | `sma-grafana`  |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| OPA GPM                                | `opa-gpm`      |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| CSMS                                   | `csms`         |                                        |                         | No                 | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| Nexus                                  | `nexus`        |                                        |                         | No                 | Uses the IP address of Istio Ingress Gateway (CMN)         |
| Rsyslog Aggregator                     | `rsyslog`      | customer-management                    | Yes                     | 514/8514           |                                                            |
| UAI                                    |                | customer-access or customer-high-speed | Yes \(multiple\)        | 22                 | Can be several of these each with a unique ID              |
| IMS                                    | `<uid\>.ims`   | customer-management                    | Yes \(multiple\)        | 22                 | Can be several of these each with a unique ID              |
