# Runbook - DHCP Troubleshooting

## 1. Confirm The Status Of The `cray-dhcp-kea`

Check if the `kea` DHCP services are running.

Create API access token for the for system:

   ```bash
   export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

### 1.1 Check `cray-dchp-kea` Pods

On any worker/manager run:

   ```bash
   kubectl get pods -n services -o wide | grep kea
   ```

You should get a list of the following pods as output:

   ```bash
   kubectl get pods -n services -o wide | grep kea
   ```

   Potential output:

   ```text
   cray-dhcp-kea-6f7ddf65dc-kckq6                                    3/3     Running            0          45h     10.37.0.47     ncn-w001   <none>           <none>
   ```

- Make sure pods listed are in `Running` state
- If `cray-dhcp-kea` pod is not in `Running` state.  Proceed to do Kubernetes troubleshooting.

This output will also show which worker node the `cray-kea-dhcp` pod is currently on.

### 1.2 Check `cray-dhcp-kea` Service Endpoints

On any worker/manager run:

   ```bash
   kubectl get services -n services | grep kea
   ```

You should see the following services as output:

   ```bash
   kubectl get services -n services | grep kea
   ```

   ```text
   cray-dhcp-kea-api                             ClusterIP      10.31.247.201   <none>          8000/TCP                     3h36m
   cray-dhcp-kea-tcp-hmn                         LoadBalancer   10.25.109.178   10.94.100.222   67:30833/TCP                 3h36m
   cray-dhcp-kea-tcp-nmn                         LoadBalancer   10.21.240.208   10.92.100.222   67:31915/TCP                 3h36m
   cray-dhcp-kea-udp-hmn                         LoadBalancer   10.20.37.60     10.94.100.222   67:30357/UDP                 3h36m
   cray-dhcp-kea-udp-nmn                         LoadBalancer   10.24.246.19    10.92.100.222   67:32188/UDP                 3h36m
   ```

- Verify all `cray-dhcp-kea` services have no `Pending` status
- If `cray-dhcp-kea` services is showing `Pending` state.  Proceed to do Kubernetes troubleshooting.

### 1.3 Check `cray-dhcp-kea` Generated Configuration Is Valid

Check to make sure `cray-dhcp-kea` is running with a valid configuration by initiated a warm configuration-reload on `cray-dhcp-kea`.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-reload",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
   ```

The expected output is:

   ```json
   [
     {
       "result": 0,
       "text": "Configuration successful."
     }
   ]
   ```

- There is a configuration data issue if you do not see the output above.

### 1.4 Review `cray-dhcp-kea` Running Configuration

Confirm configuration being used is not the base configuration.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-get",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq 
   ```

If you see similar output where there are no system specific data like 'MACs', `IPs` or `Subnets`:

   ```json
   {
     "Dhcp4": {
       "decline-probation-period": 3,
       "sanity-checks": {
               "lease-checks": "fix-del"
       },
       "expired-leases-processing": {
               "reclaim-timer-wait-time": 6000,
               "hold-reclaimed-time": 86400,
               "flush-reclaimed-timer-wait-time": 100
       },
       "control-socket": {
         "socket-name": "/cray-dhcp-kea-socket/cray-dhcp-kea.socket",
         "socket-type": "unix"
       },
       "hooks-libraries": [
         {
           "library": "/usr/local/lib/kea/hooks/libdhcp_lease_cmds.so"
         },
         {
           "library": "/usr/local/lib/kea/hooks/libdhcp_stat_cmds.so"
         }
       ],
       "interfaces-config": {
         "dhcp-socket-type": "udp",
         "interfaces": [
           "eth0"
         ]
       },
       "lease-database": {},
       "host-reservation-identifiers": [
         "hw-address"
       ],
       "reservation-mode": "global",
       "reservations": [],
       "subnet4": [],
       "valid-lifetime": 3600,
       "match-client-id": false,
       "loggers": [
         {
           "name": "cray-dchp-kea-dhcp4",
           "output_options": [
             {
               "output": "stdout"
             }
           ],
           "severity": "WARN"
         }
       ]
     }
   }
   ```

- `cray-dhcp-kea` using the base configuration indicates issues generating the configuration data from `cray-smd`, `cray-sls` and `cray-bss`. Verify those services are healthy.

### 1.5 Verify `cray-dhcp-kea` has active DHCP Leases

Verify `cray-dhcp-kea` is managing DHCP leases.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq .[].text
   ```

