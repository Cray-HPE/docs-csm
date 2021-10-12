# Check current DHCP leases

We'll use the Kea API to retrieve data from the DHCP lease database.
First you need to get the auth token, On ncn-w001 or a worker/manager with kubectl, run:

```
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Once you generate the auth token you can run these commands on a a worker or manager node.

If you want to retrieve all the Leases, (warning this may cause your terminal to crash based on the size of the output.)

Get all leases:

```
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
If you have the IP and are looking for the hostname/MAC address.
```

IP Lookup:

```
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "x.x.x.x" } }' https://api_gw_service.local/apis/dhcp-kea | jq
```

If you have the MAC and are looking for the hostname/IP Address.
MAC lookup:

```
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hw-address"=="XX:XX:XX:XX:XX:5d")'
```

If you have the hostname and are looking for the MAC/IP address.
Hostname lookup:

```
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hostname"=="xNAME")'
```

If you want to see the total amount of leases.
Total Leases:

```
curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq '.[].text'
```

[Back to Index](./index.md)