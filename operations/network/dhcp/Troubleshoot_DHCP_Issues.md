## Troubleshoot DHCP Issues

There are several things to check for when troubleshooting issues with Dynamic Host Configuration Protocol \(DHCP\) servers.

### Incorrect DHCP IP Addresses

One of the most common issues is when the DHCP IP addresses are not matching in the Domain Name Service \(DNS\).

Check to make sure `cray-dhcp` is not running in Kubernetes:

```bash
ncn-w001# kubectl get pods -A | grep cray-dhcp
```

Example output:

```
services  cray-dhcp-5f8c8767db-hg6ch       1/1     Running   0          35d
```

If the `cray-dhcp` pod is running, use the following command to shut down the pod:

```bash
ncn-w001# kubectl scale deploy cray-dhcp --replicas=0
```

If the IP addresses are still not lining up with DNS and `cray-dhcp` is confirmed not running, wait 800 seconds for DHCP leases to expire and renew.

### Verify the Status of the `cray-dhcp-kea` Pods and Services

Check to see if the Kea DHCP services are running:

```bash
ncn-w001# kubectl get services -n services | grep kea
```

Example output:

```
cray-dhcp-kea-api              ClusterIP     10.26.142.204  <none>         8000/TCP      5d23h
cray-dhcp-kea-postgres         ClusterIP     10.19.97.142   <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-0       ClusterIP     10.30.214.27   <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-1       ClusterIP     10.27.232.156  <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-2       ClusterIP     10.22.242.251  <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-config  ClusterIP     None           <none>         <none>        5d23h
cray-dhcp-kea-postgres-repl    ClusterIP     10.17.107.16   <none>         5432/TCP      5d23h
cray-dhcp-kea-tcp-hmn          LoadBalancer  10.24.79.120   10.94.100.222  67:32120/TCP  5d23h
cray-dhcp-kea-tcp-nmn          LoadBalancer  10.19.139.179  10.92.100.222  67:31652/TCP  5d23h
cray-dhcp-kea-udp-hmn          LoadBalancer  10.25.203.31   10.94.100.222  67:30840/UDP  5d23h
cray-dhcp-kea-udp-nmn          LoadBalancer  10.19.187.168  10.92.100.222  67:31904/UDP  5d23h
```

If the services shown in the output above are not present, it could be an indication that something is not working correctly. To check to see if the Kea pods are running:

```bash
ncn-w001# kubectl get pods -n services -o wide | grep kea
```

Example output:

```
cray-dhcp-kea-788b4c899b-x6ltd 3/3 Running 0 36h 10.40.3.183 ncn-w002 <none> <none>
cray-dhcp-kea-postgres-0 2/2 Running 0 5d23h 10.40.3.121 ncn-w002 <none> <none>
cray-dhcp-kea-postgres-1 2/2 Running 0 5d23h 10.42.2.181 ncn-w003 <none> <none>
cray-dhcp-kea-postgres-2 2/2 Running 0 5d23h 10.39.0.208 ncn-w001 <none> <none>
```

The pods should be in a `Running` state. The output above will also indicate which worker node the `kea-dhcp` pod is currently running on.

To restart the pods:

```bash
ncn-w001# kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
```

Use the command mentioned above to verify the pods are running again after restarting the pods.

### Check the Current DHCP Leases

Use the Kea API to retrieve data from the DHCP lease database. An authentication token will be needed to access the Kea API. To retrieve a token, run the following command from an NCN worker or manager:

```bash
ncn-w001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
-d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
-o jsonpath='{.data.client-secret}' | base64 -d` \
https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
| jq -r '.access_token')
```

Once a token has been generated, the DHCP lease database can be viewed. The commands below are the most effective way to check the current DHCP leases:

-   View all leases:

    ```bash
    ncn-w001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq
    ```

-   View the total amount of leases:

    ```bash
    ncn-w001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].text'
    ```

-   Use an IP address to search for a hostname or MAC address:

    ```bash
    ncn-w001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get", "service": [ "dhcp4" ], "arguments": { "ip-address": "x.x.x.x" } }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq
    ```

-   Use a MAC address to find a hostname or IP address:

    ```bash
    ncn-w001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | \
    select(."hw-address"=="XX:XX:XX:XX:XX:5d")'
    ```

-   Use a hostname to find a MAC address or IP address:

    ```bash
    ncn-w001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
    -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' \
    https://api-gw-service-nmn.local/apis/dhcp-kea | jq '.[].arguments.leases[] | \
    select(."hostname"=="xNAME")'
    ```


### Check the Hardware State Manager \(HSM\) for Issues

The HSM includes two important components:

- Systems Layout Service \(SLS\): This is the expected state of the system, as populated by the networks.yaml and other sources.
- State Manager Daemon \(SMD\): This is the discovered or active state of the system during runtime.

To view the information stored in SLS for a specific component name (xname):

```bash
ncn-w001# cray sls hardware describe XNAME
```

To view the information in SMD:

```bash
ncn-w001# cray hsm inventory ethernetInterfaces describe XNAME
```

### View the `cray-dhcp-kea` Logs

The specific pod name is needed in order to check the logs for a pod. Run the command below to see the pod name:

```bash
ncn-w001# kubectl logs -n services -l \
app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
```

Example output:

```
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

To view the Kea logs:

```bash
ncn-w001# kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea \
-c cray-dhcp-kea | grep -i error
```

## TCPDUMP

If a host is not getting an IP address, run a packet capture to see if DHCP traffic is being transmitted.

```bash
ncn-w001# tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

This will make a .pcap file named dhcp in the current directory. It will collect all DHCP traffic on the specified port. In this example. it would be the DHCP traffic on interface bond0.nmn0 \(10.252.0.0/17\).

To view the DHCP traffic:

```bash
ncn-w001# tcpdump -r dhcp.pcap -v -n
```

The output may be very long, so use any desired filters to narrow the results.

To do a tcpdump for a certain MAC address:

```bash
ncn-w001# tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

This example is using the MAC of b4:2e:99:3b:70:30. It will show the output on the terminal and will not save to a file.

### Verify that MetalLB/BGP Peering and Routes are Correct

Log in to the spine switches and check that MetalLB is peering to the spines via BGP.

Check both spines if they are available and powered up. All worker nodes should be peered with the spine BGP.

```bash
sw-spine-001 [standalone: master] # show ip bgp neighbors
```

Example output:

```
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

Confirm that routes to Kea \(10.92.100.222\) via all the NCN worker nodes are available:

```bash
sw-spine-001 [standalone: master] # show ip route 10.92.100.222
```

Example output:

```
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


