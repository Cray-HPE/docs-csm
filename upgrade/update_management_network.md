# Update management network from 1.4 to 1.5

### New Features and Functions for v1.5

- Static Lags from the CDU switches to the CMMs on BOTH Dell and Mellanox.
- Apollo server port config, requires a trunk port to the iLO.
- BGP tftp static route removal.
- BGP passive neighbors (Aruba and Mellanox)

Some of these changes are applied as hotfixes and patches for 1.4, they may have already been applied.

#### CMM Static Lag configuration

- Verify the version of the CMM firmware, the firmware must be on version 1.4.20 in order to support static LAGs on the CDU switches.
- The command below should get you all the cmm firmware for a system.
- Update the password in the command before usage. Change ```root:password``` to the correct BMC password.

```
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'); cmms=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?type=comptype_chassis_bmc" | jq -r '.[] | .Xname'); for cmm in ${cmms}; do echo ${cmm}; curl -sk -u root:password https://${cmm}/redfish/v1/UpdateService/FirmwareInventory/BMC | jq .Version; done
```

Expected output

```
"cc.1.4.20-shasta-release.arm64.2021-03-24T17:47:03+00:00.0b7eb31"
```

- If the firmware is not on 1.4.20, notify the admin and get it updated before proceeding. 
- If you can't get the firmware version have the admin check for you. 
- (Aruba & Dell) If the CMMs are on the correct version, verify the LAG configuration is setup correctly.
- These configurations can be found on the CDU switch pages.
    - Dell [Dell CDU](../install/configure_dell_cdu_switch.md)
    - Aruba [Aruba CDU](../install/configure_aruba_cdu_switch.md)

#### BGP updates

- (ARUBA ONLY) Remove the tftp static route entry on the switches that are BGP participating in BGP.

```
sw-spine01# show ip route 10.92.100.60
 
Displaying ipv4 routes selected for forwarding
 
'[x/y]' denotes [distance/metric]
 
10.92.100.60/32, vrf default, tag 0
    via  10.252.1.9,  [1/0],  static
```
- If this static route still exists, remove it.

```
sw-spine01(config)# no ip route 10.92.100.60/32 10.252.1.9
```

- (ARUBA ONLY) re-run the bgp script if it's missing the tftp prefix-list and route-maps.
- These are also noted on the [BGP](../operations/update_bgp_neighbors.md) page.

Example TFTP prefix-list and route-map from running config. 
```
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
     set ip next-hop 10.103.2.13
route-map ncn-w001 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.20
route-map ncn-w001 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.12
```

- BGP script location ```/opt/cray/csm/scripts/networking/BGP```
- Usage [BGP](../operations/update_bgp_neighbors.md)

(ARUBA & MELLANOX) Verify the BGP neighbors are configured as passive.  
(ARUBA) The peering between the switches is not configured as passive, only the peerings with the workers.

```
router bgp 65533
    bgp router-id 10.252.0.2
    maximum-paths 8
    distance bgp 20 70
    neighbor 10.252.0.3 remote-as 65533
    neighbor 10.252.1.7 remote-as 65533
    neighbor 10.252.1.7 passive
    neighbor 10.252.1.8 remote-as 65533
    neighbor 10.252.1.8 passive
    neighbor 10.252.1.9 remote-as 65533
    neighbor 10.252.1.9 passive
    address-family ipv4 unicast
        neighbor 10.252.0.3 activate
        neighbor 10.252.1.7 activate
        neighbor 10.252.1.7 route-map ncn-w003 in
        neighbor 10.252.1.8 activate
        neighbor 10.252.1.8 route-map ncn-w002 in
        neighbor 10.252.1.9 activate
        neighbor 10.252.1.9 route-map ncn-w001 in
    exit-address-family
```

```
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
   router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
   router bgp 65533 vrf default neighbor 10.252.1.14 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.1.14 route-map ncn-w005
   router bgp 65533 vrf default neighbor 10.252.1.10 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.11 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.12 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.1.14 transport connection-mode passive
```

#### Apollo Server configuration

If the system has Appollo servers the configuration can be found here. [configuration](../operations/configure_mgmt_net_ports.md)