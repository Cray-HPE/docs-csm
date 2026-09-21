# Check Current DHCP Leases

Use the Kea API to retrieve data from the DHCP lease database.

* [Prerequisite](#prerequisite)
* [All leases](#all-leases)
* [Lookup by IP address](#lookup-by-ip-address)
* [Lookup by MAC address](#lookup-by-mac-address)
* [Lookup by hostname](#lookup-by-hostname)
* [Number of leases](#number-of-leases)
* [Back to index](#back-to-index)

## Prerequisite

An authentication token is required for all of the commands on this page.

(`ncn-mw#`) Get an authentication token.

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

## All leases

(`ncn-mw#`) Retrieve all the leases (warning this may cause a terminal crash based on the size of the output).

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
```

## Lookup by IP address

(`ncn-mw#`) Use the IP address to get the hostname and MAC address.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "x.x.x.x" } }' https://api_gw_service.local/apis/dhcp-kea | jq
```

## Lookup by MAC address

(`ncn-mw#`) Use the MAC address to get the hostname and IP address.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hw-address"=="XX:XX:XX:XX:XX:5d")'
```

## Lookup by hostname

(`ncn-mw#`) Use the hostname to get the MAC address and IP address.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hostname"=="xNAME")'
```

## Number of leases

(`ncn-mw#`) Get total amount of leases.

```bash
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].text'
```

## Back to index

[Back to Index](../README.md)
