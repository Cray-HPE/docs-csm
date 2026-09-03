# DHCP boot file customization

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

1. (`ncn#`) Determine the [HSM][hsm] `ethernetInterfaces` record for the node.

   ```bash
   cray hsm inventory ethernetInterfaces list --component-id x3000c0s17b4n0 --format toml
   ```

   Example output:

   ```toml
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
   cray hsm inventory ethernetInterfaces update b42e99dfec47 --description="ipxe=ipxe.test" --format toml
   ```

   Example output:

   ```toml
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

1. (`ncn#`) Dump the DHCP server configuration.

   **NOTE** It make take up to two minutes for the change to [HSM][hsm] to be reflected in the DHCP server configuration as the DHCP helper has to run to update the configuration.

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

1. (`ncn#`) Remove the `ipxe=` setting from the [HSM][hsm] `ethernetInterfaces` record.

   ```bash
   cray hsm inventory ethernetInterfaces update b42e99dfec47 --description="" --format toml
   ```

   Example output:

   ```toml
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

   ```json
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

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cmn]: ../../../glossary.md#customer-management-network-cmn
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[nc]: ../../../glossary.md#node-controller-nc
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmd]: ../../../glossary.md#node-memory-dump-nmd
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[sdu]: ../../../glossary.md#system-diagnostic-utility-sdu
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