Expected output will be similar to:

   ```text
   "118 IPv4 lease(s) found."
   ```

- The expectation is to have more than 0 `IPv4 lease(s) Found`.
- If you see `"0 IPv4 lease(s) found."`, that indicates base configuration is being loaded or a network issue.

### 1.6 Check `dhcp-helper.py` output

```bash
kubectl exec -n services $(kubectl get pods -A|grep kea| awk '{ print $2 }') -c cray-dhcp-kea -- /srv/kea/dhcp-helper.py
```

If there are no error, `dhcp-helper.py` will not return any messages or logs.

- If there is output from running the above command. The out will confirm and describe the data issue(s).

### 1.7 Check `cray-dhcp-kea` logs

In order to check the logs for the pod you'll need to know the pod name, run this command to see the pod name.

```bash
kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
```

Example:

   ```bash
   kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
   ```

   Potential output:

   ```text
   2020-08-03 21:47:50.580 INFO  [kea-dhcp4.dhcpsrv/10] DHCPSRV_MEMFILE_LEASE_FILE_LOAD loading leases from file /cray-dhcp-kea-socket/dhcp4.leases
   2020-08-03 21:47:50.580 INFO  [kea-dhcp4.dhcpsrv/10] DHCPSRV_MEMFILE_LFC_SETUP setting up the Lease File Cleanup interval to 3600 sec
   2020-08-03 21:47:50.580 WARN  [kea-dhcp4.dhcpsrv/10] DHCPSRV_OPEN_SOCKET_FAIL failed to open socket: the interface eth0 has no usable IPv4 addresses configured
   2020-08-03 21:47:50.580 WARN  [kea-dhcp4.dhcpsrv/10] DHCPSRV_NO_SOCKETS_OPEN no interface configured to listen to DHCP traffic
   2020-08-03 21:48:00.602 INFO  [kea-dhcp4.commands/10] COMMAND_RECEIVED Received command 'lease4-get-all'
   {"Dhcp4": {"control-socket": {"socket-name": "/cray-dhcp-kea-socket/cray-dhcp-kea.socket", "socket-type": "unix"}, "hooks-libraries": [{"library": "/usr/local/lib/kea/hooks/libdhcp_lease_cmds.so"},
   ...SNIP...
   waiting 10 seconds for any leases to be given out...
   [{'arguments': {'leases': []}, 'result': 3, 'text': '0 IPv4 lease(s) found.'}]
   2020-08-03 21:48:22.734 INFO  [kea-dhcp4.commands/10] COMMAND_RECEIVED Received command 'config-get'
   ```

This command will output `kea` logs, if there are any errors see Is there an Error.

   ```bash
   kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea | grep -i error
   ```

## 2 Troubleshooting DHCP For A Specific Node

### 2.1 Check Current DHCP leases

We'll use the Kea API to retrieve data from the DHCP lease database.

1. First you need to get the authentication token, On any worker/manager, run:

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

1. Once you generate the authentication token you can run these commands on a a worker or manager node.
   If you want to retrieve all the Leases, (warning this may cause your terminal to crash based on the size of the output.)

Get all leases:

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

If you have the IP and are looking for the hostname/MAC address.

IP Lookup

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "$IP" } }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

If you have the MAC and are looking for the hostname/IP Address.

MAC lookup

   ```curl
   curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hw-address"=="$MAC")'
   ```

If you have the hostname and are looking for the MAC/IP address.
Hostname can be either xname or alias depending on the type of hardware.

Hostname lookup

   ```curl
   curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | select(."hostname"=="$HOSTNAME")'
   ```

### 2.2 Check HSM

Hardware State Manager has two important parts:

- SLS Systems Layout Service: This is the "expected" state of the system (as populated by `networks.yaml` and other sources).
- SMD State Manager Daemon: This is the "discovered" or active state of the system during runtime.

SLS

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v2/hardware | jq | less
   ```

   The output from SLS should look like this.

   ```json
   {
     "Parent": "x1000c7s1b0",
     "Xname": "x1000c7s1b0n0",
     "Type": "comptype_node",
     "Class": "Mountain",
     "TypeString": "Node",
     "ExtraProperties": {
       "Aliases": [
         "nid001228"
       ],
       "NID": 1228,
       "Role": "Compute"
     }
   }
   ```

SMD

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces | jq 
   ```

If you know the `MAC` address you are looking for:

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/$MAC | jq 
   ```

If you know the `XNAME/ComponentID` address you are looking for:

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?ComponentID=$XNAME | jq 
   ```

