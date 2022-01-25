# Update management network from 1.4 to 1.5

**IMPORTANT**: These procedures only need to be followed if upgrading from CSM 0.9 (Shasta 1.4). If upgrading from CSM 1.0.1 (Shasta 1.5), these procedures should already have been done.

## New Features and Functions for v1.5

- Static Lags from the CDU switches to the CMMs (Aruba and Dell).
- HPE Apollo server port config, requires a trunk port to the iLO.
- BGP TFTP static route removal (Aruba).
- BGP passive neighbors (Aruba and Mellanox)

Some of these changes are applied as hotfixes and patches for 1.4, they may have already been applied.

## CMM Static Lag configuration

For systems with mountain cabinets ONLY. Changes must

- Verify the version of the CMM firmware, the firmware must be on version 1.4.20 or greater in order to support static LAGs on the CDU switches.
- The command below should get you all the cmm firmware for a system.
- Update the password in the command before usage. Change `root:password` to the correct BMC password.

```bash
ncn# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'); cmms=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?type=comptype_chassis_bmc" | jq -r '.[] | .Xname'); for cmm in ${cmms}; do echo ${cmm}; curl -sk -u root:password https://${cmm}/redfish/v1/UpdateService/FirmwareInventory/BMC | jq .Version; done
```

Alternatively: 

```bash
ncn# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'); cmms=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?type=comptype_chassis_bmc" | jq -r '.[] | .Xname'); for cmm in ${cmms}; do echo ${cmm}; curl -sk -u root:initial0 https://${cmm}/redfish/v1/UpdateService/FirmwareInventory/BMC/b0 | jq .Version; done
```

Expected output

```bash
"cc.1.4.2x-shasta-release.arm64.2021-03-24T17:47:03+00:00.0b7eb31"
```

- If the firmware is not on 1.4.20 or greater, notify the admin and get it updated before proceeding.
- If you cannot get the firmware version, have the admin check for you.
- (Aruba and Dell) If the CMMs are on the correct version, verify the LAG configuration is setup correctly.
- These configurations can be found on the CDU switch pages under the "Configure LAG for CMMs" section.
  - Dell [Dell CDU](../install/configure_dell_cdu_switch.md)
  - Aruba [Aruba CDU](../install/configure_aruba_cdu_switch.md)

## BGP updates

- This configuration is applied to the switches running BGP, this is set during CSI configuration. This is likely the spine switches if there are no aggregation switches on the system.
- To check if the switches are running BGP run the commands below, the output might not be exact but it shows that the switch is running BGP.

### Check BGP Status

**Aruba:**

```bash
sw-spine-001# show run | include bgp
router bgp 65533
    bgp router-id 10.252.0.2
```

**Mellanox:**

```bash
sw-spine-001 [standalone: master] > ena
sw-spine-001 [standalone: master] # show run | include bgp
   protocol bgp
   router bgp 65533 vrf default
   router bgp 65533 vrf default router-id 10.252.0.2 force
   router bgp 65533 vrf default maximum-paths ibgp 32
```

### Aruba BGP updates

- Remove the TFTP static route entry on the switches that are BGP participating in BGP.
- This was set during initial install to workaround an issue with tftp booting.
- Log into the switches running BGP, in this example it is the spine switches.
- Run the following command once logged in.

```bash
sw-spine01# show ip route 10.92.100.60

Displaying ipv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

10.92.100.60/32, vrf default, tag 0
    via  10.252.1.x,  [1/0],  static
```

- If you see `via  10.252.1.x,  [1/0],  static` then you will need to remove this route.

```bash
sw-spine01# config t
sw-spine01(config)# no ip route 10.92.100.60/32 10.252.1.x
```

- Next step is to re-run the BGP script.
- It is located at `/opt/cray/csm/scripts/networking/BG/Aruba_BGP_Peers.py`
- This is documented on this page [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md)

### Check Aruba BGP configuration

- Log into the switches that you ran the BGP script against and execute `sw-spine-001# show run | begin "ip prefix-list"`

Do not copy this configuration onto your switches.
Note: the following configuration needs to be present.
`ip prefix-list tftp seq 10 permit 10.92.100.60/32 ge 32 le 32`
`neighbor 10.252.1.x passive`
The neighbors should be the NMN IP of the worker nodes.
Here is an example output from an Aruba switch with 3 worker nodes.

