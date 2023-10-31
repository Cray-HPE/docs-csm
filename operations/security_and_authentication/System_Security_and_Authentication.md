# System Security and Authentication

The system uses a number of mechanisms to ensure the security and authentication of internal and external requests.

- [API gateway service](#api-gateway-service)
- [Keycloak](#keycloak)
- [JSON Web Tokens (JWTs)](#json-web-tokens-jwts)
- [Security infrastructure](#security-infrastructure)
- [Istio ingress gateway](#istio-ingress-gateway)

## API gateway service

The Cray API gateway service provides a common access gateway for all of the systems management REST APIs.
Authentication is provided by an Identity and Access Management \(IAM\) service that integrates with Istio.

## Keycloak

Keycloak is an open source Identity and Access Management \(IAM\) solution. It provides authentication and authorization
services that are used to secure access to services on the system.

To learn more about Keycloak, see:

- [Security and authentication](../index.md#security-and-authentication)
- [Keycloak home page](https://www.keycloak.org/)

## JSON Web Tokens (JWTs)

The approach for system management authentication and authorization is to leverage the OpenID Connect standard, as much
as practical. OpenID Connect consists of a specific application of the OAuth v2.0 standard, which leverages the use of JWTs.

## Security infrastructure

![Security Infrastructure](../../img/operations/Security_Infrastructure.png "Security Infrastructure")

## Istio ingress gateway

All connections through the Istio ingress gateway require authentication with a valid JWT from Keycloak, except for the
following endpoints accessed via the `shasta` external hostname:

- `/keycloak`
- `/apis/tokens`
- `/vcs`
- `/spire-jwks-`
- `/spire-bundle`
- `/meta-data`
- `/user-data`
- `/phone-home`
- `/repository`
- `/v2`
- `/service/rest`
- `/capsules/`
