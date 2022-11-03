# Remove UAN Access to the CMN

To minimize downtime for UANs during an upgrade from CSM 1.0 to CSM 1.2, switch configurations allow UANs to run on both the CSM 1.0 CAN (which becomes the CSM 1.2 CMN) as well as the new CSM 1.2 CAN.
At the end of upgrade, switch configurations for UAN ports must be updated to remove the transitionally allowed access of UANs to the CMN. Manual removal of this port access is described in this document.
CSM 1.2.6 will automate this procedure.

## Prerequisites

As described in [Minimize UAN Downtime](bican_enable.md#minimize-uan-downtime), administrators can schedule a minimal-outage transition with users after the Management Network has been upgraded, but before new UANs are booted.
During this scheduled outage, the UAN IPv4 addresses are transitioned from the CMN to the CSM 1.2 CAN, via either reboot or running a CFS play.

1. All users of UANs running during the CSM 1.2 upgrade must have been transitioned to the CSM 1.2 CAN or CHN.
1. The administrator performing this procedure must have both of the following:
    - The CSM management network switch passwords.
    - The system network topology CCJ/Paddle file (preferred) or the system SHCD used to updated the management network switches.

## Procedure

1. Retrieve a token.

    ```bash
    ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' |
                base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ncn-m001# echo $TOKEN
    ```

    If the `TOKEN` is blank, it is likely that something is in error on the system or the core system is still being upgraded.

1. Query SLS for the BICAN toggle (`SystemDefaultRoute`).

    ```bash
    ncn-m001# BICAN=$(curl -s -k -S -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks/BICAN |
                         jq -r '.ExtraProperties.SystemDefaultRoute')
    ncn-m001# echo $BICAN
    ```

    An error in this step likely means that SLS has not been upgraded to include the BICAN network structure. **NOTE** If the value of `BICAN` is `CHN`, then skip the rest of this procedure; UAN switch port configurations are already correct.

1. Query SLS for the CAN VLAN.

    ```bash
    ncn-m001# CAN_VLAN=$(curl -s -k -S -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks/CAN |
                             jq '.ExtraProperties.Subnets | .[] | select(.Name=="bootstrap_dhcp") | .VlanID')
    ncn-m001# echo $CAN_VLAN
    ```

    An error in this step likely means that SLS has not been upgraded.

1. Back up the switch configurations.

    ```bash
    ncn-m001# cd /root && canu backup network --folder switch_backups
    ```

1. Use CANU to print the network topology.

    The Paddle/CCJ JSON file or SHCD used to update the Management Network should be reused here. The CCJ file is preferred as a means of input.

    Generating the CANU command line for the SHCD as an exercise here and not using the same command line used to update the switches in [Update the Management Network](../../../upgrade/1.2/Stage_0_Prerequisites.md#stage-03---upgrade-management-network)
will be time consuming and likely error prone. This is why the CCJ/Paddle option is recommended.

    - CCJ/Paddle (recommended)

        ```bash
        ncn-m001# canu validate paddle --ccj SYSTEM_CCJ_FILENAME
        ```

    - SHCD (ensure this command line is exactly the same as was used in updating the management network)

        ```bash
        ncn-m001# canu validate shcd -a NETWORK_ARCHITECTURE_TYPE --shcd SHCD_FILENAME --tabs LIST,OF,WORKSHEETS --corners TAB1_UPPER_LEFT, TAB1_LOWER_RIGHT...
        ```

1. Identify switches and ports associated with UAN on CAN.

    The CANU output will contain a list of switches and the port use for each switch.
    UANs will only be associated with leaf or spine switches (named `sw-leaf-` and `sw-spine-` respectively). UANs will be identified in the output via their common names (for example, `uan001`).
Only UAN CAN ports need to be identified. Only the second port of OCP and PCIe slots are used for UAN CAN, according to [cabling standards](../../../install/cable_management_network_servers.md).
Custom or non-Plan-of-Record UAN configurations will need to be handled appropriately.

    - **Example:** Identify switches and UAN CAN ports.

        Only port two for OCP and PCIe cards. Note that CANU output only lists the switch port, not the chassis or slot.
        On Aruba switches themselves, interfaces are identified by `CHASSIS/SLOT/PORT`. On all CSM Management switches, values for `CHASSIS` and `SLOT` are `1`.
        As an example, CANU slot `27` would be interface `1/1/27` on the switch. Mellanox switches follow the format `1/PORT`.
  
        ```text
        1: sw-spine-001 has the following port usage:
            ...snip...
            67==>uan002:ocp:2
            ...snip...
            71==>uan001:ocp:2
            ...snip...
        2: sw-spine-002 has the following port usage:
            ...snip...
            68==>uan002:pcie-slot1:2
            ...snip...
            72==>uan001:pscie-slot1:2
            ...snip...
        ```

    - **Example:** (Recommended) Create a document of UAN ports.

        This step is simply to consolidate the output and make the manual switch modification steps less error prone.
        Using the identified CANU output, create a document listing switches and associated UAN ports. This should look similar in layout (not content) to the following:

        ```text
        sw-spine-001:
            1/1/67
            1/1/71
        sw-spine-002:
            1/1/68
            1/1/72
        ```

1. Log in to each switch in the previously generated list document and run the following commands *for each identified UAN port*.

    Only one port reconfiguration is shown in this example. Ensure that the procedure is run for **all** identified ports.
    Be aware of the particular switch type: Aruba, Dell, or Mellanox.

    - Log in to the switch, entering the administrative password when prompted.
  
        ```bash
        ncn-m001# ssh admin@SWITCH
        ```

    - Enter configuration mode on the switch.

        - Aruba

            ```console
           sw# configure terminal
           ```

        - Mellanox

            ```console
            sw# enable
            sw# configure terminal
            ```

    - *For each UAN port identified with UAN CAN* (`UAN_PORT`) find the associated LAG (bond) (`UAN_LAG`).
  
      - Aruba

          ```console
          sw# show running-config interface 1/1/UAN_PORT
          ```

          Example output:

          ```text
          interface 1/1/UAN_PORT
          no shutdown
          mtu 9198
          description uan001:ocp:2<==sw-spine-001
          lag UAN_LAG
          ```

      - Mellanox

          ```console
          sw# show running-config interface ethernet 1/UAN_PORT
          ```

          Example output:

          ```text
          interface ethernet 1/UAN_PORT speed 40G force
          interface ethernet 1/UAN_PORT mlag-channel-group UAN_LAG mode active
          interface ethernet 1/UAN_PORT description "uan001:ocp:2"
          ```

    - *For each UAN LAG (bond) identified* (`UAN_LAG`) on the switch, allow the port to access only the VLAN identified in a previous step with the `CAN_VLAN`.

      - Aruba
  
          ```console
          sw# interface lag UAN_LAG multi-chassis
          sw# vlan trunk allowed CAN_VLAN
          ```

      - Mellanox
  
          ```console
          sw# interface mlag-port-channel UAN_LAG switchport hybrid allowed-vlan CAN_VLAN
          ```

    - Save the switch configuration.

      - Aruba

          ```console
          sw# write memory
          ```

      - Mellanox

          ```console
          sw# write memory
          ```
