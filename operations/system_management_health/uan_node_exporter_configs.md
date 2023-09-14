# UAN NODE Exporter

The Prometheus UAN NODE Exporter service,service monitor and endpoints are deployed to scrape SMARTMON data by the `cray-sysmgmt-health` chart to the `sysmgmt-health` 
namespace as part of the Cray System Management \(CSM\) release.

## Configuration

In order to provide data to the Grafana SMART dashboards, the UAN NODE Exporter must be configured with a list of UAN 
NMN IP Address to scrape metrics from.

> **`NOTE`** All variables used within this page depend on the `/etc/environment` setup done in [Pre-installation](../../install/pre-installation.md).

1. (`uan#`) Obtain the list of UAN NMN IP Address.
    Login to UAN node
   (`uan#`)
    ```bash
    # hostname -i
    ```

   Expected output looks similar to the following:

    ```
    ::1 127.0.0.1 10.252.1.13
    ```
1. (`pit#`) Update `customizations.yaml` with the list of switches.

    ```bash
    yq write -s - -i ${PITDATA}/prep/site-init/customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
      value:
                enabled: true
                endpoints:
                - 10.252.1.18
                - 10.252.1.13
    EOF
    ```

1. (`pit#`) Review the UAN NODE Exporter configuration.

    ```bash
    yq r ${PITDATA}/prep/site-init/customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
    ```

   The expected output looks similar to:

    ```yaml
    uanNodeExporter:
      enabled: true
      endpoints:
      - 10.252.1.18
      - 10.252.1.13
    ```

The most common configuration parameters are specified in the following table. They must be set in the `customizations.yaml` file
under the `spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter` service definition.

| Customization            | Default      | Description                                                                         |
|--------------------------|--------------|-------------------------------------------------------------------------------------|
| `enabled`                | `false`       | Enables `service` for UAN NODE Exporter \(default chart value is `false`\)         |
| `endpoints`              | `10.252.1.13` | list of UAN NMN IP Address to monitor SMARTMON data                              |

For a complete set of available parameters, consult the `values.yaml` file for the `cray-sysmgmt-health` chart.
