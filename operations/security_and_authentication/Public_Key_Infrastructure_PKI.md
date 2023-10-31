# Public Key Infrastructure \(PKI\)

Public Key Infrastructure \(PKI\) represents the algorithms, infrastructure, policies, and processes required to leverage
applied public key cryptography methods for operational security use cases. The Rivest-Shamir-Adleman \(RSA\) and
Elliptic-curve \(ECC\) are some example algorithm systems.

The use of PKI for the system is in the Transport Layer Security \(TLS\) protocol, which is the successor of the now deprecated
Secure Sockets Layer \(SSL\). This is where trusted chains of Certificate Authorities \(CAs\) are used to authenticate the identity
of servers and sometimes clients \(for example, mutual TLS\) for relying parties. This chain of trust is anchored by a root CA and
is used to make assertions that a particular public and private key pair belong to a given party by assigning a certificate for the
party. This party is still required to prove they actually own the key material through enciphering, deciphering, and digital
signature operations that require private keys that are not shared among parties. However, public keys are shared through
certificates and are policy bound in that respect.

The post-installation PKI implementation for the system is made up of Kubernetes services \(illustrated in the
figure below\). During installation, either the platform can be directed to generate certificate authorities \(CAs\), or a
customer-supplied intermediate CA can be supplied. After installation, the CA material resides in a Kubernetes Secret, and
ultimately in the HashiCorp Vault.

![Public Key Infrastructure](../../img/operations/PKI_Infrastructure.png)

Refer to [PKI Services](PKI_Services.md) for more information on the services in the figure above.

## Limitations

The following limitations exist within the PKI implementation:

- [Cert-manager renewal](#cert-manager-renewal)
- [Supported cryptography suites](#supported-cryptography-suites)
- [CA rotation](#ca-rotation)
- [Implications of transitive trust](#implications-of-transitive-trust)
- [Abuse of PKI APIs to sign malicious products](#abuse-of-pki-apis-to-sign-malicious-products)
- [Security of CA material](#security-of-ca-material)
- [Revocation lists and Online Certificate Status Protocol (OCSP)](#revocation-lists-and-online-certificate-status-protocol-ocsp)
- [Key escrow](#key-escrow)

### Cert-manager renewal

An outstanding bug in the Keycloak Gatekeeper service prevents it from updating its TLS certificate and key material upon
Cert-manager renewal. It may be necessary to monitor the situation and proactively renew or force reload Keycloak Gatekeeper.

### Supported cryptography suites

RSA-based CAs and certificates are currently supported. CAs must have either a 3072- or 4096-bit modulus and use SHA256 as the
signature algorithm. Installation paths are designed to force convention.

Password-encrypted private keys are not currently supported.

### CA rotation

Changing the platform CA post-installation is not currently supported. Changing it requires a re-install.

### Implications of transitive trust

If the platform is configured to generate a dynamic CA, then customer services or users that interact with the platform must
trust the platform CA to validate TLS sessions. Thus, provided the platform has a disjoint DNS domain name \(for example,
`shasta.acme.org`\), and the PKI trust realm is established at this FQDN or a subdomain of this FQDN, then a compromise of
platform CA material should be limited to the platform itself \(subject to many nuances\).

If a customer supplies a CA to the platform, and the CA is part of an expanded PKI trust realm, then a compromise of platform
CA material could be leveraged to compromise the broader environment through PKI APIs available on the system. Customers should
consider this risk, and, if providing a CA is desired, consider strictly limiting the PKI trust realm established by the provided CA.

### Abuse of PKI APIs to sign malicious products

Compromise of a platform could lead to the generation of certificates for potentially malicious workloads.
Current HashiCorp Vault policies that control legitimate signing activities are fairly broad in allowed certificate CSR
properties. This is due largely to common name and SAN requirements for certificate workloads across the platform.

### Security of CA material

During installation, CA material is exposed in the following cases:

- When they are staged by the installer
- By installation processes \(e.g., `shasta-cfg`\)

After installation, CA material is exposed in the following cases:

- In a SealedSecret
- In a Kubernetes Secret
- In Kubernetes etcd backups and other backups taken of the platform
- To Vault
- Through the creation of additional subordinate CAs for Spire

### Revocation lists and Online Certificate Status Protocol (OCSP)

The platform does not provide revocation lists or access to a revocation service \(OCSP\).

### Key escrow

The platform does not provide any key escrow services.
