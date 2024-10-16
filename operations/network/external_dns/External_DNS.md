# External DNS

External DNS, along with the customer accessible networks CMN and CAN/CHN, PowerDNS, Border Gateway Protocol \(BGP\), and MetalLB, makes it simpler to access the HPE Cray EX API and system management services.
Services are accessible directly from a laptop without needing to tunnel into a non-compute node \(NCN\) or override /etc/hosts settings. Some services may require a JSON Web Token \(JWT\) to access them, while
others may require OAuth2 to login using a DC LDAP password.

![External DNS](../../../img/operations/ExternalDNS.png "External DNS")

The following services are currently available:

- HPE Cray EX API \(requires valid JWT\)
- Keycloak
- Ceph RADOS gateway \(requires valid JWT\)
- Nexus
- System Management Health Vmselect \(redirects to OAuth2 Proxy for SSO\)
- System Management Health Grafana \(redirects to OAuth2 Proxy for SSO\)
- System Management Health Alertmanager \(redirects to OAuth2 Proxy for SSO\)
- Kiali, for Istio service mesh visibility \(redirects to OAuth2 Proxy for SSO\)

In general, external hostnames should resolve to a external IP address for one of the following services:

- `istio-system/istio-ingressgateway-cmn` - Istio's ingress gateway on CMN.
- `istio-system/istio-ingressgateway-can` - Istio's ingress gateway on CAN.
- `istio-system/istio-ingressgateway-chn` - Istio's ingress gateway on CHN.
- `services/cray-oauth2-proxies-customer-access-ingress` - OAuth2 Proxy's ingress on CMN that redirects browsers to Keycloak for log in, and then to Istio's ingress gateway with a valid JWT for authorized access.
- `services/cray-oauth2-proxies-customer-management-ingress` - OAuth2 Proxy's ingress on CAN that redirects browsers to Keycloak for log in, and then to Istio's ingress gateway with a valid JWT for authorized access.
- `services/cray-oauth2-proxies-customer-high-speed-ingress` - OAuth2 Proxy's ingress on CHN that redirects browsers to Keycloak for log in, and then to Istio's ingress gateway with a valid JWT for authorized access.

This can be verified using the dig command to resolve the external hostname and compare it with Kubernetes.

## What Happens if External DNS is not Used?

Without forwarding to External DNS, administrators will not have the ability to use the externally exposed services, such as Prometheus, Grafana, the HPE Cray EX REST API, and more.
See [Externally Exposed Services](../customer_accessible_networks/Externally_Exposed_Services.md) for more information.

Accessing most of these services by IP address will not work because the Ingress Gateway uses the name to direct requests to the appropriate service.

## DNS for HPE Cray EX Systems

There is a separate set of DNS instances within HPE Cray EX that is used by the nodes and pods within the system for resolving names.

- **Unbound**

    The unbound DNS instance is used to resolve names for the physical equipment on the management networks within HPE Cray EX, such as NCNs, UANs, switches, compute nodes, and more. This instance is accessible only within the system.

- **Kubernetes CoreDNS**

    There is a CoreDNS instance within Kubernetes that is used by Kubernetes pods to resolve names for internal pods and services. This instance is accessible only within the HPE Cray EX Kubernetes cluster.

## Connect Customer DNS to PowerDNS

The DNS instance at the customer site should use DNS forwarding to forward the subdomain specified by the `system-name` and `site-domain` values \(combined to make the `system-name.site-domain` value\) to the IP
address specified by the `cmn-external-dns` value. These values are defined with the `csi config init` command. The specifics on how to do the forwarding configuration is dependent on the type of DNS used by the
customer.
