# Runbook - DHCP Troubleshooting

- [Get an API token](#get-an-api-token)
- [1 Confirm the status of the `cray-dhcp-kea` services](#1-confirm-the-status-of-the-cray-dhcp-kea-services)
   1. [Check `cray-dchp-kea` pods](#11-check-cray-dchp-kea-pods)
   1. [Check `cray-dhcp-kea` service endpoints](#12-check-cray-dhcp-kea-service-endpoints)
   1. [Verify that `cray-dhcp-kea` configuration is valid](#13-verify-that-cray-dhcp-kea-configuration-is-valid)
   1. [Review `cray-dhcp-kea` running configuration](#14-review-cray-dhcp-kea-running-configuration)
   1. [Verify that `cray-dhcp-kea` has active DHCP leases](#15-verify-that-cray-dhcp-kea-has-active-dhcp-leases)
   1. [Check `dhcp-helper.py` output](#16-check-dhcp-helperpy-output)
   1. [Check `cray-dhcp-kea` logs](#17-check-cray-dhcp-kea-logs)
- [2 Troubleshooting DHCP for a specific node](#2-troubleshooting-dhcp-for-a-specific-node)
   1. [Check current DHCP leases](#21-check-current-dhcp-leases)
   1. [Check the Hardware State Manager](#22-check-the-hardware-state-manager)
      - [System Layout Service](#system-layout-service)
      - [State Manager Daemon](#state-manager-daemon)
   1. [Duplicate IP address](#23-duplicate-ip-address)
   1. [Numerous DHCP decline messages during node boot](#24-numerous-dhcp-decline-messages-during-node-boot)
- [3 Network troubleshooting](#3-network-troubleshooting)
   1. [Check BGP/MetalLB](#31-check-bgpmetallb)
      - [Mellanox spine switches](#mellanox-spine-switches)
      - [Aruba spine switches](#aruba-spine-switches)
   1. [`tcpdump`](#32-tcpdump)
      - [Dell/Leaf CDU switches](#dellleaf-cdu-switches)

## Get an API token

(`ncn-mw#`) Some of the commands in these procedures require an API token to be acquired and stored in the `TOKEN` environment variable.

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
    -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

## 1 Confirm the status of the `cray-dhcp-kea` services

Check if the Kea DHCP services are running properly.

### 1.1 Check `cray-dchp-kea` pods

1. (`ncn-mw#`) List the `cray-dchp-kea` pods.

   ```bash
   kubectl get pods -n services -o wide | grep kea
   ```

   Expected output looks similar to the following:

   ```text
   cray-dhcp-kea-6f7ddf65dc-kckq6                                    3/3     Running            0          45h     10.37.0.47     ncn-w001   <none>           <none>
   ```

1. Verify that all pods listed are in `Running` state.

   If a `cray-dhcp-kea` pod is not in `Running` state, then perform Kubernetes troubleshooting.

   This output will also show which worker node the `cray-kea-dhcp` pod is currently on. This information may be useful when debugging a Kubernetes problem.

### 1.2 Check `cray-dhcp-kea` service endpoints

1. (`ncn-mw#`) List the `cray-dhcp-kea` service endpoints.

   ```bash
   kubectl get services -n services | grep kea
   ```

   Expected output looks similar to the following:

   ```text
   cray-dhcp-kea-api                             ClusterIP      10.31.247.201   <none>          8000/TCP                     3h36m
   cray-dhcp-kea-tcp-hmn                         LoadBalancer   10.25.109.178   10.94.100.222   67:30833/TCP                 3h36m
   cray-dhcp-kea-tcp-nmn                         LoadBalancer   10.21.240.208   10.92.100.222   67:31915/TCP                 3h36m
   cray-dhcp-kea-udp-hmn                         LoadBalancer   10.20.37.60     10.94.100.222   67:30357/UDP                 3h36m
   cray-dhcp-kea-udp-nmn                         LoadBalancer   10.24.246.19    10.92.100.222   67:32188/UDP                 3h36m
   ```

1. Verify that all `cray-dhcp-kea` services are listed as `Pending`.

   If any `cray-dhcp-kea` service is showing `Pending`, then perform Kubernetes troubleshooting.

### 1.3 Verify that `cray-dhcp-kea` configuration is valid

Check to make sure that `cray-dhcp-kea` is running with a valid configuration by initiating a warm configuration-reload on `cray-dhcp-kea`.

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Initiate the configuration reload.

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

   If the output is different from what is expected, then there is a configuration data issue.

### 1.4 Review `cray-dhcp-kea` running configuration

Verify that the configuration being used is not the base configuration.

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) View the current configuration.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-get",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq 
   ```

1. Determine whether the base configuration is in use.

   The base configuration will contain no system-specific data (such as MAC addresses, IP addresses, or subnets), similar to the following example:

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

   If `cray-dhcp-kea` is using the base configuration, then this indicates issues generating the configuration data from `cray-smd`, `cray-sls`, and `cray-bss`.
   Verify that those services are healthy.

### 1.5 Verify that `cray-dhcp-kea` has active DHCP leases

Verify that `cray-dhcp-kea` is managing DHCP leases.

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Check how many DHCP leases are found.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
      -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq .[].text
   ```

   Expected output will be similar to:

   ```text
   "118 IPv4 lease(s) found."
   ```

   If things are working normally, then the expectation is to have more than 0 leases found.
   If no leases are found, then that indicates the base configuration is being loaded or there is a network issue.

### 1.6 Check `dhcp-helper.py` output

(`ncn-mw#`) Run `dhcp-helper.py`.

```bash
kubectl exec -n services $(kubectl get pods -A|grep kea| awk '{ print $2 }') -c cray-dhcp-kea -- /srv/kea/dhcp-helper.py
```

If there are no errors, then `dhcp-helper.py` will not return any messages or logs.

If there is output from running the above command, then the output will include a description of any problems found.

### 1.7 Check `cray-dhcp-kea` logs

- (`ncn-mw#`) View the pod logs.

   ```bash
   kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
   ```

   Beginning of example output:

   ```text
   2020-08-03 21:47:50.580 INFO  [kea-dhcp4.dhcpsrv/10] DHCPSRV_MEMFILE_LEASE_FILE_LOAD loading leases from file /cray-dhcp-kea-socket/dhcp4.leases
   2020-08-03 21:47:50.580 INFO  [kea-dhcp4.dhcpsrv/10] DHCPSRV_MEMFILE_LFC_SETUP setting up the Lease File Cleanup interval to 3600 sec
   2020-08-03 21:47:50.580 WARN  [kea-dhcp4.dhcpsrv/10] DHCPSRV_OPEN_SOCKET_FAIL failed to open socket: the interface eth0 has no usable IPv4 addresses configured
   2020-08-03 21:47:50.580 WARN  [kea-dhcp4.dhcpsrv/10] DHCPSRV_NO_SOCKETS_OPEN no interface configured to listen to DHCP traffic
   2020-08-03 21:48:00.602 INFO  [kea-dhcp4.commands/10] COMMAND_RECEIVED Received command 'lease4-get-all'
   {"Dhcp4": {"control-socket": {"socket-name": "/cray-dhcp-kea-socket/cray-dhcp-kea.socket", "socket-type": "unix"}, "hooks-libraries": [{"library": "/usr/local/lib/kea/hooks/libdhcp_lease_cmds.so"},
   ```

    Tail end of example output:

   ```text
   waiting 10 seconds for any leases to be given out...
   [{'arguments': {'leases': []}, 'result': 3, 'text': '0 IPv4 lease(s) found.'}]
   2020-08-03 21:48:22.734 INFO  [kea-dhcp4.commands/10] COMMAND_RECEIVED Received command 'config-get'
   ```

- (`ncn-mw#`) Display only potential error messages in the pod logs.

   ```bash
   kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea | grep -i error
   ```

## 2 Troubleshooting DHCP for a specific node

### 2.1 Check current DHCP leases

Use the Kea API to retrieve data from the DHCP lease database.

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Run desired commands to check DHCP leases.

   - Get all leases.

      Warning: this may cause the terminal to crash, if there is too much output.

      ```bash
      curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
         -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
      ```

   - Determine the hostname or MAC address from an IP address.

      ```bash
      IP=<IP_address>
      curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
         -d "{ \"command\": \"lease4-get\", \"service\": [ \"dhcp4\" ], \"arguments\": { \"ip-address\": \"${IP}\" } }" \
         https://api-gw-service-nmn.local/apis/dhcp-kea | jq
      ```

   - Determine the hostname or IP address from the MAC address

      ```bash
      MAC=<MAC_address>
      curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
         -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | \
         jq ".[].arguments.leases[] | select(.\"hw-address\"==\"${MAC}\")"
      ```

   - Determine MAC or IP address from the hostname.

      The hostname can be either the component name (xname) or an alias, depending on the type of hardware.

      ```bash
      HNAME=<hostname>
      curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
         -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | \
         jq ".[].arguments.leases[] | select(.\"hostname\"==\"${HNAME}\")"
      ```

### 2.2 Check the Hardware State Manager

Hardware State Manager (HSM) has two important parts:

- [System Layout Service](#system-layout-service) (SLS): This is the "expected" state of the system (as populated by `networks.yaml` and other sources).
- [State Manager Daemon](#state-manager-daemon) (SMD): This is the "discovered" or active state of the system during runtime.

#### System Layout Service

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Retrieve SLS data.

   ```bash
   curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v2/hardware | jq | less
   ```

   The output from SLS should look similar to the following:

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

#### State Manager Daemon

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Query SMD.

   There are a number of options.

   - List all interfaces

      ```bash
      curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces | jq 
      ```

   - Lookup by MAC address

      The MAC address should contain no colons.

      ```bash
      MAC=<MAC address>
      curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/${MAC} | jq 
      ```

   - Lookup by xname

      ```bash
      XNAME=<xname>
      curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?ComponentID=${XNAME} | jq 
      ```

   - Lookup by IP address

      ```bash
      IP=<IP address>
      curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?IPAddress=${IP} | jq 
      ```

   Output from SMD should look similar to the following:

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

### 2.3 Duplicate IP address

A sign of a duplicate IP address is seeing a `DECLINE` message from the client to the server.

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

To test for duplicate IP addresses, ping the suspected IP address while turning off the node. If ping continues to get responses after the node is down, then there is a duplicate IP address.

### 2.4 Numerous DHCP decline messages during node boot

The symptom of this looks similar to the following on a node console during boot:

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

This indicates that an IP address being allocated is already being used. If that is the case, use the following procedure to
troubleshoot and remediate the problem.

1. [Get an API token](#get-an-api-token).

1. (`ncn-mw#`) Determine the IP address that is supposed to be set for node.

   Example commands:

   - Check by MAC address (no colons).

      ```bash
      curl -f -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/18c04d13d73c
      ```

   - Check by xname.

      ```bash
      curl -f -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?ComponentID=x3000c0s25b0n0
      ```

   Output should look similar to the following:

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

1. (`ncn-mw#`) Ping the IP address from the SMD entry to see if something is responding to it.

   Example command:

   ```bash
   ping -c 3 10.252.0.78
   ```

   Example output:

   ```text
   PING 10.252.0.78 (10.252.0.78) 56(84) bytes of data.
   64 bytes from 10.252.0.78: icmp_seq=1 ttl=64 time=0.102 ms
   64 bytes from 10.252.0.78: icmp_seq=2 ttl=64 time=0.229 ms
   64 bytes from 10.252.0.78: icmp_seq=3 ttl=64 time=0.096 ms
   --- 10.252.0.78 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2054ms
   rtt min/avg/max/mdev = 0.096/0.142/0.229/0.062 ms
   ```

   If ping receives responses, then that confirms that a device is responding to the IP address. In that case, the DHCP reservation for the device must be moved to another IP address.

1. (`ncn-mw#`) Remove the entry by its MAC address (without colons) in the SMD Ethernet table.

   Example:

    ```bash
    curl -f -X DELETE -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces/18c04d13d73c
    ```

1. Wait five minutes for HMS discovery to recreate the SMD Ethernet table entry.

1. Reboot the node and let the node get an IP address from DHCP.

   The standard discovery/DHCP/DNS process should complete in about 5 minutes.
   This will get the node to boot up until DVS is needed (if the node is using DVS).

1. If the node is using DVS, follow the DVS node map update procedure.

   See `Troubleshoot Node Map IP Change Issues` in the `Cray Shasta DVS Administration Guide`.

## 3 Network troubleshooting

### 3.1 Check BGP/MetalLB

Verify that the Metal Load Balancer (MetalLB) is peering to the spine switches via the Border Gateway Protocol (BGP). The commands in these sections must be
run on the spine switches themselves.

#### Mellanox spine switches

1. (`sw#`) Show the BGP status.

   ```text
   show ip bgp summary
   ```

   All the neighbors should be in the `ESTABLISHED` state, as seen in the following example output:

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

1. (`sw#`) If the `State/PfxRcd` is `IDLE`, then restart the BGP process.

   ```text
   clear ip bgp all
   ```

1. (`sw#`) Verify that routes to Kea via all workers are available.

   Routes to Kea (`10.92.100.222`) via all workers (in the above examples, `10.252.0.4` - `10.252.0.6`) should be available.

   ```text
   show ip route 10.92.100.222
   ```

   Example output:

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

#### Aruba spine switches

(`sw#`) Show BGP status.

```text
show bgp ipv4 u s
```

Example output:

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

If a host is not getting an IP address, then run a packet capture to see if DHCP traffic is being transmitted.

```bash
tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

This will make a `.pcap` file named DHCP in the current directory. It will collect all DHCP traffic on the specified port. In this example, it is looking for DHCP traffic on
the NMN interface (`10.252.0.0/17`).

View the DHCP traffic:

```bash
tcpdump -r dhcp.pcap -v -n
```

The output may be very long, which can be handled by using filters.
Do a `tcpdump` for a certain MAC address:

```bash
tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

This example is using the MAC address of `b4:2e:99:3b:70:30`. It will show the output on the terminal and not save to a file.

#### Dell/Leaf CDU switches

It is also possible to run `tcpdump` from the Dell Leaf/CDU switches.

- (`sw#`) Example of `tcpdump` for DHCP traffic on the NMN:

   ```text
   system "sudo tcpdump -enli br2 port 67 or port 68"
   ```

- (`sw#`) Example of `tcpdump` for DHCP traffic for interface `1/1/4`:

   ```text
   system "sudo tcpdump -enli e101-004-0 port 67 or port 68"
   ```
