# Enable IPMI access on HPE iLO BMCs

New HPE nodes ship with with IPMI access disabled by default. In order for CSM to fully manage HPE nodes, IPMI access must be enabled on HPE node BMCs.

## Prerequisites

- The BMC or CMC is accessible over the network via hostname or IP address.

## Procedure

1. (`ncn#`) Set up an environment variable with the hostname or IP address of the BMC where IPMI needs to be enabled. If coming from the
  [Add Worker, Storage, or Master NCNs](Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#add-worker-storage-or-master-ncns)
  procedure, then the IP address should already be stored in the `BMC_IP` environment variable.

    - Hostname:

        ```bash
        BMC=x3000c0s3b0
        ```

    - IP address:

        ```bash
        BMC=10.254.1.9
        ```

1. (`ncn#`) Check to see if IPMI is enabled.

    > `read -s` is used to read the password in order to prevent it from being echoed to the screen or saved in the shell history.
    > Note that the subsequent `curl` commands **will** do both of these things. If this is not desired, the call should be made in
    > another way.

    ```bash
    read -s ROOT_PASSWORD
    export ROOT_PASSWORD
    curl -k -u "root:${ROOT_PASSWORD}" "https://${BMC}/redfish/v1/Managers/1/NetworkProtocol" | jq .IPMI
    ```

    Expected output showing that IPMI is enabled. **If this is observed, then no further action is required to enable IPMI access; skip the rest of the procedure**.

    ```json
    {
        "Port": 623,
        "ProtocolEnabled": true
    }
    ```

    If the following is observed, then this indicates that IPMI access is not configured. **Continue this procedure to enable IPMI access.**

    ```json
    {
        "Port": 623,
        "ProtocolEnabled": false
    }
    ```

1. **If IPMI is disabled**, then enable IPMI.

    1. (`ncn#`) Enable IPMI access.

        ```bash
        curl -k -u "root:${ROOT_PASSWORD}" -X PATCH \
            -H 'Content-Type: application/json' \
            -d '{"IPMI": {"Port": 623, "ProtocolEnabled": true}}' \
            "https://${BMC}/redfish/v1/Managers/1/NetworkProtocol" | jq
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

    1. (`ncn#`) Restart the BMC.

        ```bash
        curl -k -u "root:${ROOT_PASSWORD}" -X POST \
            -H 'Content-Type: application/json' \
            -d '{"ResetType": "GracefulRestart"}' \
            "https://${BMC}/redfish/v1/Managers/1/Actions/Manager.Reset" | jq
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

    1. Wait for the BMC to restart. This may take a couple of minutes.

    1. (`ncn#`) Verify that IPMI is enabled.

        ```bash
        curl -k -u "root:${ROOT_PASSWORD}" "https://${BMC}/redfish/v1/Managers/1/NetworkProtocol" | jq .IPMI
        ```

        Expected output showing that IPMI is enabled:

        ```json
        {
          "Port": 623,
          "ProtocolEnabled": true
        }
        ```
