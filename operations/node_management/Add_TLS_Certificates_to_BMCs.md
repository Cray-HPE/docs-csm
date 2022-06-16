# Add TLS Certificates to BMCs

Use the System Configuration Service \(SCSD\) tool to create TLS certificates and store them in Vault secure storage. Once certificates are created, they are placed on to the target BMCs.

### Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Limitations

TLS certificates can only be set for liquid-cooled BMCs. TLS certificate support for air-cooled BMCs is not supported in release 1.4.

### Procedure

1.  Use SCSD to generate TLS certificates.

    1.  Create a cert\_create.json JSON file containing all cabinet level certificate creation information.

        ```bash
        {
          "Domain": "Cabinet",
          "DomainIDs": [ "x0", "x1", "x2", "x3"]
        }
        ```

    2.  Generate the TLS certificates.

        ```bash
        ncn-m001# cray scsd bmc createcerts create --format json cert_create.json
        ```

        Example output:

        ```
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

2.  Apply the TLS certificates to the target BMCs.

    1.  Create a new cert\_set.json JSON file to specify the endpoints.

        ```bash
        {
          "Force": false,
          "CertDomain": "Cabinet",
          "Targets": [
            "x0c0s0b0","x0c0s1b0","x0c0s2b0", "x0c0s3b0"
          ]
        }
        ```

    2.  Set the certificates on the target BMCs.

        ```bash
        ncn-m001# cray scsd bmc setcerts create --format json cert_set.json
        ```

        Example output:

        ```
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

