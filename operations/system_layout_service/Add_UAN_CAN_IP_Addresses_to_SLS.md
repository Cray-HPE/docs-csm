# Add UAN CAN IP Addresses to SLS

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
    https://api-gw-service-nmn.local/apis/sls/v1/networks/CAN|jq > CAN.json

    ncn-m001# cp CAN.json CAN.json.bak
    ```

2.  Edit the CAN.json file and add the desired UAN CAN IP addresses in the ExtraProperties.Subnets section.

    This subsection is located under the CAN Bootstrap DHCP Subnet section. The IP address reservations array needs to be added in the following JSON format:

    ```json
          {
            "Comment": "x3000c0s23b0n0",
            "IPAddress": "10.103.2.20",
            "Name": "uan01"
          },
    ```

    If multiple alias are required, the JSON format would be:

    ```json
          {
            "Aliases": [
              "uan01-can",
              "uan01-slurm"
            ],
            "Comment": "x3000c0s23b0n0",
            "IPAddress": "10.103.2.20",
            "Name": "uan01"
          },
    ```

    IMPORTANT: There must be an alias or name defined in a format that matches the hostname of the UAN. This is required by the CFS play uan_interfaces that configures the CAN interface on UANs. If the CAN is not being configured for a particular UAN, then this requirement is not needed.

3.  Upload the updated CAN.json file to SLS.

    ```bash
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" --header \
    "Content-Type: application/json" --request PUT --data @CAN.json \
    https://api-gw-service-nmn.local/apis/sls/v1/networks/CAN
    ```

4.  Verify that DNS records were created.

    It will take about five minutes before any records will show up.

    For example:

    ```bash
    ncn-m001:~ # nslookup uan01.can
    Server:	10.92.100.225
    Address:	10.92.100.225#53

    Name:	uan01.can
    Address: 10.103.2.24

    ncn-m001:~ # nslookup uan01-can.can
    Server:	10.92.100.225
    Address:	10.92.100.225#53

    Name:	uan01-can.can
    Address: 10.103.2.24
    ```

    As stated above, the UAN play uan_interfaces will attempt to nslookup the hostname of the node with with ".can" appended. Make sure this alias resolves if the CAN is going to be configured on that particular UAN. In certain upgrade scenarios, the expected alias may not have been added by default.
