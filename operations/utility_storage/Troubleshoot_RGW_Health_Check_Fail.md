# Troubleshoot if RGW Health Check Fails

Use this procedure to determine why the RGW health check failed and what needs to be fixed.

## Procedure

In the goss test output, look at the value of `x` in `Expected \< int \>: x` (possible values are 1, 2, 3, 4, 5). Based on the value, navigate to the corresponding numbered item below for troubleshooting this issue.

(Optional) Manually run the rgw health check script to see descriptive output.

```bash
GOSS_BASE=/opt/cray/tests/install/ncn /opt/cray/tests/install/ncn/scripts/rgw_health_check.sh
```

1. A value of `1` is returned if unable to connect to `rgw-vip`. This happens if any of the following three commands fail.

    ```bash
    curl -i -s -S -k https://rgw-vip.nmn
    curl -i -s -S http://rgw-vip.nmn
    curl -i -s -S http://rgw-vip.hmn
    ```
    Log into a storage node and look at the version and status of Ceph.
    ```bash
    ceph --version
    ceph -s
    ```

1. A value of `2` is returned if a storage node is not able to be reached. In this case, run the `rgw_health_check.sh` as stated in the optional step above. Find which storage nodes are not able to be reached, and run the following checks on those nodes.

    - Check if `HAProxy` is running on the node.

        ```bash
        systemctl status haproxy
        ```
        If `HAProxy` is not running, restart it and check the status again.
        ```bash
        systemctl restart haproxy
        systemctl status haproxy
        ```

    - Check if `keepalived` is running on the node.

        ```bash
        systemctl status keepalived.service
        ```
        If `keepalived` is not running, restart it and check the status again.
        ```bash
        systemctl restart keepalived.service
        systemctl status keepalived.service
        ```

    - Check if the `ceph-rgw` daemon is running.
        ```bash
        ceph -s | grep rgw
        ```
        If the `ceph-rgw` daemon is not running on 3 storage nodes, restart the daemon and watch it come up within a few seconds.

        ```bash
        ceph orch ps | grep rgw           #use this to wach the daemon start
        ceph orch daemon restart <name>
        ```

1. A value of `3` is returned if a `craysys` command fails. This implies 'cloud-init' is not healthy. Run the command below to determine the health.

    ```bash
    cloud-init query -a
    ```

    If the command above fails, reinitialize 'cloud-init' using the following command.

    ```bash
    cloud-init init
    ```

1. If a value of `4` or `5` is returned, then `rgw-vip` and the storage nodes are reachable. The error occurred when attempting to create a bucket, upload an object to a bucket, or download an object from a bucket. This implies Ceph may be unhealthy. Check Ceph status with the following command.

    ```bash
    ceph -s
    ```

    If Ceph reports any status other than "HEALTH_OK", refer to [Utility Storage](Utility_Storage.md) for general Ceph troubleshooting.

