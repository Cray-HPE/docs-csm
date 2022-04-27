# Allocate NCN IP Addresses

## Description

This procedure allocates IP addresses for an NCN being added to a system to the applicable networks (HMN, NMN, MTL, CAN, etc.) to the System Layout Service (SLS) and the Boot Script Service (BSS).

This procedure will perform and verify the following:
1. If the NCN being added is ncn-m00[1-3], ncn-w00[1-3], or ncn-s00[1-3], it is expected to already be present and consistent between SLS and BSS.
1. Otherwise, new IP addresses for the NCN will be allocated and verified to be within the static IP address pool in the `bootstrap_dhcp` subnet for the various networks in system.

## Procedure
1.  Retrieve an API token:
    ```bash
    ncn-m# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
            -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
            | jq -r '.access_token')
    ```

1.  Determine the component name (xname) of the NCN by referring to the HMN of the systems SHCD, if it has not been determined yet.

    Sample row from the `HMN` tab of an SHCD:
    | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
    | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
    | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

    > The Source name for the a worker NCN would be in the format of `wn01`, master NCNs are `mn01`, and storage NCNs have `sn01`.

    Node xname format: xXcCsSbBnN

    |   |                | SHCD Column to reference | Description
    | - | -------------- | ------------------------ | -----------
    | X | Cabinet number | SourceRack (K20)         | The Cabinet or rack number containing the Management NCN.
    | C | Chassis number |                          | For air-cooled nodes the chassis is 0.
    | S | Slot/Rack U    | Source Location (L20)    | The Slot of the node is determined by the bottom most rack U that node occupies.
    | B | BMC number     |                          | For Management NCNs the BMC number is 0.
    | N | Node number    |                          | For Management NCNs the Node number is 0.


    ```bash
    ncn-m# export XNAME=x3000c0s4b0n0
    ```

1.  Perform a dry-run of allocating IP addresses for the NCN:
    ```bash
    ncn-m# ./add_management_ncn.py allocate-ips \
        --xname $XNAME \
        --alias $NODE
    ```

    Example output:
    ```
    ...
    IP Addressees have been allocated for x3000c0s36b0n0 (ncn-s004) and been added to SLS and BSS
        WARNING A Dryrun was performed, and no changes were performed to the system

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        CAN     | 10.102.4.15
        HMN     | 10.254.1.22
        MTL     | 10.1.1.11
        NMN     | 10.252.1.13

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.21
    ```

1.  Allocate IP addresses for the NCN in SLS and HSM by adding the `--perform-changes` argument to the command in the previous step:

    ```bash
    ncn-m# ./add_management_ncn.py allocate-ips \
        --xname $XNAME \
        --alias $NODE \
        --perform-changes
    ```

    Example output:
    ```
    IP Addressees have been allocated for x3000c0s36b0n0 (ncn-s004) and been added to SLS and BSS

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        CAN     | 10.102.4.15
        HMN     | 10.254.1.22
        MTL     | 10.1.1.11
        NMN     | 10.252.1.13

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.21
    ```

Proceed to the next step to [Add Switch Config](Add_Switch_Config.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
