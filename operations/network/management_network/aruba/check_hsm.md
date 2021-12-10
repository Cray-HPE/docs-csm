# Check the Hardware State Manager (HSM)

The Hardware State Manager (HSM) has two important parts: 

* **System Layout Service (SLS):** This is the "expected" state of the system (as populated by networks.yaml and other sources)
* **State Manager Daemon (SMD):**  This is the "discovered" or active state of the system during runtime

## Procedure

1. Check SLS. 

    ```
    curl  -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/sls/v1/hardware | jq | less
    ```

    The output from SLS should look similar to the following:

    ```
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

1. Check SMD.

    ```
    curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces | jq | less
    ```

    The output from SMD should look similar to the following:

    ```
    {
      "ID": "0040a6838b0e",
      "Description": "",
      "MACAddress": "0040a6838b0e",
      "IPAddress": "10.100.1.147",
      "LastUpdate": "2020-07-24T23:44:24.578476Z",
      "ComponentID": "x1000c7s1b0n0",
      "Type": "Node"
    },
    ```

[Back to Index](../index_aruba.md)