3.  Enable the CA\_URI variable in all Hardware Management Services \(HMS\) that use Redfish.

    Each system's customizations.yaml file needs an entry to specify the URI where the Certificate Authority \(CA\) bundle can be found.

    ```bash
    ncn-m001# vi customizations.yaml
    ```

    Example customizations.yaml:

    ```
    [...]

    spec:
      network:
        ...
      hms_ca_info:
        hms_svc_ca_uri: "/usr/local/cray-pki/certificate_authority.crt"

    [...]

    services:

    [...]

      cray-hms-reds:
    #   hms_ca_uri: "vault://pki_common/ca_chain"     # NOTE: this specifies the use of the Vault PKI directly
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

4.  Deploy the services.

    1.  Edit the manifest.yaml file.

        The modifications to the system's customizations.yaml shown above will apply when CMS is installed or upgraded as a whole. When upgrading a single service, the manifest.yaml file must contain an override for ca\_host\_uri.

        ```bash
        ncn-m001# vi manifest.yaml
        ```

        Example manifest.yaml:

        ```
        ## Example manifest for a single service upgrade
        ---
        schema: v2
        name: example-manifest
        version: 1.0.0
        failOnFirstError: True
        repositories:
          docker: dtr.dev.cray.com
          helm: helmrepo.dev.cray.com:8080
        charts: # Will install/upgrade charts in the order below
          - name: "cray-hms-smd"
            namespace: "services"
            version: 1.4.4-20201104155929+70c870d
            overrides:
              - cray-service.imagesHost="{repos[docker]}"
            values:
              hms_ca_uri: "/usr/local/cray-pki/certificate_authority.crt"
        ```

    2.  Edit the sysman.yaml file to retrieve the entries in the values: section.

        Locate the section for the target service in the sysman.yaml file and copy the information described in this step from the values: section. This content will be copied to the values: section in the manifest.yaml file in the next step.

        ```bash
        ncn-m001# manifestgen -i /opt/cray/site-info/manifests/sysmgmt.yaml \
        -c /opt/cray/site-info/customizations.yaml > sysman.yaml
        ncn-m001# vi sysman.yaml
        ```

        Example sysman.yaml:

        ```
        [...]

        - name: cray-hms-scsd
          namespace: services
          overrides:
          - cray-service.imagesHost="{repos[docker]}"
          values:
            hms_ca_uri: /usr/local/cray-pki/certificate_authority.crt  **\#\#\#\# only need to copy this line**

        [...]
        ```

        The Mountain Endpoint Discovery Service \(MEDS\) and River Endpoint Discovery Service \(REDS\) have sealed secret information in the values: section that need to be copied as well. For example:

        ```bash
        [...]

        - name: cray-hms-reds
          namespace: services
          overrides:
          - cray-service.imagesHost="{repos[docker]}"
          - imagesHost="{repos[docker]}"
          values:
            cray-service: #### start copying from here
              sealedSecrets:
              - apiVersion: bitnami.com/v1alpha1
                kind: SealedSecret
                metadata:
                  annotations:
                    sealedsecrets.bitnami.com/cluster-wide: 'true'
                  creationTimestamp: null
                  name: cray-reds-credentials
                  namespace: services
                spec:
                  encryptedData:
                    vault_redfish_defaults: AgBdzvLKM468cpWcrXxf8TcveJa4d0OWw1fJCxl138zDDCL1haLl1DY9cETQm73nPwgpKL8v3Tz+2qkpXR+HNomrjf    XN+dauJA1lj1xTTKYwRRZdux0NlLuujxr9gjtChkT/CEvCA8gNDjA/O5/2RPaWizL5IGWXBLUhN/02KmNZozpfos3WhCewnhTJiEhGLoJ+ykl9oeMI3cf+W14dpZaU    0Tc5ZAIMfR+vrfTxIlxBClUhsa82Ot8RmtvQNacvGCWuuIRcUfZcCCMQzJCKWi75l0DtRu6VkhX1pnQq/mttGbWJkhveal/VJIEFm3eIOJzn6G1KyyTzU8tjRZHLey    UTY61CrdbczDjfQ8v47T8v43G3bGUUsMcB8evNqAOvlG+DTy+WvcPnmLnVItJkQ/30m+xMIzWG0tLf/YIu2fA7u0i56hERVcg2dwC7HZUM7+GZbIsONtKthmna+EiT    cewuuc/ftgRvxEGCS5lpTnOYhgYo/C0UNd7EmEOlzt+sWWQAocGKZemHiJVGU4HRSqyMJSk/mDTJlkN24EgfLj0k8VkrPPWFMT+hXi2YjLYrtkC9GtiDZ3tOkKPAxi    yh6pR5unjhBv7LtXBbW3uD5xMvv34D0CKOcKWLeMZ97JH84Oroc2iUOP62MYVYfaA/BrPhhOS/TwhJ7SDU6q/a+Pn4I6OslrzYy8haGpiFx6lGhvpSg8F5ez1hYXB9    OmNS1UNdcX4qZpp2npOCKHpN8PeRhnD9cCC1+ObHCflMhjRiHHlQ9PdZi21DoWqvwluDVw92afPpHdVuuSJu8akEDigHUJe3ITnb4jnlQnHDe6TEZ7gyGjZqBMXzxE    7269k8DSUIEy1ofcGIBJBE5K9j+aUdlmQtiNBIh/jbV9x4y2PoA2Zyo7w3Foztn2Kw/jbXfA5b4Z47qWR57tMitv8ZwTk2m5aH+d9BHvnSVsouM/eThT8ptDJLO5gN    HulXZoKYt5YMhdEY/I0lN/NIOmRX/HeYxPbjg1+dYhVSRzM=
                    vault_switch_defaults: AgCV7pocyFV/BWZxqi9f3r4gUm7Csotf5e/X9iHo+U3Ctdkl4NW+iX1d8x+sG1UxjgSF7Vcis2y2JSbAgxz68LWBv/o    tQrDOu3v6hbxS6mu+M19D6iL5EiMbMkHpWKaG2QtHjPWrw2ZBLb+oVYivJF5N83wb1uHnwnss5SpBZTXVYg8sd5viBwKnpacQrB6dcMilceJ1Ag9gGPacyz0+gMEOP    tQZ2I4SFl82LkYdgWJyNqBvz3B8OA3SE7SBX3EKbUYUvdQ8QQptaz9l3gRVIRO8Z0I6HorYeOPzek0m6dDr6fHAAUJNrX2gcBQz/V/QvX1ngOpcpceGNumDwziwZb0    FmUQo8Tm1yrU6bcKWAch/FAv6M/HReE2eekOt41qd/dfWMs5EV5vUOauBfOdhirU1V8azlT+0HbuybWolcpTQV01t6kIUoQgyeLu5xGjV8lYfCov+FBSgYGBaQ2ZVb    L2ERWfzHLHIjvZVh0Hm6UaUc1tMqCW1gIW3FIYVMxijYet39qa54L/ARaJz/tl2u0pBwHDiJ2iTR6Lb8YGP4vFrGH7T2I9oLX6uc/K0IRTo3i7fpVBcckrXWbhLMyA    87bCoRxotERjZTIafduGgDMzJ0vlNrUK+7GAX2e8lI1hpmqc1f0CBSn6yVFELRvXX2Zgnm4yqRJb5TO0zGeoVSQCFEnHw6SdtcWmEzCiyTCDvm4r7kxmR35E6XGUqr    Qb6ypjQB70HkLFs1KucGHnOgzH3FkKka4ge1c20s8hEPdeSmLMEX8aNxNrAT6t9WznlndxZItZzlwuWrRnGSuC4oE57UBcpKZawHA6bc/nYzskW
                  template:
                    metadata:
                      annotations:
                        sealedsecrets.bitnami.com/cluster-wide: 'true'
                      creationTimestamp: null
                      name: cray-reds-credentials
                      namespace: services
                    type: Opaque
            hms_ca_uri: /usr/local/cray-pki/certificate_authority.crt
        ```

    3.  Copy the information recorded in the previous step to the values: section in the manifest.yaml file.

        Ensure the proper indenting is preserved when copying information.

        ```bash
        ncn-m001# vi manifest.yaml
        ```

    4.  Run loftsman to perform the upgrade.

        If the image is not already in place, use docker to put it into place. The following example is for SMD:

        ```bash
        ncn-m001# docker pull dtr.dev.cray.com/cray/cray-hms-smd:1.4.4-20201104155929_70c870d
        ncn-m001# docker tag dtr.dev.cray.com/cray/cray-hms-smd:1.4.4-20201104155929_70c870d registry.local/cray/cray-hms-smd:1.4.4-20201104155929_70c870d
        ncn-m001# docker push registry.local/cray/cray-hms-smd:1.4.4-20201104155929_70c870d
        ```

        Perform the upgrade:

        ```bash
        ncn-m001# loftsman ship --shape --images-registry dtr.dev.cray.com \
        --charts-repo http://helmrepo.dev.cray.com:8080 --loftsman-images-registry dtr.dev.cray.com \
        --manifest-file-path ./manifest.yaml
        ```


At any point the TLS certs can be re-generated and replaced on Redfish BMCs. The CA trust bundle can also be modified at any time. When this is to be done, the following steps are needed:

1.  Modify the CA trust bundle.

    Once the CA trust bundle is modified, each service will automatically pick up the new CA bundle data. There is no manual step.

2.  Regenerate the TLS cabinet-level certificates as done is the preceding step.
3.  Place the TLS certificates onto the Redfish BMCs as in the preceding step.

