# Enable IPMI access on HPE iLO BMCs

New HPE nodes ship with with IPMI access disabled by default. For CSM to fully manage HPE nodes IPMI access must enabled on HPE node BMCs.

## Prerequisites

- The BMC or CMC is accessible over the network via hostname or IP address.

## Procedure

1. (`ncn#`) Setup environment variable of the BMC hostname or IP to verify and enable IPMI on. If coming from the [Add Worker, Storage or Master NCNs](Add_Remove_Replace_NCNs.md#add-worker-storage-master)
  procedure, then the IP address of should stored in the `BMC_IP` environment variable.

    Via hostname:

    ```bash
    BMC=x3000c0s3b0
    ```

    Via IP address:

    ```bash
    BMC=10.254.1.9
    ```

1. (`ncn#`) Check to see if IPMI is enabled:

    > `read -s` is used to read the password in order to prevent it from being echoed to the screen or saved in the shell history.
    > Note that the subsequent `curl` commands **will** do both of these things. If this is not desired, the call should be made in
    > another way.

    ```bash
    read -s ROOT_PASSWORD
    export ROOT_PASSWORD
    curl -k -u root:$ROOT_PASSWORD https://$BMC/redfish/v1/Managers/1/NetworkProtocol | jq .IPMI
    ```

    Expected output showing IPMI is enabled. **if this is observed no further action is required to enable IPMI Access. The rest of the procedure can be skipped**.

    ```json
    {
        "Port": 623,
        "ProtocolEnabled": true
    }
    ```

    If the following is observed this indicates IPMI access is not configured password. **Continue this procedure to enable IPMI access.**

    ```json
    {
        "Port": 623,
        "ProtocolEnabled": false
    }
    ```

1. **If IPMI is disabled**, then enable IPMI.

    1. (`ncn#`) Enable IPMI access:

        ```bash
        curl -k -u root:$ROOT_PASSWORD -X PATCH \
            -H 'Content-Type: application/json' \
            -d '{"IPMI": {"Port": 623, "ProtocolEnabled": true}}' \
            https://$BMC/redfish/v1/Managers/1/NetworkProtocol | jq
        ```

        Expected output:

        ```json
        {
          "error": {
            "code": "iLO.0.10.ExtendedInfo",
            "message": "See @Message.ExtendedInfo for more information.",
            "@Message.ExtendedInfo": [
              {
                "MessageId": "iLO.2.14.ResetRequired"
              }
            ]
          }
        }
        ```

    1. (`ncn#`) **If IPMI was disabled**, then restart the BMC:

        ```bash
        curl -k -u root:$ROOT_PASSWORD -X POST \
            -H 'Content-Type: application/json' \
            -d '{"ResetType": "GracefulRestart"}' \
            https://$BMC/redfish/v1/Managers/1/Actions/Manager.Reset | jq
        ```

        Expected output:

        ```json
        {
          "error": {
            "code": "iLO.0.10.ExtendedInfo",
            "message": "See @Message.ExtendedInfo for more information.",
            "@Message.ExtendedInfo": [
              {
                "MessageId": "iLO.2.14.ResetInProgress"
              }
            ]
          }
        }
        ```

    1. (`ncn#`) Wait for the BMC to restart:

        ```bash
        sleep 120
        ```

    1. (`ncn#`) Verify IPMI is enabled:

        ```bash
        curl -k -u root:$ROOT_PASSWORD https://$BMC/redfish/v1/Managers/1/NetworkProtocol | jq .IPMI
        ```

        Expected output showing IPMI is enabled:

        ```json
        {
          "Port": 623,
          "ProtocolEnabled": false
        }
        ```