If you know the `IP` address you are looking for:

   ```curl
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?IPAddress=$IP | jq 
   ```

Your output from SMD should look like this.

   ```json
   {
     "ID": "0040a6838b0e",
     "Description": "",
     "MACAddress": "0040a6838b0e",
     "IPAddresses": [{"IPAddress":"10.100.1.147"}],
     "LastUpdate": "2020-07-24T23:44:24.578476Z",
     "ComponentID": "x1000c7s1b0n0",
     "Type": "Node"
   }
   ```

### 2.3 Duplicate IP

A sign of a duplicate IP is seeing a DECLINE message from the client to the server.

   ```text
   10.40.0.0.337 > 10.42.0.58.67: BOOTP/DHCP, Request from b4:2e:99:be:1a:d3, length 301, hops 1, xid 0x9d1210d, Flags [none]
        Gateway-IP 10.252.0.2
        Client-Ethernet-Address b4:2e:99:be:1a:d3
        Vendor-rfc1048 Extensions
          Magic Cookie 0x63825363
          DHCP-Message Option 53, length 1: Decline
          Client-ID Option 61, length 19: hardware-type 255, 99:be:1a:d3:00:01:00:01:26:c8:55:c3:b4:2e:99:be:1a:d3
          Server-ID Option 54, length 4: 10.42.0.58
          Requested-IP Option 50, length 4: 10.252.0.26
          Agent-Information Option 82, length 22: 
            Circuit-ID SubOption 1, length 20: vlan2-ethernet1/1/12
   ```

To test for Duplicate IPs you can ping the suspected address while you turn off the node, if you continue to get responses, then you have a dupe IP.

### 2.4 Seeing Large Number of DHCP Declines On A Node Boot

- If you are seeing something like:

   ```text
   IPv6: ADDRCONF(NETDEV_CHANGE): eth0: link becomes ready
   dracut-initqueue[1902]: wicked: eth0: Request to acquire DHCPv4 lease with UUID 13b0675f-12cb-0a00-2f0a-000001000000
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.51
   random: fast init done
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.53
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.54
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.55
   random: crng init done
   random: 7 urandom warning(s) missed due to ratelimiting
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.56
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.57
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.58
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.59
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.60
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.51
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.53
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.54
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.61
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.62
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.63
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.64
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.65
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.66
   dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.67
   ```

- This indicates an issue with an IP being allocated is already being used and not able to get the IP assigned to the device as previously set.

    Check for the that is supposed to be set for node:

    Examples:

  - Check by MAC(no colons):

    ```curl
    curl -f -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/18c04d13d73c
    ```

  - Check by Xname:

    ```curl
    curl -f -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?ComponentID=x3000c0s25b0n0
    ```

   Output should look similar to:

   ```json
   {
     "ID": "18c04d13d73c",
     "Description": "Ethernet Interface Lan1",
     "MACAddress": "18:c0:4d:13:d7:3c",
     "IPAddresses": [{,"IPAddress":"10.252.0.78"}],
     "LastUpdate": "2020-09-20T19:46:04.811779Z",
     "ComponentID": "x3000c0s25b0n0",
     "Type": "Node"
   }
   ```

- We use the IP from the SMD entry to check to see if something is responding to the IP with ping

   Example:

   ```bash
   # ping -c 3 10.252.0.78
   PING 10.252.0.78 (10.252.0.78) 56(84) bytes of data.
   64 bytes from 10.252.0.78: icmp_seq=1 ttl=64 time=0.102 ms
   64 bytes from 10.252.0.78: icmp_seq=2 ttl=64 time=0.229 ms
   64 bytes from 10.252.0.78: icmp_seq=3 ttl=64 time=0.096 ms
   --- 10.252.0.78 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2054ms
   rtt min/avg/max/mdev = 0.096/0.142/0.229/0.062 ms
   #
   ```

- If ping comes back with responses, that confirms a device is responding to the IP and we need to set move the DHCP reservation for the device to another IP.
- We will remove the entry from based on the MAC address(without colons) in the SMD Ethernet Table

Example:

   ```curl
   curl -f -X DELETE -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces/18c04d13d73c
   ```

