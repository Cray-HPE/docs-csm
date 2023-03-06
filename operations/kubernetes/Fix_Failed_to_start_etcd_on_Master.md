# Fix `Failed to start etcd` on Master NCN

When deploying the final NCN, at times etcd may fail to rejoin the etcd cluster.

This procedure provides steps to recover from this issue.

## Prerequisites

- This procedure requires root privileges.
- The etcd cluster on master NCNs has two healthy members.

## Procedure

1. Identify unhealthy member.

    Run `etcdctl member list` on each master node.

    ```bash
    etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt member list
    ```

    Example output from healthy master node (assuming run from `ncn-m002`):

    ```text
    60a0d077eb0db20f, started, ncn-m001, https://10.252.1.4:2380, https://10.252.1.4:2379,https://127.0.0.1:2379, false
    b0dd65d7036d6932, started, ncn-m003, https://10.252.1.6:2380, https://10.252.1.6:2379,https://127.0.0.1:2379, false
    c0d7b0944e709721, started, ncn-m002, https://10.252.1.5:2380, https://10.252.1.5:2379,https://127.0.0.1:2379, false
    ```

    Example output from ***unhealthy*** master node (assuming run from `ncn-m001`):

    ```text
    {"level":"warn","ts":"2023-03-06T17:44:25.725Z","logger":"etcd-client","caller":"v3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00022e000/#initially=[https://127.0.0.1:2379]","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing dial tcp 127.0.0.1:2379: connect: connection refused\""}
    Error: context deadline exceeded
    ```

    Given the above, `ncn-m001` is unhealthy, and the remainder of these steps provide an example of how to remove and re-add `ncn-m001` back into the etcd cluster.

1. Stop etcd on the unhealthy NCN (`ncn-m001` is used as an example):

    ```bash
    systemctl stop etcd
    ```

1. Remove and re-add the unhealthy member from the cluster ***on a healthy NCN*** (`ncn-m002` in this example):

   Determine the `member id`, `name` (same as NCN name), and `peer-urls` from current member list from output above:

    ```text
    60a0d077eb0db20f, started, ncn-m001, https://10.252.1.4:2380, https://10.252.1.4:2379,https://127.0.0.1:2379, false
    ^^^^^^^^^^^^^^^^           ^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^^^
       member id                 name          peer-urls
    ```

    Using the values above, remove and re-add the member:

    ```bash
    etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt member remove 60a0d077eb0db20f
    ```

    Example output:

    ```text
    Member 60a0d077eb0db20f removed from cluster f1c6e6ee71e931c3
    ```

    ```bash
    etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt member add ncn-m001 --peer-urls=https://10.252.1.4:2380
    ```

    Example output:

    ```text
    Member be55f20f284cbc1b added to cluster f1c6e6ee71e931c3
    
    ETCD_NAME="ncn-m001"
    ETCD_INITIAL_CLUSTER="ncn-m003=https://10.252.1.6:2380,ncn-m001=https://10.252.1.4:2380,ncn-m002=https://10.252.1.5:2380"
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.252.1.4:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"
    ```

    Member list should now show `ncn-m001` as `unstarted`:

    ```bash
    etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt member list
    ```

    Example output:

    ```text
    c0d7b0944e709721, started, ncn-m002, https://10.252.1.5:2380, https://10.252.1.5:2379,https://127.0.0.1:2379, false
    b0dd65d7036d6932, started, ncn-m003, https://10.252.1.6:2380, https://10.252.1.6:2379,https://127.0.0.1:2379, false
    be55f20f284cbc1b, unstarted, , https://10.252.1.4:2380, , false
    ```

1. Remove etcd member data on unhealthy NCN (`ncn-m001`):

    ```bash
    rm -rf /var/lib/etcd/member
    ```

1. Set the etcd service to start as `existing` (`ncn-m001`):

    ```bash
    sed -i 's/new/existing/' /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service
    systemctl daemon-reload
    ```

1. Start etcd on the unhealthy NCN (`ncn-m001`):

    ```bash
    systemctl start etcd
    ```

1. Member list on all three masters should now show `ncn-m001` back in the cluster with a new member id:

   ```bash
    etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt member list
   ```

   Example output:

   ```text
   b0dd65d7036d6932, started, ncn-m003, https://10.252.1.6:2380, https://10.252.1.6:2379,https://127.0.0.1:2379, false
   be55f20f284cbc1b, started, ncn-m001, https://10.252.1.4:2380, https://10.252.1.4:2379,https://127.0.0.1:2379, false
   c0d7b0944e709721, started, ncn-m002, https://10.252.1.5:2380, https://10.252.1.5:2379,https://127.0.0.1:2379, false
   ```

1. At this point, etcd is healthy. If the NCN has yet to join the K8S cluster, running the following script should join it now that etcd is healthy:

   ```bash
   /srv/cray/scripts/common/kubernetes-cloudinit.sh
   ```
