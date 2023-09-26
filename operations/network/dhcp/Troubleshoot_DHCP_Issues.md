# Troubleshoot DHCP Issues

There are several things to check for when troubleshooting issues with Dynamic Host Configuration Protocol \(DHCP\) servers.

## Incorrect DHCP IP addresses

One of the most common issues is when the DHCP IP addresses are not matching in the Domain Name Service \(DNS\).

(`ncn-mw#`) Check to make sure `cray-dhcp` is not running in Kubernetes:

```bash
kubectl get pods -A | grep cray-dhcp
```

Example output:

```text
services  cray-dhcp-5f8c8767db-hg6ch       1/1     Running   0          35d
```

(`ncn-mw#`) If the `cray-dhcp` pod is running, use the following command to shut down the pod:

```bash
kubectl scale deploy cray-dhcp --replicas=0
```

If the IP addresses are still not lining up with DNS and `cray-dhcp` is confirmed not running, then wait 800 seconds for DHCP leases to expire and renew.

## Verify the status of the `cray-dhcp-kea` pods and services

(`ncn-mw#`) Check to see if the Kea DHCP services are running:

```bash
kubectl get services -n services | grep kea
```

Example output:

```text
cray-dhcp-kea-api              ClusterIP     10.26.142.204  <none>         8000/TCP      5d23h
cray-dhcp-kea-postgres         ClusterIP     10.19.97.142   <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-0       ClusterIP     10.30.214.27   <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-1       ClusterIP     10.27.232.156  <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-2       ClusterIP     10.22.242.251  <none>         5432/TCP      5d23h
cray-dhcp-kea-postgres-config  ClusterIP     None           <none>         <none>        5d23h
cray-dhcp-kea-postgres-repl    ClusterIP     10.17.107.16   <none>         5432/TCP      5d23
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
cray-dhcp-kea-7d4c5c9fb5-hs5gg      3/3 Running   0 33m   10.33.0.22   ncn-w011 <none> <none>
cray-dhcp-kea-7d4c5c9fb5-qtwtn      3/3 Running   0 33m   10.39.0.47   ncn-w006 <none> <none>
cray-dhcp-kea-7d4c5c9fb5-t4mkw      3/3 Running   0 24h   10.40.0.13   ncn-w005 <none> <none>
cray-dhcp-kea-helper-28256892-bl64f 0/2 Completed 0 29m   10.39.0.48   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256895-6t674 0/2 Completed 0 26m   10.39.0.53   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256898-8xzl2 0/2 Completed 0 23m   10.39.0.32   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256901-4wzql 0/2 Completed 0 20m   10.39.0.41   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256904-9h7hw 0/2 Completed 0 17m   10.39.0.48   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256907-zstfk 0/2 Completed 0 14m   10.39.0.44   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256910-566dd 0/2 Completed 0 11m   10.39.0.53   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256913-n2q2x 0/2 Completed 0 8m19s 10.39.0.48   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256916-j5w2n 0/2 Completed 0 5m19s 10.39.0.32   ncn-w006 <none> <none>
cray-dhcp-kea-helper-28256919-xnhnw 0/2 Completed 0 2m19s 10.39.0.32   ncn-w006 <none> <none>
cray-dhcp-kea-init-24-nbhng         0/2 Completed 0 8d    10.32.0.52   ncn-w001 <none> <none>
cray-dhcp-kea-postgres-0            3/3 Running   0 24h   10.39.0.28   ncn-w006 <none> <none>
cray-dhcp-kea-postgres-1            3/3 Running   0 24h   10.34.128.12 ncn-w004 <none> <none>
cray-dhcp-kea-postgres-2            3/3 Running   0 24h   10.32.0.39   ncn-w001 <none> <none>
```

The pods should be in a `Running` state. The output above will also indicate which worker node the `kea-dhcp` pods are currently running on.

(`ncn-mw#`) To restart the Kea pods.

```bash
kubectl rollout restart deployment -n services cray-dhcp-kea
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
