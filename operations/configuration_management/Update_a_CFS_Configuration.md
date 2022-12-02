# Update a CFS Configuration

Modify a Configuration Framework Service \(CFS\) configuration by specifying the JSON of the configuration and its layers. Use the
`cray cfs configurations update` command, similar to creating a configuration.

## Prerequisites

* A CFS configuration has been created.
* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
  See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

1. (`ncn-mw#`) Add and/or remove the configuration layers from an existing JSON configuration file.

    Do not include the name of the configuration in the JSON file. This is specified on the command line in the next step.

    ```bash
    cat configurations-example.json
    ```

    Example configuration:

    ```json
    {
      "layers": [
        {
          "name": "configurations-layer-example-1",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
          "playbook": "site.yml",
          "commit": "<git commit id>"
        }
      ]
    }
    ```

1. (`ncn-mw#`) Update the configuration in CFS.

    ```bash
    cray cfs configurations update configurations-example --file ./configurations-example.json --format json
    ```

    Example output:

    ```json
    {
      "lastUpdated": "2021-07-28T03:26:30:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
          "commit": "<git commit id>",
          "name": "configurations-layer-example-1",
          "playbook": "site.yml"
        }
      ],
      "name": "configurations-example"
    }
    ```
