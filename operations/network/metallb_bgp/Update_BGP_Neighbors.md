# Update BGP Neighbors

This page will detail the manual procedure to configure and verify BGP neighbors on the management switches.

You will not have BGP peers until CSM `install.sh` has run. This is where MetalLB is deployed.

* How do I check the status of the BGP neighbors?
    * Log into the spine switches and run `show bgp ipv4 unicast summary` for Aruba/HPE switches and `show ip bgp summary` for Mellanox.
* Are my Neighbors stuck in IDLE?
    * Running `clear ip bgp all` on the Mellanox and `clear bgp *` on the Arubas will restart the BGP process. This process may need to be done when a system is reinstalled or when a worker node is rebuilt.
    * If you cannot get the neighbors out of IDLE, make sure that passive neighbors are configured. This is in the automated scripts and shown in the example below. Passive neighbors should only be configured on NCN neighbors.
* The BGP neighbors will be the worker NCN IP addresses on the NMN (node management network) (VLAN002). If your system is using HPE/Aruba, one of the neighbors will be the other spine switch.

## Generate MetalLB configmap
* Depending on the network architecture of your system you may need to peer with switches other than the spines. CSI has a BGP peers argument that accepts 'aggregation' as an option, if no option is defined it will default to the spines as being the MetalLB peers.

CSI CLI arguments with `--bgp-peers aggregation`
```bash
linux# export IPMI_PASSWORD=changeme
linux# csi config init --bootstrap-ncn-bmc-user root --bootstrap-ncn-bmc-pass $IPMI_PASSWORD --ntp-pools cfntp-4-1.us.cray.com,cfntp-4-2.us.cray.com --can-external-dns 10.103.8.113 --can-gateway 10.103.8.1 --site-ip 172.30.56.2/24 --site-gw 172.30.48.1 --site-dns 172.30.84.40 --site-nic em1 --system-name odin --bgp-peers aggregation
```

## Automated Process
For Mellanox there is a script `mellanox_set_bgp_peers.py` and for Aruba there is CANU (Cray Automated Network Utility).
In order for these scripts to work the following commands will need to be applied on the switches.

### Aruba

1. In order for the automated process to work, the following command will need to be run on the switches:

    ```
    sw-spine-001(config)# https-server rest access-mode read-write
    ```

2. Run CANU.

    CANU requires three parameters: the IP address of switch 1, the IP address of Switch 2, and the path to the directory containing the file `sls_input_file.json`.

    The IP addresses in this example should be replaced by the IP addresses of the switches. Make sure the `$SLS_PATH` variable is set to the correct directory.

    ```bash
    pit# SYSTEM_NAME=eniac
    pit# SLS_PATH="/var/www/ephemeral/prep/${SYSTEM_NAME}/"
    pit# canu -s 1.5 config bgp --ips 10.252.0.2,10.252.0.3 --csi-folder "${SLS_PATH}"
    ```

### Mellanox

1. In order for the automated process to work, the following commands will need to be run on the switches:

    ```
    sw-spine-001 [standalone: master] > enable
    sw-spine-001 [standalone: master] # configure terminal
    sw-spine-001 [standalone: master] (config) # json-gw enable
    ```

2. Run the BGP helper script.

    The BGP helper script requires three parameters: the IP address of switch 1, the IP address of Switch 2, and the path to CSI-generated network files.

    * The IP addresses used should be Node Management Network IP addresses (NMN). These IP addresses will be used for the BGP Router-ID.
    * The path to the CSI-generated network files must include `CAN.yaml`, `HMN.yaml`, `HMNLB.yaml`, `NMNLB.yaml`, and `NMN.yaml`. The path must include the `$SYSTEM_NAME.`

    The IP addresses in this example should be replaced by the IP addresses of the switches. Make sure the `$CSI_PATH` variable is set to the correct directory.

    ```bash
    pit# SYSTEM_NAME=eniac
    pit# CSI_PATH="/var/www/ephemeral/prep/${SYSTEM_NAME}/networks/"
    pit# /usr/local/bin/mellanox_set_bgp_peers.py 10.252.0.2 10.252.0.3 "${CSI_PATH}"
    ```

   `*WARNING*` The mellanox_set_bgp_peers.py script assumes that the prefix length of the CAN is `/24`. If that value is incorrect for the system being installed then update the script with the correct prefix length by editing the following line.

    ```python
    cmd_prefix_list_can = "ip prefix-list pl-can seq 30 permit {} /24 ge 24".format()
    ```

### Verification

After following the previous steps, you will need to verify the configuration and verify the BGP peers are `ESTABLISHED`. If it is early in the install process and the CSM services have not been deployed yet, there will not be speakers to peer with, so the peering sessions may not be `ESTABLISHED` yet. This is expected and not a problem.

## Manual Process

