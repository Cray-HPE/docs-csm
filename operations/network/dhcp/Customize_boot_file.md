# DHCP boot file customization

* [DHCP Boot file customization](#dhcp-boot-file-customization)
    * [Background](#background)
    * [Override the boot file name](#override-the-boot-file-name)
    * [Verify the node DHCP configuration has been updated](#verify-the-node-dhcp-configuration-has-been-updated)
    * [Reset the boot file to the default option](#reset-the-boot-file-name-to-default)

## Background

The `cray-dhcp-kea` service is configured to send a CPU architecture appropriate boot file based on the value received in
the client system architecture field (option 93) of the incoming DHCP request. By default `cray-dhcp-kea` will send
the following in the DHCP boot file name field (option 67) of the DHCP response.

| Option 93 value         | Filename         |
|-------------------------|------------------|
| `0x7` - x64 UEFI        | `ipxe.efi`       |
| `0xb` - ARM 64-bit UEFI | `ipxe.arm64.efi` |

It may be desirable to use a different boot file to the default one for testing or debugging purposes. This document
describes how the boot file name may be overridden on a per-node basis.

## Override the boot file name

1. (`ncn#`) Determine the HSM `ethernetInterfaces` record for the node.

   ```bash
   cray hsm inventory ethernetInterfaces list --component-id x3000c0s17b4n0
   ```

   Example output:

   ```text
   [[results]]
   ID = "b42e99dfec47"
   Description = ""
   MACAddress = "b4:2e:99:df:ec:47"
   LastUpdate = "2024-07-01T11:31:24.942557Z"
   ComponentID = "x3000c0s17b4n0"
   Type = "Node"
   [[results.IPAddresses]]
   IPAddress = "10.106.0.15"
   ```

1. (`ncn#`) Set the desired boot file name by adding the `ipxe` option to `Description` field of the HSM `ethernetInterfaces` record.

   This example will set the boot file name to `ipxe.test`.

   ```bash
   cray hsm inventory ethernetInterfaces update b42e99dfec47 --description="ipxe=ipxe.test"
   ```

   Example output:

   ```text
   ID = "b42e99dfec47"
   Description = "ipxe=ipxe.test"
   MACAddress = "b4:2e:99:df:ec:47"
   LastUpdate = "2024-04-25T06:28:34.825112Z"
   ComponentID = "x3000c0s17b4n0"
   Type = "Node"
   [[IPAddresses]]
   IPAddress = "10.106.0.15"
   ```

## Verify the node DHCP configuration has been updated

1. (`ncn#`) Retrieve a token.

   ```bash
   export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                    -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

2. (`ncn#`) Dump the DHCP server configuration.

   **`NOTE`** It make take up to two minutes for the change to HSM to be reflected in the DHCP server configuration as the DHCP helper has to run to update the configuration.

   ```bash
   curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
     -d '{ "command": "config-get",  "service": [ "dhcp4" ] }' \
     https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

   The `boot-file-name` field for the node should reflect the desired boot file name.

   Example output:

   ```json
   {
   "boot-file-name": "ipxe.test",
   "client-classes": [],
   "hostname": "nid000004",
   "hw-address": "b4:2e:99:df:ec:47",
   "ip-address": "10.106.0.15",
   "next-server": "0.0.0.0",
   "option-data": [],
   "server-hostname": ""
   }
   ```

When the node boots, it should now boot using the desired boot file.

Example output:

```text
2024-06-05 12:33:18 >>Start PXE over IPv4 on MAC: B4-2E-99-DF-EC-47. Press ESC key to abort PXE boot.
2024-06-05 12:33:26   Station IP address is 10.106.0.15
2024-06-05 12:33:26
2024-06-05 12:33:26   Server IP address is 10.92.100.60
2024-06-05 12:33:26   NBP filename is ipxe.test
```

## Reset the boot file name to default

1. (`ncn#`) Remove the `ipxe=` setting from the HSM `ethernetInterfaces` record.

   ```bash
   cray hsm inventory ethernetInterfaces update b42e99dfec47 --description=""
   ```

   Example output:

   ```text
   ID = "b42e99dfec47"
   Description = ""
   MACAddress = "b4:2e:99:df:ec:47"
   LastUpdate = "2024-04-25T06:28:34.825112Z"
   ComponentID = "x3000c0s17b4n0"
   Type = "Node"
   [[IPAddresses]]
   IPAddress = "10.106.0.15"
   ```

1. Verify the node configuration.

   Use the [Verify the node DHCP configuration has been updated](#verify-the-node-dhcp-configuration-has-been-updated) procedure to verify the configuration for the node.
   The `boot-file-name` field should be empty indicating that the DHCP service will supply the default boot file name.

   Example output:

   ```text
   {
   "boot-file-name": "",
   "client-classes": [],
   "hostname": "nid000004",
   "hw-address": "b4:2e:99:df:ec:47",
   "ip-address": "10.106.0.15",
   "next-server": "0.0.0.0",
   "option-data": [],
   "server-hostname": ""
   }
   ```
