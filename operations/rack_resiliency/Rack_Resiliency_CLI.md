# Rack Resiliency Service CLI Commands

This page is a quick reference for common RRS commands in the [Cray CLI](../../glossary.md#cray-cli-cray).

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.
For more information about the RRS API, see [Rack Resiliency Service](../../api/rrs.md).

* [Managing zones](#managing-zones)
* [Managing critical services](#managing-critical-services)
* [Monitoring critical services status](#monitoring-critical-services-status)
* [Updating critical services](#updating-critical-services)

## Managing zones

* (`ncn-mw#`) List all configured zones:

    ```bash
    cray rrs zones list
    ```

* (`ncn-mw#`) Get detailed information about a specific zone:

    ```bash
    cray rrs zones describe <zone-name>
    ```

  This will return detailed information about the zone including management master nodes, worker nodes, and storage nodes with their status.

## Managing critical services

* (`ncn-mw#`) List all critical services grouped by namespace:

    ```bash
    cray rrs criticalservices list
    ```

* (`ncn-mw#`) Get summarized information about a specific critical service:

    ```bash
    cray rrs criticalservices describe <critical-service-name>
    ```

  This will return information such as configured instances, currently running instances, name, namespace, and type.

## Monitoring critical services status

* (`ncn-mw#`) List the status of all critical services with distribution details:

    ```bash
    cray rrs criticalservices status list
    ```

  This will show service status (e.g., balanced, no pods found) and distribution of pods across zones and nodes.

* (`ncn-mw#`) Get detailed status information about a specific critical service:

    ```bash
    cray rrs criticalservices status describe <critical-service-name>
    ```

  This will return detailed pod information including pod names, nodes, statuses, and zones.

## Updating critical services

* (`ncn-mw#`) Update the critical services configuration using a JSON file:

    ```bash
    cray rrs criticalservices update --from-file <file-path>
    ```

  The file should contain a JSON string with the critical services configuration in the following format:

    ```json
    {
      "critical-services": {
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "kube-proxy": {
          "namespace": "kube-system",
          "type": "DaemonSet"
        }
      }
    }
    ```

  This format allows you to specify multiple services together with their namespaces and types.

## Examples

* (`ncn-mw#`) Get information about zone "cscs-rack-x3001":

    ```bash
    cray rrs zones describe cscs-rack-x3001
    ```

* (`ncn-mw#`) Get detailed status of the "cray-vault" service:

    ```bash
    cray rrs criticalservices status describe cray-vault
    ```

* (`ncn-mw#`) Display status of all critical services in a system:

    ```bash
    cray rrs criticalservices status list
    ```

* (`ncn-mw#`) Update critical services with a new configuration file:

    ```bash
    cray rrs criticalservices update --from-file new-critical-services.json
    ```

  Where new-critical-services.json contains:

    ```json
    {
      "critical-services": {
        "cray-vault": {
          "namespace": "vault",
          "type": "StatefulSet"
        },
        "nexus": {
          "namespace": "nexus",
          "type": "Deployment"
        }
      }
    }
    ```
