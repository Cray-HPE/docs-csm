# Check Current DHCP Leases

Use the Kea API to retrieve data from the DHCP lease database.

## Prerequisites

(`ncn-mw#`) An authentication token is required. If one has not been set up, log on to a Kubernetes master or worker
and run the following:

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Once an authentication token is generated, these commands can be run on a Kubernetes master or worker node.

## Commands to check leases

(`ncn-mw#`) Get all leases:

> **WARNING:** This may cause the terminal to crash based on the size of the output.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
```

(`ncn-mw#`) In order to use an IP address to look for the hostname/MAC address, use IP address lookup.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "x.x.x.x" } }' https://api_gw_service.local/apis/dhcp-kea | jq
```

(`ncn-mw#`) Use the MAC address to find the hostname/IP address:

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hw-address"=="XX:XX:XX:XX:XX:5d")'
```

(`ncn-mw#`) Use the hostname to find the MAC address or IP address:

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hostname"=="xNAME")'
```

(`ncn-mw#`) View the total amount of leases:

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].text'
```

[Back to Index](../README.md)