```bash
ip prefix-list pl-can seq 10 permit 10.103.11.0/24 ge 24
ip prefix-list pl-hmn seq 20 permit 10.94.100.0/24 ge 24
ip prefix-list pl-nmn seq 30 permit 10.92.100.0/24 ge 24
ip prefix-list tftp seq 10 permit 10.92.100.60/32 ge 32 le 32
!
!
!
!
route-map ncn-w001 permit seq 10
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.7
     set local-preference 1000
route-map ncn-w001 permit seq 20
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.8
     set local-preference 1100
route-map ncn-w001 permit seq 30
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.9
     set local-preference 1200
route-map ncn-w001 permit seq 40
     match ip address prefix-list pl-can
     set ip next-hop 10.103.11.10
route-map ncn-w001 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.14
route-map ncn-w001 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.9
route-map ncn-w002 permit seq 10
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.7
     set local-preference 1000
route-map ncn-w002 permit seq 20
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.8
     set local-preference 1100
route-map ncn-w002 permit seq 30
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.9
     set local-preference 1200
route-map ncn-w002 permit seq 40
     match ip address prefix-list pl-can
     set ip next-hop 10.103.11.9
route-map ncn-w002 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.12
route-map ncn-w002 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.8
route-map ncn-w003 permit seq 10
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.7
     set local-preference 1000
route-map ncn-w003 permit seq 20
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.8
     set local-preference 1100
route-map ncn-w003 permit seq 30
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.9
     set local-preference 1200
route-map ncn-w003 permit seq 40
     match ip address prefix-list pl-can
     set ip next-hop 10.103.11.8
route-map ncn-w003 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.10
route-map ncn-w003 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.7
!
router ospf 1
    router-id 10.2.0.2
    area 0.0.0.0
router ospfv3 1
    router-id 10.2.0.2
    area 0.0.0.0
router bgp 65533
    bgp router-id 10.252.0.2
    maximum-paths 8
    neighbor 10.252.0.3 remote-as 65533
    neighbor 10.252.1.7 remote-as 65533
    neighbor 10.252.1.8 remote-as 65533
    neighbor 10.252.1.9 remote-as 65533
    address-family ipv4 unicast
        neighbor 10.252.0.3 activate
        neighbor 10.252.1.7 activate
        neighbor 10.252.1.7 passive
        neighbor 10.252.1.7 route-map ncn-w003 in
        neighbor 10.252.1.8 activate
        neighbor 10.252.1.8 passive
        neighbor 10.252.1.8 route-map ncn-w002 in
        neighbor 10.252.1.9 activate
        neighbor 10.252.1.9 passive
        neighbor 10.252.1.9 route-map ncn-w001 in
    exit-address-family
!
```

### Mellanox BGP updates

- The Mellanox BGP neighbors need to configured as passive.

To do this, log into the switches and run the commands below.
the neighbor will be the NMN IP of ALL the worker nodes. You may have more than 3.

```bash
sw-spine-001 [standalone: master] > ena
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.10 transport connection-mode passive
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.11 transport connection-mode passive
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.12 transport connection-mode passive
```

Run the command below to verify the configuration got applied correctly.

```bash
sw-spine-001 [standalone: master] (config) # show run protocol bgp
```

### Check Mellanox BGP Configuration

The configuration should look similar to the following. This is an example only.
More BGP documentation can be found here [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md).

The neighbors should be the ALL of the NCN-Workers and their NMN address, they will not peer over any other network.

```bash
## BGP configuration
##
   protocol bgp
   router bgp 65533 vrf default
   router bgp 65533 vrf default router-id 10.252.0.2 force
   router bgp 65533 vrf default maximum-paths ibgp 32
   router bgp 65533 vrf default neighbor 10.252.1.10 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.1.10 route-map ncn-w001
   router bgp 65533 vrf default neighbor 10.252.1.11 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.1.11 route-map ncn-w002
   router bgp 65533 vrf default neighbor 10.252.1.12 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.1.12 route-map ncn-w003
   router bgp 65533 vrf default neighbor 10.252.1.10 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.11 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.12 transport connection-mode passive

```
If the configuration does not look like the example above check the [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md) docs.
#### Apollo Server configuration

If the system has Apollo servers, the configuration can be found [here](../operations/configure_mgmt_net_ports.md) under the section "Apollo Server port config".

[Return to main upgrade page](../index.md)
