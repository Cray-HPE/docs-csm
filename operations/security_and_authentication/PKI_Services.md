# PKI Services

The services in this section are integral parts of the Public Key Infrastructure \(PKI\) implementation.

- [HashiCorp Vault](#hashicorp-vault)
- [Jetstack Cert-manager](#jetstack-cert-manager)
- [TrustedCerts Operator](#trustedcerts-operator)

## HashiCorp Vault

A deployment of HashiCorp Vault, managed via the Bitnami `Bank-vaults` operator, stores private and public
Certificate Authority \(CA\) material, and serves APIs through a PKI engine instance. This instance also serves as a general
secrets engine for the system.

Kubernetes service account authorization is utilized to authenticate access to Vault. The configuration of Vault, as deployed on
the system, can be viewed with the following command:

```bash
ncn-mw# kubectl get vault -n vault cray-vault -o yaml
```

A Kubernetes operator manages the deployment of Vault, based on this definition. The resulting instance is deployed to the `vault` namespace.

**IMPORTANT:** Changing the `cray-vault` custom resource definition is not supported unless directed by customer support.

For more information, refer to the following resources:

- [HashiCorp Vault](HashiCorp_Vault.md)
- [`Bank-vault` external documentation](https://banzaicloud.com/docs/bank-vaults/overview/)
- [Vault external documentation](https://www.vaultproject.io/docs)

## Jetstack Cert-manager

A deployment of Jetstack Cert-manager provides a Kubernetes-native API to request x.509 certificates and perform key management operations.

Cert-manager is integrated with HashiCorp Vault for use as a CA. Cert-manager generates key material and a certificate signing request
\(CSR\), and then submits the CSR to Vault for signature. Once Vault has signed the certificate, it is made available, along with other
key materials, via a Kubernetes Secret. Kubernetes pods or other platform-aware components can then source the resulting secret.

Cert-manager will also automatically manage renewal of certificates prior to their expiration time. Cert-manager is deployed on the
system using namespace-specific certificate issuers.

To view issuers:

```bash
ncn-mw# kubectl get issuer -A -o wide
```

To view certificates:

```bash
ncn-mw# kubectl get certificate -A -o wide
```

Once a certificate is ready, the resulting secret will contain the following data fields:

| Field   | Description                                                                               |
|---------|-------------------------------------------------------------------------------------------|
| `ca.crt`  | Contains trusted CA certificates                                                          |
| `tls.crt` | Contains the generated certificate, along with trusted CA certificates in the trust chain |
| `tls.key` | Contains the private key                                                                  |

To view certificate signing requests:

```bash
ncn-mw# kubectl get certificaterequest -A -o wide
```

The Cert-manager workload is deployed to the `cert-manager` namespace.

For more information, see the [Cert-manager external documentation](https://cert-manager.io/docs/).

## TrustedCerts Operator

The TrustedCerts Operator is an HPE Kubernetes Operator. It acts on the `TrustedCertificates` custom resource definitions. Its
function is to source CA certificates via use of a Vault API, and then distribute them.

To see the deployed `TrustedCertificates` resources:

```bash
ncn-mw# kubectl get trustedcertificates -A
```

These resources can be used to further examine the ConfigMap and [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss)
destination references. The TrustedCerts workload is deployed to the `pki-operator` namespace.
