# Ingress Routing

Ingress routing to services via Istio's ingress gateway is configured by `VirtualService` custom resource definitions \(CRD\). When using external hostnames, there needs to be a `VirtualService` CRD that matches the external hostname to the desired destination.

For example, the configuration below controls the ingress routing for `grafana.cmn.SYSTEM_DOMAIN_NAME`:

```bash
kubectl get vs -n sysmgmt-health cray-sysmgmt-health-grafana
```

Example output:

```text
NAME                             GATEWAYS                      HOSTS                              AGE
cray-sysmgmt-health-grafana   [services/services-gateway]   [grafana.cmn.SYSTEM_DOMAIN_NAME]   22h
```

```bash
kubectl get vs -n sysmgmt-health cray-sysmgmt-health-grafana -o yaml
```

Example output:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  annotations:
    meta.helm.sh/release-name: cray-sysmgmt-health
    meta.helm.sh/release-namespace: sysmgmt-health
  creationTimestamp: "2024-10-15T12:59:14Z"
  generation: 1
  labels:
    app: cray-sysmgmt-health-grafana
    app.kubernetes.io/instance: cray-sysmgmt-health
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: cray-sysmgmt-health
    app.kubernetes.io/version: 0.17.5
    helm.sh/chart: cray-sysmgmt-health-1.0.14-20241001112803_a342aa8
  name: cray-sysmgmt-health-grafana
  namespace: sysmgmt-health
  resourceVersion: "147358949"
  uid: c0093cce-f246-40d9-a733-226092e72ecb
spec:
  gateways:
  - services/services-gateway
  - services/customer-admin-gateway
  hosts:
  - grafana.cmn.mug.hpc.amslabs.hpecorp.net
  http:
  - match:
    - authority:
        exact: grafana.cmn.mug.hpc.amslabs.hpecorp.net
    route:
    - destination:
        host: cray-sysmgmt-health-grafana
        port:
          number: 80
      headers:
        request:
          add:
            X-WEBAUTH-USER: admin
          remove:
          - Authorization

```

By matching the external hostname in the authority field, Istio's ingress gateway is able to route incoming traffic from OAuth2 Proxy to the `cray-sysmgmt-health-grafana` service in the `sysmgmt-health`
namespace. Also, notice that the `VirtualService` for `grafana.cmn.SYSTEM_DOMAIN_NAME` uses the existing `services/services-gateway` Gateway CRD and does not create a new one.

## Secure Ingress via OAuth2 Proxy

Web apps intended to be accessed via the browser, such as  Alertmanager, Grafana, Kiali, Kibana, Elasticsearch, should go through the OAuth2 Proxy reverse proxy. Browser sessions are
automatically configured to use a JSON Web Token \(JWT\) for authorization to Istio's ingress gateway, enabling a central enforcement point of Open Policy Agent \(OPA\) policies for system management traffic.

The OAuth2 Proxy will inject HTTP headers so that an upstream endpoint can identify the user and customize access as needed. To enable ingress via OAuth2 Proxy external hostnames, web apps need to be added to
the `proxiedWebAppExternalHostnames` for the appropriate ingress (`customerManagement`, `customerAccess`, or `customerHighSpeed`) in `customizations.yaml` (`i.e sma-grafana.cmn.{{ network.dns.external }}`).
