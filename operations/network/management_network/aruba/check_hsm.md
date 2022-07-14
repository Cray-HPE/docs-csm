# Check HSM

Hardware State Manager has two important parts:

* [System Layout Service (SLS)](#sls): This is the "expected" state of the system (as populated by `networks.yaml` and other sources).
* [State Manager Daemon (SMD)](#smd): This is the "discovered" or active state of the system during runtime.

## Prerequisites

* The API calls on this page require an authorization token to be set in the `TOKEN` variable.
  See [Retrieve an Authentication Token](../../../security_and_authentication/Retrieve_an_Authentication_Token.md).
* The `cray` CLI commands on this page require the Cray command line interface to be configured.
  See [Configure the Cray CLI](../../../configure_cray_cli.md).

## SLS

* API call

    ```bash
    ncn# curl  -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/sls/v1/hardware | jq
    ```

* CLI command

    ```bash
    ncn# cray sls hardware list --format json
    ```

In either case, the output from SLS should consist of a list of objects that look like the following:

```json
  {
    "Parent": "x1000c7s1b0",
    "Xname": "x1000c7s1b0n0",
    "Type": "comptype_node",
    "Class": "Mountain",
    "TypeString": "Node",
    "ExtraProperties": {
      "Aliases": [
        "nid001228"
      ],
      "NID": 1228,
      "Role": "Compute"
    }
  }
```

## SMD

* API call

    ```bash
    ncn# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces | jq
    ```

* CLI command

    ```bash
    ncn# cray hsm inventory ethernetInterfaces list --format json
    ```

In either case, the output from SMD should consist of a list of objects that look like the following:

```json
  {
    "ID": "0040a6838b0e",
    "Description": "",
    "MACAddress": "0040a6838b0e",
    "IPAddress": "10.100.1.147",
    "LastUpdate": "2020-07-24T23:44:24.578476Z",
    "ComponentID": "x1000c7s1b0n0",
    "Type": "Node"
  }
```

[Back to Index](../index.md)
