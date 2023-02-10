# TLS Certificates for Redfish BMCs

Redfish HTTP communications are capable of using TLS certificates and Certificate Authority \(CA\) trust
bundles to improve security. Several Hardware Management Services \(HMS\) have been modified to enable the
HTTP transports used for Redfish communications to use a CA trust bundle.

The following services communicate with Redfish BMCs:

- State Manager Daemon \(SMD\) aka Hardware State Manager \(HSM\)
- Cray Advanced Platform Monitoring and Control \(CAPMC\)
- Power Control Service \(PCS\)
- Firmware Action Service \(FAS\)
- HMS Collector
- River Endpoint Discovery Service \(REDS\)
- Mountain Endpoint Discovery Service \(MEDS\)

Each Redfish BMC must have a TLS certificate in order to be useful. The certificates will come from the same
PKI that issues the CA trust bundle. The Vault PKI is used to create the TLS certs. Services will get the CA
trust bundle either directly from the Vault PKI, or it can be read in via a Kubernetes ConfigMap.

## TLS Certificate Creation

TLS certificates are created by the System Configuration Service \(SCSD\) tool and are stored in Vault secure
storage for later retrieval. Each certificate can be created at any level or domain from the individual BMC,
all the way up to a cabinet-level. Any certificate created above the BMC domain will contain enough Subject
Alternative Names \(SANs\) to cover that domain. The goal and intent is to create certificates at the cabinet
domain, containing the SANs for every possible BMC in that cabinet.

Refer to [Add TLS Certificates to BMCs](Add_TLS_Certificates_to_BMCs.md) for the SCSD commands used to create
and store the certificates.

Once the certificates are created, they can be placed on the target BMCs again using SCSD. Only liquid-cooled
BMCs can have TLS certificates set in them.

## CA Bundle Usage By Services

Services will use a CA trust bundle when creating secured/validated HTTP clients and transports for use in
Redfish operations. Any services that communicate with other services must not use this same client/transport
because these services are within the service mesh and do not use TLS certificates. Thus, most services will
need different HTTP clients/transports for Redfish and for inter-service communications.

The CA trust bundle is placed into a file visible by each HMS service. The Helm chart for each service will
specify where this file is located. In addition, there is an environment variable \(CA\_URI\) that comes from
a value in `customizations.yaml` and will direct the service to point to either the Vault PKI's CA bundle or to
the ConfigMap bundle.

If the CA\_URI variable is an empty string, it means that the `customizations.yaml` has no special entry for it.
In this event, each service is set up to not use a CA bundle for Redfish HTTP clients/transports. Thus, this
implementation is very backward compatible.