On the Aruba switches, the output of the `show bgp ipv4 unicast summary` command should look like the following if the MetalLB speaker pods are running. If it is early in the install process and the CSM services have not been deployed yet, you may see the neighbors in `Idle`, `Active`, or `Connect` state. This is expected and not a problem.
```
sw-spine-001# show bgp ipv4 unicast summary
VRF : default
BGP Summary
-----------
 Local AS               : 65533        BGP Router Identifier  : 10.252.0.1
 Peers                  : 4            Log Neighbor Changes   : No
 Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60

 Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
 10.252.0.3      65533       31457   31474   00m:02w:04d  Established   Up
 10.252.2.8      65533       54730   62906   00m:02w:04d  Established   Up
 10.252.2.9      65533       54732   62927   00m:02w:04d  Established   Up
 10.252.2.18     65533       54732   62911   00m:02w:04d  Established   Up
```
On the Mellanox switches, first you must run the switch commands listed in the Automated section above. The output of the `show ip bgp summary` command should look like the following if the MetalLB speaker pods are running. If it is early in the install process and the CSM services have not been deployed yet, you may see the neighbors in `IDLE`, `ACTIVE`, or `CONNECT` state. This is expected and not a problem.

```
sw-spine-001 [standalone: master] # show ip bgp summary

VRF name                  : default
BGP router identifier     : 10.252.0.1
local AS number           : 65533
BGP table version         : 308
Main routing table version: 308
IPV4 Prefixes             : 261
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
------------------------------------------------------------------------------------------------------------------
10.252.0.7        4    65533        37421     42948     308       0      0      12:23:16:07   ESTABLISHED/53
10.252.0.8        4    65533        37421     42920     308       0      0      12:23:16:07   ESTABLISHED/51
10.252.0.9        4    65533        37420     42962     308       0      0      12:23:16:07   ESTABLISHED/51
```
* If the BGP neighbors are not in the `ESTABLISHED` state make sure the IP addresses are correct for the route-map and BGP configuration and the MetalLB speaker pods are running on all of the workers.
* If IP addresses are incorrect you will have to update the configuration to match the IP addresses, the configuration below will need to be edited.
* You can get the NCN IP addresses from the CSI-generated files (`NMN.yaml`, `CAN.yaml`, `HMN.yaml`), these IP addresses are also located in `/etc/dnsmasq.d/statics.conf` on the PIT node.
    ```bash
    pit# grep w00 /etc/dnsmasq.d/statics.conf | grep nmn
    host-record=ncn-w003,ncn-w003.nmn,10.252.1.13
    host-record=ncn-w002,ncn-w002.nmn,10.252.1.14
    host-record=ncn-w001,ncn-w001.nmn,10.252.1.15
    ```
* The route-map configuration will require you to get the HMN, and CAN IP addresses as well. Note the `Bond0 Mac0/Mac1` entry is for the NMN.
    ```bash
    pit# grep ncn-w /etc/dnsmasq.d/statics.conf | egrep "Bond0|HMN|CAN" | grep -v mgmt
    dhcp-host=50:6b:4b:08:d0:4a,10.252.1.13,ncn-w003,20m # Bond0 Mac0/Mac1
    dhcp-host=50:6b:4b:08:d0:4a,10.254.1.20,ncn-w003,20m # HMN
    dhcp-host=50:6b:4b:08:d0:4a,10.102.4.12,ncn-w003,20m # CAN
    dhcp-host=98:03:9b:0f:39:4a,10.252.1.14,ncn-w002,20m # Bond0 Mac0/Mac1
    dhcp-host=98:03:9b:0f:39:4a,10.254.1.22,ncn-w002,20m # HMN
    dhcp-host=98:03:9b:0f:39:4a,10.102.4.13,ncn-w002,20m # CAN
    dhcp-host=98:03:9b:bb:a9:94,10.252.1.15,ncn-w001,20m # Bond0 Mac0/Mac1
    dhcp-host=98:03:9b:bb:a9:94,10.254.1.24,ncn-w001,20m # HMN
    dhcp-host=98:03:9b:bb:a9:94,10.102.4.14,ncn-w001,20m # CAN
    ```
* The Aruba configuration will require you to set the other peering switch as a BGP neighbor, the Mellanox configuration does not require this.
* You will need to delete the previous route-map, and BGP configuration on both switches.

### Aruba delete commands
```
sw-spine-001# configure terminal

sw-spine-001(config)# no router bgp 65533
This will delete all BGP configurations on this device.
Continue (y/n)? y

sw-spine-001(config)# no route-map ncn-w003
sw-spine-001(config)# no route-map ncn-w002
sw-spine-001(config)# no route-map ncn-w001
```
### Aruba configuration example

