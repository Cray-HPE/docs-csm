# Certificate Types

The system software installation process creates an X.509 Certificate Authority \(CA\) on the primary non-compute node \(NCN\) and uses the CA to create an NCN host X.509 certificate. This host certificate is used during the
installation process to configure the API gateway for TLS so that communications to the gateway can use HTTPS.

Clients should use HTTPS to talk to services behind the API gateway and need to ensure that the NCN CA certificate is known by the client software when making requests.

Keycloak, which is the Identity and Access Management \(IAM\) server, will also have a certificate created at install time for the `Shasta` realm. This certificate is known as the `Shasta` realm certificate and is used when
signing a [JSON Web Token (JWT)](../../glossary.md#json-web-token-jwt). The `Shasta` realm certificate is registered with the API gateway and is used by the API gateway to validate that a JWT passed when requests are made
actually originate from the IAM server.

This document does not cover the process for updating any of the certificates described below.

- [NCN CA certificate](#ncn-ca-certificate)
- [NCN host certificate](#ncn-host-certificate)
- [API gateway TLS certificate](#api-gateway-tls-certificate)
- [IAM service `Shasta` realm JWT certificate](#iam-service-shasta-realm-jwt-certificate)

## NCN CA certificate

The NCN CA is created by the installer and located on `ncn-s001` at `/var/opt/cray/certificate_authority/certificate_authority.crt`.
The signature algorithm used is `sha256WithRSAEncryption` and the key length is 2048 bits. The CA `Issuer` is generated at the time of creation and therefore
specific to each installation.

(`ncn-s001#`) This and other certificate details can be viewed by executing:

```bash
openssl x509 -in /var/opt/cray/certificate_authority/certificate_authority.crt -noout -text
```

## NCN host certificate

The NCN host certificate is created by the installer and located at `sms-1:/var/opt/cray/certificate\_authority/hosts/host.crt`

The signature algorithm used is `sha256WithRSAEncryption` and the key length is 2048 bits.

(`ncn#`) Additional certificate details can be viewed by executing:

```bash
openssl x509 -in /var/opt/cray/certificate_authority/hosts/host.crt -noout -text
```

## API gateway TLS certificate

The API gateway is configured with the NCN host certificate and key to allow enabling TLS/HTTPS on the gateway. Configuration details are handled by the installer when the API
gateway Kubernetes pods are created.

## IAM service `Shasta` realm JWT certificate

The IAM service \(Keycloak\) `Shasta` realm contains an RSA certificate. This is known as the realm certificate. The realm certificate is used by the API gateway during JWT validation.

The installer adds a `Shasta` realm to the IAM service. The RSA realm certificate is created as part of that process. This certificate can be viewed from the Keycloak `Admin Console`
by selecting the `Shasta` realm, then `Realm Settings`, then `Keys` tab. The certificate can be viewed by clicking the `Public Key` button for the RSA certificate. The key length is 2048 bits.
