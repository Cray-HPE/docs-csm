# Access to System Management Services

The standard configuration for System Management Services \(SMS\) is the containerized REST micro-service with a public API. All of the micro-services provide an HTTP interface and are collectively exposed through a single gateway URL. The API gateway for the system is available at a well known URL based on the domain name of the system. It acts as a single HTTPS endpoint for terminating Transport Layer Security \(TLS\) using the configured certificate authority. All services and the API gateway are not dependent on any single node. This resilient arrangement ensures that services remain available during possible underlying hardware and network failures.

Access to individual APIs through the gateway is controlled by a policy-driven access control system. Administrators and users must retrieve a token for authentication before attempting to access APIs through the gateway and present a valid token with each API call. The authentication and authorization decisions are made at the gateway level which prevent unauthorized API calls from reaching the underlying micro-services. Refer to [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) for more detail on the process of obtaining tokens and user management.

Review the API documentation in the supplied container before attempting to use the API services. This container is generated with the release using the most current API descriptions in OpenAPI 2.0 format. Because this file serves as both an internal definition of the API contract and the external documentation of the API function, it is the most up-to-date reference available.

The API Gateway URL for accessing the APIs on a site-specific system is https://api.SYSTEM-NAME_DOMAIN-NAME/apis/.

The internal URL from a local console on any of the NCNs is https://api-gw-service-nmn.local/apis.