- Wait 5 minutes for HMS discovery to recreate the SMD Ethernet Table entry.
- Reboot the node and let the node get an IP from DHCP
- The standard discovery/DHCP/DNS process complete in about 5 minutes
- This will get the node to boot up till DVS is needed.
- The next step is follow the DVS node map update in the section "Troubleshoot Node Map IP Change Issues" in Section 7 of "Cray Shasta DVS Administration Guide". Shasta (V1.3) Software Documentation.

## 3. Network Troubleshooting

### 3.1 Check BGP/MetalLB

Log in to the spine switches and check that MetalLB is peering to the spines via BGP.

For **Mellanox** Spine Switches

   ```bash
   show ip bgp summary
   ```

Example working state: All the neighbors should be in the Established state.

   ```bash
   show ip bgp summary 
   ```

   Potential output:

   ```text
   VRF name                  : default
   BGP router identifier     : 10.252.0.1
   local AS number           : 65533
   BGP table version         : 6
   Main routing table version: 6
   IPV4 Prefixes             : 84
   IPV6 Prefixes             : 0
   L2VPN EVPN Prefixes       : 0

   ------------------------------------------------------------------------------------------------------------------
   Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd    
   ------------------------------------------------------------------------------------------------------------------
   10.252.0.4        4    65533        465       501       6         0      0      0:03:37:43    ESTABLISHED/28
   10.252.0.5        4    65533        463       501       6         0      0      0:03:36:51    ESTABLISHED/28
   10.252.0.6        4    65533        463       500       6         0      0      0:03:36:39    ESTABLISHED/28
   ```

If the `State/pfxrcd` is `IDLE` you need to restart the BGP process with this command:

   ```bash
   clear ip bgp all
   ```

Routes to Kea (10.92.100.222) via all workers (in the above 10.252.0.4,5,6) should be available.

   ```bash
   show ip route 10.92.100.222
   ```

   Potential output:

   ```text
   Routes:All worker nodes (in the above example 3) should be peered with the spine BGP.
   Example:
   sw-spine01 [standalone: master] # show ip route 10.92.100.222
   Flags:
     F: Failed to install in H/W
     B: BFD protected (static route)
     i: BFD session initializing (static route)
     x: protecting BFD session failed (static route)
     c: consistent hashing
     p: partial programming in H/W
   VRF Name default:
     ------------------------------------------------------------------------------------------------------
     Destination       Mask              Flag     Gateway           Interface        Source     AD/M  
     ------------------------------------------------------------------------------------------------------
     default           0.0.0.0           c        10.102.255.9      eth1/16          static     1/1   
     10.92.100.222     255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0   
                                         c        10.252.0.5        vlan2            bgp        200/0   
                                         c        10.252.0.6        vlan2            bgp        200/0

   ```

For Aruba Spine Switches

   ```bash
   show bgp ipv4 u s
   ```

   Potential output:

   ```text
   VRF : default
   BGP Summary
   -----------
    Local AS               : 65533        BGP Router Identifier  : 10.252.0.3
    Peers                  : 4            Log Neighbor Changes   : No
    Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
    Confederation Id       : 0
    
    Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
    10.252.0.2      65533       45052   45044   02m:02w:02d  Established   Up
    10.252.1.7      65533       78389   90090   02m:02w:02d  Established   Up
    10.252.1.8      65533       78384   90059   02m:02w:02d  Established   Up
    10.252.1.9      65533       78389   90108   02m:02w:02d  Established   Up
   ```

### 3.2 `tcpdump`

If your host is not getting an IP address you can run a packet capture to see if DHCP traffic is being transmitted.
On `ncn-w001` or a worker/manager with `kubectl`, run

   ```bash
   tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
   ```

This will make a `.pcap` file named DHCP in your current directory.  It will collect all DHCP traffic on the port you specify, in this example we are looking for DHCP traffic on interface NMN (10.252.0.0/17)

To view the DHCP traffic, run:

   ```bash
   tcpdump -r dhcp.pcap -v -n
   ```

The output may be very long, you may want to use filters.
If you want to do a `tcpdump` for a certain MAC address you can run:

   ```bash
   tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
   ```

This example is using the MAC of `b4:2e:99:3b:70:30` and will show the output on your terminal and not save to a file.

You can also run a `tcpdump` from the Dell Leaf/CDU switches.

Example of `tcpdump` for DHCP traffic on the NMN:

   ```bash
   system "sudo tcpdump -enli br2 port 67 or port 68"
   ```

Example of `tcpdump` for DHCP traffic for interface 1/1/4:

   ```bash
   system "sudo tcpdump -enli e101-004-0 port 67 or port 68"
   ```
