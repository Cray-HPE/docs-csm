## Add UAN CAN IP Addresses to SLS

Add the Customer Access Network \(CAN\) IP addresses for User Access Nodes \(UANs\) to the IP address reservations in the System Layout Service \(SLS\). Adding these IP addresses will propagate the data needed for the Domain Name Service \(DNS\).

For more information on CAN IP addresses, refer to the [Customer Access Network (CAN)](../network/customer_access_network/Customer_Access_Network_CAN.md).

### Prerequisites

This procedure requires administrative privileges.

### Procedure


1.  Retrieve the SLS data for the CAN.

    ```bash
    ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
    -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
    -o jsonpath='{.data.client-secret}' | base64 -d` \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
    | jq -r '.access_token')
    
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
    https://api_gw_service.local/apis/sls/v1/networks/CAN|jq > CAN.json
    
    ncn-m001# cp CAN.json CAN.json.bak
    ```

2.  Edit the CAN.json file and add the desired UAN CAN IP addresses in the ExtraProperties.Subnets section.

    This subsection is located under the CAN Bootstrap DHCP Subnet section. The IP address reservations array needs to be added in the following JSON format:

    ```json
           {
             "Aliases": [
               "uan10000-can"
             ],
             "IPAddress": "10.103.13.222",
             "Name": "uan10000"
           }
    ```

    `-can` needs to be added to the hostname for the Aliases value, and the hostname belongs in the Name value.

3.  Upload the updated CAN.json file to SLS.

    ```bash
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" --header \
    "Content-Type: application/json" --request PUT --data @CAN.json \
    https://api_gw_service.local/apis/sls/v1/networks/CAN
    ```

4.  Verify that DNS records were created.

    It will take about five minutes before any records will show up.

    For example:

    ```bash
    ncn-m001# nslookup uan10000-can 10.92.100.225
    Server:     10.92.100.225
    Address:    10.92.100.225#53
    
    Name:   uan10000-can
    Address: 10.103.13.222
    
    ncn-m001# nslookup uan10000.can 10.92.100.225
    Server:     10.92.100.225
    Address:    10.92.100.225#53
    
    Name:   uan10000.can
    Address: 10.103.13.222
    ```

