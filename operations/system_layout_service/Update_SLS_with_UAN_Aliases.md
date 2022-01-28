# Update SLS with UAN Aliases

This guide shows the process for manually adding an alias to a UAN in SLS and ensuring that the node
is being monitored by conman for console logs.

### Prerequisites
* SLS is up and running and has been populated with data.
* Access to the API gateway `api-gw-service` (legacy: `api-gw-service-nmn.local`)

## Procedure

1. Authenticate with Keycloak to obtain an API token:

   ```bash
   export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
   -d client_id=admin-client \
   -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' \
   | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
   | jq -r '.access_token')
   ```

1. Find the xname of the UAN by searching through all Application nodes until found.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" \
   "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Application" \
   | jq
   ```

   This will return an array of application nodes currently known in SLS:
   ```json
   ncn-w001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
   "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Application" \
   | jq
   [
     {
       "Parent": "x3000c0s19b0",
       "Xname": "x3000c0s19b0n0",
       "Type": "comptype_node",
       "Class": "River",
       "TypeString": "Node",
       "LastUpdated": 1606332877,
       "LastUpdatedTime": "2020-11-25 19:34:37.183293 +0000 +0000",
       "ExtraProperties": {
         "Role": "Application",
         "SubRole": "UAN"
       }
     }
   ]
   ```

1. Update the UAN object in SLS by adding Aliases array with the UAN's hostname.

   Replace `UAN_XNAME` in the URL and JSON object with the UAN's xname.
   Replace `UAN_PARENT_XNAME` in the JSON object with the UAN's parent xname.
   Replace `UAN_ALIAS` in the Aliases array with the UAN's hostname.
   The `LastUpdated` and `LastUpdatedTime` fields are not required to be in the PUT payload.

   ```json
   curl -X PUT -s -k -H "Authorization: Bearer ${TOKEN}" \
   "https://api-gw-service-nmn.local/apis/sls/v1/hardware/<UAN_XNAME>" -d '
   {
     "Parent": "UAN_PARENT_XNAME",
     "Xname": "UAN_XNAME",
     "Type": "comptype_node",
     "Class": "River",
     "TypeString": "Node",
     "ExtraProperties": {
       "Role": "Application",
       "SubRole": "UAN",
       "Aliases": ["UAN_ALIAS"]
     }
   }'
   ```


   Using the response from the previous step, we can build the following command. The hostname for this uan is `uan01`, and this is reflected in the added `Aliases` field in the UAN's `ExtraProperties`.

   ```json
   curl -X PUT -s -k -H "Authorization: Bearer ${TOKEN}" \
   "https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0" -d '
   {
     "Parent": "x3000c0s19b0",
     "Xname": "x3000c0s19b0n0",
     "Type": "comptype_node",
     "Class": "River",
     "TypeString": "Node",
     "ExtraProperties": {
       "Role": "Application",
       "SubRole": "UAN",
       "Aliases": ["uan01"]
     }
   }'
   ```

   Example response:

   ```json
   ncn-w001# curl -X PUT -s -k -H "Authorization: Bearer ${TOKEN}" \
   >"https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0" -d '
   > {
   >   "Parent": "x3000c0s19b0",
   >   "Xname": "x3000c0s19b0n0",
   >   "Type": "comptype_node",
   >   "Class": "River",
   >   "TypeString": "Node",
   >   "ExtraProperties": {
   >     "Role": "Application",
   >     "SubRole": "UAN",
   >     "Aliases": ["uan01"]
   >   }
   > }'
   {"Parent":"x3000c0s19b0","Xname":"x3000c0s19b0n0","Type":"comptype_node","Class":"River","TypeString":"Node","LastUpdated":1606332877,"LastUpdatedTime":"2020-11-25 19:34:37.183293 +0000 +0000","ExtraProperties":{"Aliases":["uan01"],"Role":"Application","SubRole":"UAN"}}
   ```

   After a few minutes the -mgmt name should begin resolving. Communication with the BMC should be available via the alias `uan01-mgmt`.

1. Confirm that the BMC for the UAN is up and running at the aliased address.

   ```
   ncn-w001# ping -c 4 uan01-mgmt
   ```

   Example output:

   ```
   PING uan01-mgmt (10.254.2.53) 56(84) bytes of data.
   64 bytes from x3000c0s19b0 (10.254.2.53): icmp_seq=1 ttl=255 time=0.170 ms
   64 bytes from x3000c0s19b0 (10.254.2.53): icmp_seq=2 ttl=255 time=0.228 ms
   64 bytes from x3000c0s19b0 (10.254.2.53): icmp_seq=3 ttl=255 time=0.311 ms
   64 bytes from x3000c0s19b0 (10.254.2.53): icmp_seq=4 ttl=255 time=0.240 ms

   --- uan01-mgmt ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3061ms
   rtt min/avg/max/mdev = 0.170/0.237/0.311/0.051 ms
   ```

   When this node boots, the DHCP request of its -nmn interface will cause the uan01 to be created and resolved.

1. Confirm that the UAN is being monitored by the console services. Follow the procedure in [Manage Node Consoles](../conman/manage_node_consoles.md).

