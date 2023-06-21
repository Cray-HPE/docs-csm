# Add TLS Certificates to BMCs

Use the System Configuration Service \(SCSD\) tool to create TLS certificates and store them in Vault secure storage. Once certificates are created, they are placed on to the target BMCs.

- [Prerequisites](#prerequisites)
- [Limitations](#limitations)
- [Generate TLS certificates](#generate-tls-certificates)
- [Regenerate TLS certificates](#regenerate-tls-certificates)

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

## Limitations

TLS certificates can only be set for liquid-cooled BMCs. TLS certificate support for air-cooled BMCs is not supported in release 1.4.

## Generate TLS certificates

1. (`ncn-mw#`) Use SCSD to generate TLS certificates.

    1. Create a `cert_create.json` JSON file containing all cabinet level certificate creation information.

        ```json
        {
          "Domain": "Cabinet",
          "DomainIDs": [ "x0", "x1", "x2", "x3"]
        }
        ```

    1. Generate the TLS certificates.

        ```bash
        cray scsd bmc createcerts create --format json cert_create.json
        ```

        Example output:

        ```json
        {
          "DomainIDs": [
            {
              "ID": "x0",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x1",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x2",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x3",
              "StatusCode": 200,
              "StatusMsg": "OK"
            }
          ]
        }
        ```

1. (`ncn-mw#`) Apply the TLS certificates to the target BMCs.

    1. Create a new `cert_set.json` JSON file to specify the endpoints.

        ```json
        {
          "Force": false,
          "CertDomain": "Cabinet",
          "Targets": [
            "x0c0s0b0","x0c0s1b0","x0c0s2b0", "x0c0s3b0"
          ]
        }
        ```

    1. Set the certificates on the target BMCs.

        ```bash
        cray scsd bmc setcerts create --format json cert_set.json
        ```

        Example output:

        ```json
        {
          "Targets": [
            {
              "ID": "x0c0s0b0",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x0c0s1b0",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x0c0s2b0",
              "StatusCode": 200,
              "StatusMsg": "OK"
            },
            {
              "ID": "x0c0s3b0",
              "StatusCode": 200,
              "StatusMsg": "OK"
            }
          ]
        }
        ```

1. (`ncn-mw#`) Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

    - Name of chart to be redeployed: `cray-hms-smd`
    - Base name of manifest: `sysmgmt`
    - When reaching the step to update customizations, perform the following step:

        **Only follow this step as part of the previously linked chart redeploy procedure.**

        Enable the `CA_URI` variable in all Hardware Management Services \(HMS\) that use Redfish.

        The `customizations.yaml` file needs an entry to specify the URI where the Certificate Authority \(CA\) bundle can be found.

        ```bash
        vi customizations.yaml
        ```

        Example excerpts from `customizations.yaml`:

        ```yaml
          hms_ca_info:
            hms_svc_ca_uri: "/usr/local/cray-pki/certificate_authority.crt"
        ```

        ```yaml
          cray-hms-reds:    
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri}}"
          cray-hms-capmc:
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri}}"
          cray-hms-meds:
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri}}"
          cray-hms-hmcollector:
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri}}"
          cray-hms-smd:
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri }}"
          cray-hms-firmware-action:
            hms_ca_uri: "{{ hms_ca_info.hms_svc_ca_uri}}"
        ```

        > Setting `hms_ca_uri` to `"vault://pki_common/ca_chain"` specifies the use of the Vault PKI directly.

    - When reaching the step to validate that the redeploy was successful, there are no additional steps to perform.
    - **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**

## Regenerate TLS certificates

At any point the TLS certs can be regenerated and replaced on Redfish BMCs. The CA trust bundle can also be modified at any time. When this is to be done, the following steps are needed:

1. Modify the CA trust bundle.

   Once the CA trust bundle is modified, each service will automatically pick up the new CA bundle data. There is no manual step.

1. Regenerate the TLS cabinet-level certificates as done is the preceding step.

1. Place the TLS certificates onto the Redfish BMCs as in the preceding step.
