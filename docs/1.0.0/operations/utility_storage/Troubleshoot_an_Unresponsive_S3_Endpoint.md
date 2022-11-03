# Troubleshoot an Unresponsive Rados-Gateway (radosgw) S3 Endpoint

## Issue 1: Rados-Gateway/s3 endpoint is not accessible

```bash
ncn# response=$(curl --write-out '%{http_code}' --silent --output /dev/null http://rgw-vip)|echo "Curl Response Code: $response"
Curl Response Code: 200
```

Expected Responses: 2xx, 3xx

### Procedure:

1. Check the individual endpoints.

   ```bash
   ncn# num_storage_nodes=$(craysys metadata get num_storage_nodes);for node_num in $(seq 1 "$num_storage_nodes"); do nodename=$(printf "ncn-s%03d" "$node_num");  response=$(curl --write-out '%{http_code}' --silent --output /dev/null http://$nodename:8080); echo "Curl Response Code for ncn-s00$endpoint: $response"; done

   Curl Response Code for ncn-s003: 200
   Curl Response Code for ncn-s003: 200
   Curl Response Code for ncn-s003: 200
   ```

   **Troubleshooting:** If an error occurs with the above script, then `echo $num_storage_nodes`. If it is not an integer that matches the known configuration of the number of Utility Storage nodes, then run `cloud-init init` to refresh the `cloud-init` cache. Alternatively, manually set that number if the number of Utility Storage nodes is known.

1. Check the `HAProxy` endpoint.

   ```bash
   ncn# response=$(curl --write-out '%{http_code}' --silent --output /dev/null http://rgw-vip)|echo "Curl Response Code: $response"

   Curl Response Code: 200
   ```

1. Verify `HAProxy` and `KeepAlived` status.

   `KeepAlived:`

   1. Check KeepAlived on each node running ceph-radosgw. By default this will be all Utility Storage nodes, but may differ based on your configuration.

   ```bash
   ncn-s# systemctl is-active keepalived.service
   active
   ```

   1. Check for the KeepAlived instance hosting the VIP (Virtual IP). This command will have to be run on each node until you find the expected output.

    ```bash
    ncn-s# journalctl -u keepalived.service --no-pager |grep -i gratuitous
    Aug 25 19:33:12 ncn-s001 Keepalived_vrrp[12439]: Registering gratuitous ARP shared channel
    Aug 25 19:43:08 ncn-s001 Keepalived_vrrp[12439]: Sending gratuitous ARP on vlan002 for 10.252.1.3
    Aug 25 19:43:08 ncn-s001 Keepalived_vrrp[12439]: (VI_0) Sending/queueing gratuitous ARPs on vlan002 for 10.252.1.3
    ```

   `HAProxy:`

   ```bash
    ncn-s# systemctl is-active haproxy.service
    active
   ```

## Issue 2: Ceph Reports `HEALTH_OK` but S3 Operations Not Functioning

Restart Ceph OSDs to help make the `rgw.local:8080` endpoint responsive.

**Ceph has an issue where it appears healthy but the `rgw.local:8080` endpoint is unresponsive.**

This issue occurs when `ceph -s` is run and produces a very high reads per second output:

```bash
io:
    client:   103 TiB/s rd, 725 KiB/s wr, 2 op/s rd, 44 op/s wr
```

The `rgw.local` endpoint needs to be responsive in order to interact directly with the Simple Storage Service \(S3\) RESTful API.

### Prerequisites

This procedure requires admin privileges.

### Procedure

1. View the OSD status.

    ```bash
    ncn-m001# ceph osd tree
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95312 root default
    -7        6.98438     host ncn-s001
     0   ssd  3.49219         osd.0         up  1.00000 1.00000
     3   ssd  3.49219         osd.3         up  1.00000 1.00000
    -3        6.98438     host ncn-s002
     2   ssd  3.49219         osd.2         up  1.00000 1.00000
     5   ssd  3.49219         osd.5         up  1.00000 1.00000
    -5        6.98438     host ncn-s003
     1   ssd  3.49219         osd.1         up  1.00000 1.00000
     4   ssd  3.49219         osd.4         up  1.00000 1.00000

    ```

1. Log in to each node and restart the OSDs.

    The OSD number in the example below should be replaced with the number of the OSD being restarted.

    ```bash
    ncn-m001# ceph orch restart osd.3
    ```

    Wait for Ceph health to return to OK before moving between nodes.
