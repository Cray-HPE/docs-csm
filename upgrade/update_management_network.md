# Update Management Network From 1.4 To 1.5

**IMPORTANT**: These procedures only need to be followed if upgrading from CSM 0.9 (Shasta 1.4). If upgrading from CSM 1.0.1 (Shasta 1.5), these procedures should already have been done.

1. [New Features and Functions for v1.5](#new-features-and-functions)
1. [Accessing Network Switches](#accessing-network-switches)
    1. [Finding Switch Hostnames and IP Addresses](#finding-switch-hostnames)
    1. [Reminders](#switch-reminders)
1. [CMM Static Lag Configuration](#cmm-static-lag-configuration)
1. [BGP](#bgp-updates)
    1. [Aruba](#bgp-aruba)
    1. [Mellanox](#bgp-mellanox)
1. [Apollo Server Configuration](#apollo-server-configuration)

<a name="new-features-and-functions"></a>
## 1. New Features and Functions for v1.5

- Static Lags from the CDU switches to the CMMs (Aruba and Dell).
- HPE Apollo server port config, requires a trunk port to the iLO.
- BGP TFTP static route removal (Aruba).
- BGP passive neighbors (Aruba and Mellanox)

Some of these changes are applied as hotfixes and patches for 1.4; they may have already been applied.

<a name="accessing-network-switches"></a>
## 2. Accessing Network Switches

For some of the procedures on this page you will need to SSH into your switches as the `admin` user to verify settings and possibly make changes.

<a name="finding-switch-hostnames"></a>
### 2.1 Finding Switch Hostnames and IP Addresses

If you do not already know the hostnames or IP addresses of the switches in the system, here are some methods to determine them.

#### Default Values

The default switch hostnames are in the following formats:
```text
sw-spine-001
sw-spine-002
sw-agg-001
sw-agg-002
...
sw-leaf-001
sw-leaf-002
...
sw-cdu-001
sw-cdu-002
...
```

#### Get Spine Switch IPs from Kubernetes

One way to get the IP addresses for the two spine switches is from the `metallb-system` configmap in Kubernetes:
```bash
ncn# kubectl get cm config -n metallb-system -o json | 
        jq -r '.data | .config' | 
        yq r -  -j | 
        jq -r '.peers | .[]."peer-address"'
```

Expected output is similar to the following:
```text
10.252.0.2
10.252.0.3
```

#### Check `/etc/hosts`

A quick method to look for the hostnames and IP addresses is by looking in `/etc/hosts` on an NCN:
```bash
ncn# grep sw /etc/hosts
```

Expected output looks similar to the following:
```text
10.252.0.2      sw-spine-001
10.252.0.3      sw-spine-002
10.252.0.4      sw-agg-001
10.252.0.5      sw-agg-002
10.252.0.6      sw-agg-003
10.252.0.7      sw-agg-004
10.252.0.8      sw-leaf-001
10.252.0.9      sw-leaf-002
10.252.0.10     sw-leaf-003
10.252.0.11     sw-leaf-004
10.252.0.12     sw-cdu-001
10.252.0.13     sw-cdu-002
```

<a name="switch-reminders"></a>
### 2.2 Reminders

> On Mellanox switches, the `enable` command must be issued before some other commands will work properly.

> If changes are made to a switch configuration, to not forget to save them with the `write memory` command.

<a name="cmm-static-lag-configuration"></a>
## 3. CMM Static Lag Configuration

For systems with Mountain cabinets ONLY, one must verify the version of the Mountain CMM firmware. The firmware must be on version 1.4.20 or greater in order to support static LAGs on the CDU switches. Follow this procedure to do so:

1. Set environment variables with the credentials for the Mountain CMMs:

    ```bash
    ncn# read -s BMC_USER
    ncn# read -s BMC_PASS
    ncn# export BMC_USER BMC_PASS
    ```

1. Obtain an API token:

    ```bash
    ncn# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | 
                        jq -r '.access_token')
    ```

1. Run the following script to get a report on the Mountain CMM firmware levels:

    ```bash
    ncn# /usr/share/doc/csm/upgrade/scripts/get_mountain_cmm_firmware_versions.py
    ```

    Expected output looks similar to the following:
    ```text
    Retrieving list of Mountain CMM xnames
    Making GET request to https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?type=comptype_chassis_bmc&class=Mountain
    
    Found 3 Mountain CMM(s) in the system: x1001c5, x1001c4, x1000c5
    
    Retrieving list of Redfish endpoint FQDNs of the Mountain CMM(s)
    Making GET request to https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/ComponentEndpoints?id=x1001c5&id=x1001c4&id=x1000c5
    
    Found 3 Mountain CMM Redfish FQDN(s) in the system: x1001c5b0, x1000c5b0, x1001c4b0
    
    Checking firmware version of x1001c5b0
    Making GET request to https://x1001c5b0/redfish/v1/UpdateService/FirmwareInventory/BMC
    
    Checking firmware version of x1000c5b0
    Making GET request to https://x1000c5b0/redfish/v1/UpdateService/FirmwareInventory/BMC
    
    Checking firmware version of x1001c4b0
    Making GET request to https://x1001c4b0/redfish/v1/UpdateService/FirmwareInventory/BMC
    
    Mountain CMM | Firmware Version
    x1000c5b0    | cc.1.5-31-shasta-release.arm64.2021-11-03T03:50:18+00:00.b9ced71
    x1001c4b0    | cc.1.5-31-shasta-release.arm64.2021-11-03T03:50:18+00:00.b9ced71
    x1001c5b0    | cc.1.5-31-shasta-release.arm64.2021-11-03T03:50:18+00:00.b9ced71
    
    Firmware versions successfully reported
    ```

1. Proceed to the appropriate next step:
    - If the firmware is not on 1.4.20 or greater, notify the admin and get it updated before proceeding.
    - If you cannot get the firmware version, have the admin check for you.
    - (Aruba and Dell) If the CMMs are on the correct version, verify the LAG configuration is setup correctly. These configurations can be found on the CDU switch pages under the "Configure LAG for CMMs" section:
        - [Dell CDU](../install/configure_dell_cdu_switch.md)
        - [Aruba CDU](../install/configure_aruba_cdu_switch.md)

<a name="bgp-updates"></a>
## 4. BGP

- This configuration is applied to the switches running BGP. This is set during CSI configuration. This is likely the spine switches, if there are no aggregation switches on the system.
- To check if the switches are running BGP, run the commands below. The output might not be exact, but it shows that the switch is running BGP.
- These checks and procedures must be followed on ALL switches running BGP.
- More BGP documentation can be found here [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md).

The procedures to follow are broken up by switch type:
* [Aruba](#bgp-aruba)
* [Mellanox](#bgp-mellanox)

<a name="bgp-aruba"></a>
### 4.1 BGP: Aruba

#### BGP: Aruba: Check Status

```
sw-spine-001# show run | include bgp
router bgp 65533
    bgp router-id 10.252.0.2
```

#### BGP: Aruba: Make Updates

- Remove the TFTP static route entry on the switches that are participating in BGP.
- This was set during initial install to workaround an issue with TFTP booting.
- Log into the switches running BGP. In this example it is the spine switches.
- Run the following command once logged in:

```
sw-spine01# show ip route 10.92.100.60

Displaying IPv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

10.92.100.60/32, vrf default, tag 0
    via  10.252.1.x,  [1/0],  static
```

- If you see `via  10.252.1.x,  [1/0],  static`, then you will need to remove this route.

```
sw-spine01# config t
sw-spine01(config)# no ip route 10.92.100.60/32 10.252.1.x
```

- Next step is to re-run the BGP script.
- It is located at `/opt/cray/csm/scripts/networking/BGP/Aruba_BGP_Peers.py`
- This is documented on this page [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md)

#### BGP: Aruba: Check Configuration

Log into the switches that you ran the BGP script against and execute `sw-spine-001# show run | begin "ip prefix-list"`

Do not copy this configuration onto your switches.
The following configuration needs to be present.
`ip prefix-list tftp seq 10 permit 10.92.100.60/32 ge 32 le 32`
`neighbor 10.252.1.x passive`
The neighbors should be the NMN IP addresses of the worker nodes.
Here is an example output from an Aruba switch with 3 worker nodes.

```
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

If the configuration does not look like the example above, check the [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md) docs.

When the configuration is correct, if any configuration changes were made, run `write memory` on all of the switches to save it.

<a name="bgp-mellanox"></a>
### 4.2 BGP: Mellanox

#### BGP: Mellanox: Check Status

```
sw-spine-001 [standalone: master] > enable
sw-spine-001 [standalone: master] > show protocols | include bgp
 bgp:                    enabled
```

#### BGP: Mellanox: Make Updates

The Mellanox BGP neighbors need to configured as passive.

To do this, log into the switches and run the commands below.
The neighbors will be the NMN IP addresses of ALL the worker nodes. You may have more than 3.

```
sw-spine-001 [standalone: master] > ena
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.10 transport connection-mode passive
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.11 transport connection-mode passive
sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default neighbor 10.252.1.12 transport connection-mode passive
```

Run the command below to verify the configuration got applied correctly.

```
sw-spine-001 [standalone: master] (config) # show protocols | include bgp
```

#### BGP: Mellanox: Check Configuration

The configuration should look similar to the following. This is an example only.
The neighbors should be the ALL of the NCN Workers and their NMN addresses; they will not peer over any other network.

```
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

If the configuration does not look like the example above, check the [Update BGP Neighbors](../operations/network/metallb_bgp/Update_BGP_Neighbors.md) docs.

When the configuration is correct, if any configuration changes were made, run `write memory` on all of the switches to save it.

<a name="apollo-server-configuration"></a>
## 5. Apollo Server Configuration

If the system has Apollo servers, the required configuration can be found in the 
[Management Network Access Port Configurations page](../operations/network/management_network/Management_Network_Access_Port_Configurations.md), 
under the section "Apollo Server Port Configuration".

[Return to main upgrade page](index.md)
