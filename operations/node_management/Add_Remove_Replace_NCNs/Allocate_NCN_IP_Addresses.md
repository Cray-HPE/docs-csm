# Allocate NCN IP Addresses

## Description

This procedure allocates IP addresses for an NCN being added to a system. The addresses are allocated on the applicable networks
(HMN, NMN, MTL, CMN, etc.), and added to both the System Layout Service (SLS) and the Boot Script Service (BSS).

This procedure will perform and verify the following:

* If the NCN being added is one of the first three master, storage, or worker NCNs, then its IP address is expected to already be present and consistent between SLS and BSS.
* Otherwise, new IP addresses for the NCN will be allocated and verified to be within the static IP address pool in the `bootstrap_dhcp` subnet for the various networks in system.

## Prerequisites

* The latest CSM documentation is installed on the system. See
  [Check for latest documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-mw#`) Retrieve an API token.

    ```bash
    export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                     -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
                     -o jsonpath='{.data.client-secret}' | base64 -d` \
                     https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                     | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Determine the component name (xname) of the NCN by referring to the HMN of the systems SHCD, if it has not been determined yet.

    Sample row from the `HMN` tab of an SHCD:
    | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
    | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
    | `wn01`            | `x3000`             | `u04`                   | `-`     |              |      | `j3`                | `sw-smn01`          | `x3000`                  | `u14`                        | `-`     | `j48`                    |

    > The Source name for the a worker NCN would be in the format of `wn01`; master NCNs are `mn01`, and storage NCNs are `sn01`.

    Node xname format: `xXcCsSbBnN`

    |   |                | SHCD Column to Reference | Description
    | - | -------------- | ------------------------ | -----------
    | X | Cabinet number | Source Rack (K20)        | The Cabinet or rack number containing the Management NCN.
    | C | Chassis number |                          | For air-cooled nodes within a standard rack, the chassis is `0`. If the air-cooled node node is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
    | S | Slot/Rack U    | Source Location (L20)    | The Slot of the node is determined by the bottom most rack U that node occupies.
    | B | BMC number     |                          | For Management NCNs the BMC number is 0.
    | N | Node number    |                          | For Management NCNs the Node number is 0.

    ```bash
    export XNAME=x3000c0s4b0n0
    ```

1. (`ncn-mw#`) Perform a dry-run of allocating IP addresses for the NCN.

    ```bash
    cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
    ./add_management_ncn.py allocate-ips --xname "$XNAME" --alias "$NODE"
    ```

    Example output:

    ```text
    ...
    IP Addressees have been allocated for x3000c0s36b0n0 (ncn-s004) and been added to SLS and BSS
        WARNING A Dryrun was performed, and no changes were performed to the system

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        CMN     | 10.103.11.42
        CAN     | 10.102.4.10
        HMN     | 10.254.1.14
        MTL     | 10.1.1.7
        NMN     | 10.252.1.9

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.21
    ```

    > Depending on the networking configuration of the system, the CMN or CAN networks may not be present in SLS network data. No IP addresses will be allocated for networks that do not exist in SLS.

1. (`ncn-mw#`) Allocate IP addresses for the NCN in SLS and HSM by adding the `--perform-changes` argument to the command in the previous step.

    ```bash
    ./add_management_ncn.py allocate-ips --xname "$XNAME" --alias "$NODE" --perform-changes
    ```

    Example output:

    ```text
    IP Addressees have been allocated for x3000c0s36b0n0 (ncn-s004) and been added to SLS and BSS

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        CMN     | 10.103.11.42
        CAN     | 10.102.4.10
        HMN     | 10.254.1.14
        MTL     | 10.1.1.7
        NMN     | 10.252.1.9

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.21
    ```

## Next step

Proceed to the next step to [Add Switch Configuration](Add_Switch_Config.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
