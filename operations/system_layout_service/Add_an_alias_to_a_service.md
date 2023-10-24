# Add an alias to a service

Add an alias for an existing service to the IP address reservations in the System Layout Service \(SLS\). Adding these IP addresses will propagate the data needed for the Domain Name Service \(DNS\).

## Prerequisites

This procedure requires administrative privileges.

## Procedure

This example will add an alias to the `pbs_service` in the Node Management Network \(NMN\).

1. Get an API token.

    ```bash
    ncn-mw# TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
                -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
                -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                | jq -r '.access_token')
    ```

1. Retrieve the SLS data for the network the service resides in.

    ```bash
    ncn-mw# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks/NMN|jq > NMN.json
    ```

1. Make a backup copy of the file.

    ```bash
    ncn-mw# cp -v NMN.json NMN.json.bak
    ```

1. Edit the `NMN.json` file and add the desired alias in the `ExtraProperties.Subnets` section.

    For example, after editing it may look similar to the following:

    ```json
    {
      "Aliases": [
        "pbs-service",
        "pbs-service-nmn",
        "pbs_service.local",
        "test-alias"
      ],
      "Comment": "pbs-service,pbs-service-nmn",
      "IPAddress": "10.252.2.5",
      "Name": "pbs_service"
    }
    ```

1. Upload the updated `NMN.json` file to SLS.

    ```bash
    ncn-mw# curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" --request PUT \
                --data @NMN.json https://api-gw-service-nmn.local/apis/sls/v1/networks/NMN
    ```

1. Verify that DNS records were created.

    It will take about five minutes before any records will show up.

    For example:

    ```bash
    ncn-mw# nslookup test-alias
    ```

    Example output:

    ```text
    Server:     10.92.100.225
    Address:    10.92.100.225#53

    Name:    test-alias
    Address: 10.252.2.5
    ```
