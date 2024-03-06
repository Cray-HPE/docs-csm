# Troubleshoot DHCP Issues

There are several things to check for when troubleshooting issues with Dynamic Host Configuration Protocol \(DHCP\) servers.

## Verify the status of the `cray-dhcp-kea` pods and services

(`ncn-mw#`) Check to see if the Kea DHCP services are running:

```bash
kubectl get services -n services | grep kea
```

Example output:

```text
cray-dhcp-kea-api              ClusterIP     10.26.142.204  <none>         8000/TCP      5d23h
cray-dhcp-kea-tcp-hmn          LoadBalancer  10.24.79.120   10.94.100.222  67:32120/TCP  5d23h
cray-dhcp-kea-tcp-nmn          LoadBalancer  10.19.139.179  10.92.100.222  67:31652/TCP  5d23h
cray-dhcp-kea-udp-hmn          LoadBalancer  10.25.203.31   10.94.100.222  67:30840/UDP  5d23h
cray-dhcp-kea-udp-nmn          LoadBalancer  10.19.187.168  10.92.100.222  67:31904/UDP  5d23h
```

If the services shown in the output above are not present, then it could be an indication that something is not working correctly.

(`ncn-mw#`) To check to see if the Kea pods are running:

```bash
kubectl get pods -n services -o wide | grep kea
```

Example output:

```text
cray-dhcp-kea-788b4c899b-x6ltd 3/3 Running 0 36h 10.40.3.183 ncn-w002 <none> <none>
```

The pods should be in a `Running` state. The output above will also indicate which worker node the `kea-dhcp` pod is currently running on.

(`ncn-mw#`) To restart the pods:

```bash
kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
```

Use the command mentioned above to verify the pods are running again after restarting the pods.

## Check the current DHCP leases

Use the Kea API to retrieve data from the DHCP lease database. An authentication token will be needed to access the Kea API.

(`ncn#`) To retrieve a token:

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                 https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
               | jq -r '.access_token')
```

Once a token has been generated, the DHCP lease database can be viewed. The commands below are the most effective way to check the current DHCP leases:

- (`ncn#`) View all leases:

  ```bash
  curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq
  ```

- (`ncn#`) View the total number of leases:

  ```bash
  curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].text'
  ```

- (`ncn#`) Use an IP address to search for a hostname or MAC address:

  ```bash
  curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "x.x.x.x" } }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq
  ```

- (`ncn#`) Use a MAC address to find a hostname or IP address:

  ```bash
  curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | \
    select(."hw-address"=="XX:XX:XX:XX:XX:5d")'
  ```

- (`ncn#`) Use a hostname to find a MAC address or IP address:

  ```bash
  curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | \
    select(."hostname"=="xNAME")'
  ```

## Check the Hardware State Manager \(HSM\) for issues

The HSM includes two important components:

- Systems Layout Service \(SLS\): This is the expected state of the system.
- State Manager Daemon \(SMD\): This is the discovered or active state of the system during runtime.

(`ncn-mw#`) To view the information stored in SLS for a specific component name (xname):

```bash
cray sls hardware describe XNAME
```

(`ncn-mw#`) To view the information in SMD:

```bash
cray hsm inventory ethernetInterfaces describe XNAME
```

## View the `cray-dhcp-kea` logs

(`ncn-mw#`) To view the Kea logs:

```bash
kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
```

Example output:

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

## `tcpdump`

(`ncn#`) If a host is not getting an IP address, then run a packet capture to see if DHCP traffic is being transmitted.

```bash
tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

This will create a file named `dhcp.pcap` in the current directory. It will collect all DHCP traffic on the specified port. In this example. it would be the DHCP traffic on interface `bond0.nmn0` \(`10.252.0.0/17`\).

(`ncn#`) To view the DHCP traffic:

```bash
tcpdump -r dhcp.pcap -v -n
```

The output may be very long, so use any desired filters to narrow the results.

(`ncn#`) To do a `tcpdump` for a certain MAC address:

```bash
tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

This example is using the MAC of `b4:2e:99:3b:70:30`. It will show the output on the terminal and will not save to a file.

## Verify that MetalLB/BGP peering and routes are correct

Log in to the spine switches and check that MetalLB is peering to the spines via BGP.

(`sw-spine#`) Check both spines if they are available and powered up. All worker nodes should be peered with the spine BGP.

```text
show ip bgp neighbors
```

Example output:

```text
BGP neighbor: 10.252.0.4, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w001
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90BGP neighbor: 10.252.0.5, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w002
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90BGP neighbor: 10.252.0.6, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w003
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90
```

(`sw-spine#`) Confirm that routes to Kea \(`10.92.100.222`\) via all the NCN worker nodes are available:

```text
show ip route 10.92.100.222
```

Example output:

```text
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
