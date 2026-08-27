# Externally Exposed Services

This page lists services that are exposed on one or more of the external networks
([CMN][cmn], [CAN][can], and [CHN][chn]). Each of these services requires an IP
address in the relevant subnets, in order to be reachable on that network. This IP
address is allocated by the MetalLB component.

Services under Istio Ingress Gateway and OAuth2 Proxy Ingress share an ingress,
so they all use the IP address allocated to the Ingress.

Each service is given a DNS name that is served by the PowerDNS service to make
them resolvable from the site network. This makes it possible to access each of
these services by name rather than finding the allocated IP address. The DNS name
and network are prepended to the `system-name.site-domain` specified during
[`csi config init`][csi]. For example, if the system is named `TestSystem`, and the
site is `example.com`, then the HPE Cray EX domain would be `testsystem.example.com`.

See [External DNS](../external_dns/External_DNS.md) for more information.

| *Service*                              | *DNS name*     | *Address pool*        | *Requires CMN/CAN/CHN IP?* | *External ports*   | *Notes*                                                    |
|----------------------------------------|----------------|-----------------------|----------------------------|--------------------|------------------------------------------------------------|
| Istio Ingress Gateway - [CMN][cmn]     |                | `customer-management` | Yes                        | 80/443, 8081, 8888 |                                                            |
| Istio Ingress Gateway - [CAN][can]     |                | `customer-access`     | Yes                        | 80/443, 8081, 8888 |                                                            |
| Istio Ingress Gateway - [CHN][chn]     |                | `customer-high-speed` | Yes                        | 80/443, 8081, 8888 |                                                            |
| HPE Cray EX REST API                   | `api`          |                       |                            |                    | Uses the IP address of Istio Ingress Gateway (CMN/CAN/CHN) |
| Authentication                         | `auth`         |                       |                            |                    | Uses the IP address of Istio Ingress Gateway (CMN/CAN/CHN) |
| [S3][s3]                               | `s3`           | `customer-management` | Yes                        | 8080               |                                                            |
| PowerDNS                               |                | `customer-management` | Yes                        | 53                 |                                                            |
| OAuth2 Proxy Ingress - [CMN][cmn]      |                | `customer-management` | Yes                        | 443                |                                                            |
| OAuth2 Proxy Ingress - [CAN][can]      |                | `customer-access`     | Yes                        | 443                |                                                            |
| OAuth2 Proxy Ingress - [CHN][chn]      |                | `customer-high-speed` | Yes                        | 443                |                                                            |
| System Management Health Vmselect      | `vmselect`     |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| System Management Health Alert Manager | `alertmanager` |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| System Management Health Grafana       | `grafana`      |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| Istio Kiali                            | `kiali-istio`  |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| [VCS][vcs]                             | `vcs`          |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| [SMA][sma] Kibana                      | `sma-kibana`   |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| [SMA][sma] Grafana                     | `sma-grafana`  |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| OPA GPM                                | `opa-gpm`      |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| CSMS                                   | `csms`         |                       |                            |                    | Uses the IP address of OAuth2 Proxy Ingress (CMN)          |
| Nexus                                  | `nexus`        |                       |                            |                    | Uses the IP address of Istio Ingress Gateway (CMN)         |
| Rsyslog Aggregator                     | `rsyslog`      | `customer-management` | Yes                        | 514/8514           |                                                            |
| [IMS][ims]                             | `<uid>.ims`    | `customer-management` | Yes (multiple)             | 22                 | There may be several of these, each with a unique ID       |

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cmn]: ../../../glossary.md#customer-management-network-cmn
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