```
ip prefix-list pl-can seq 10 permit 193.167.208.0/25 ge 24
ip prefix-list pl-hmn seq 20 permit 10.94.100.0/24 ge 24
ip prefix-list pl-nmn seq 30 permit 10.92.100.0/24 ge 24
ip prefix-list tftp seq 10 permit 10.92.100.60/32 ge 32 le 32

route-map ncn-w001 permit seq 10
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.7
     set local-preference 1000
route-map ncn-w001 permit seq 20
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.8
     set local-preference 1100
route-map ncn-w001 permit seq 30ß
     match ip address prefix-list tftp
     match ip next-hop 10.252.1.9
     set local-preference 1200
route-map ncn-w001 permit seq 40
     match ip address prefix-list pl-can
     set ip next-hop 10.103.10.10
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
     set ip next-hop 10.103.10.9
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
     set ip next-hop 10.103.10.8
route-map ncn-w003 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.10
route-map ncn-w003 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.7
!
router ospfv3 1
    area 0.0.0.0
router bgp 65533
    distance bgp 20 70
    bgp router-id 10.252.0.2
    maximum-paths 8
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

### Mellanox delete commands

```
sw-spine-001 [standalone: master] #
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # no router bgp 65533
sw-spine-001 [standalone: master] (config) # no route-map ncn-w001
sw-spine-001 [standalone: master] (config) # no route-map ncn-w002
sw-spine-001 [standalone: master] (config) # no route-map ncn-w003
```

### Mellanox configuration example

```
## Route-maps configuration
##
   route-map rm-ncn-w001 permit 10 match ip address pl-nmn
   route-map rm-ncn-w001 permit 10 set ip next-hop 10.252.0.7
   route-map rm-ncn-w001 permit 20 match ip address pl-hmn
   route-map rm-ncn-w001 permit 20 set ip next-hop 10.254.0.7
   route-map rm-ncn-w001 permit 30 match ip address pl-can
   route-map rm-ncn-w001 permit 30 set ip next-hop 10.103.8.7
   route-map rm-ncn-w002 permit 10 match ip address pl-nmn
   route-map rm-ncn-w002 permit 10 set ip next-hop 10.252.0.8
   route-map rm-ncn-w002 permit 20 match ip address pl-hmn
   route-map rm-ncn-w002 permit 20 set ip next-hop 10.254.0.8
   route-map rm-ncn-w002 permit 30 match ip address pl-can
   route-map rm-ncn-w002 permit 30 set ip next-hop 10.103.8.8
   route-map rm-ncn-w003 permit 10 match ip address pl-nmn
   route-map rm-ncn-w003 permit 10 set ip next-hop 10.252.0.9
   route-map rm-ncn-w003 permit 20 match ip address pl-hmn
   route-map rm-ncn-w003 permit 20 set ip next-hop 10.254.0.9
   route-map rm-ncn-w003 permit 30 match ip address pl-can
   route-map rm-ncn-w003 permit 30 set ip next-hop 10.103.8.9

##
## BGP configuration
##
   protocol bgp
   router bgp 65533 vrf default
   router bgp 65533 vrf default router-id 10.252.0.1 force
   router bgp 65533 vrf default maximum-paths ibgp 32
   router bgp 65533 vrf default neighbor 10.252.0.7 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.7 route-map ncn-w001
   router bgp 65533 vrf default neighbor 10.252.0.7 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.0.8 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.8 route-map ncn-w002
   router bgp 65533 vrf default neighbor 10.252.0.8 transport connection-mode passive
   router bgp 65533 vrf default neighbor 10.252.0.9 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.9 route-map ncn-w003
   router bgp 65533 vrf default neighbor 10.252.0.9 transport connection-mode passive
```

* Once the IP addresses are updated for the route-maps and BGP neighbors you may need to restart the BGP process on the switches, you do this by running `clear ip bgp all` on the Mellanox and `clear bgp *` on the Arubas. (This may need to be done multiple times for all the peers to come up)
* When worker nodes are reinstalled, the BGP process will need to be restarted.
* If the BGP peers are still not coming up you should check the metallb.yaml config file for errors. The MetalLB config file should point to the NMN IP addresses of the switches configured.

### metallb.yaml configuration example

The peer-address should be the IP address of the switch that you are doing BGP peering with.
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    peers:
    - peer-address: 10.252.0.2
      peer-asn: 65533
      my-asn: 65533
    - peer-address: 10.252.0.3
      peer-asn: 65533
      my-asn: 65533
    address-pools:
    - name: customer-access
      protocol: bgp
      addresses:
      - 10.102.9.112/28
    - name: customer-access-dynamic
      protocol: bgp
      addresses:
      - 10.102.9.128/25
    - name: hardware-management
      protocol: bgp
      addresses:
      - 10.94.100.0/24
    - name: node-management
      protocol: bgp
      addresses:
      - 10.92.100.0/24
```

