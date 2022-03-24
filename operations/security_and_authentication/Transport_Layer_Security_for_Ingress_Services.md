# Transport Layer Security \(TLS\) for Ingress Services

The Istio Secure Gateway and Keycloak Gatekeeper services utilize Cert-manager for their Transport Layer Security \(TLS\) certificate and private key. Certificate custom resource definitions are deployed as part of Helm Charts for these services.

To view properties of the Istio Secure Gateway certificate:

```bash
# kubectl describe certificate -n istio-system ingress-gateway-cert
```

To view the properties of the Keycloak Gatekeeper certificate:

```bash
# kubectl describe certificate -n services keycloak-gatekeeper
```

An outstanding bug in the Keycloak Gatekeeper service prevents it from updating its TLS certificate and key material upon Cert-manager renewal. Thus, it may be necessary to monitor the situation and proactively renew/force reload Keycloak Gatekeeper.

