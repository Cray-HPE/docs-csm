# Troubleshoot if RGW Health Check Fails

Use this procedure to determine why the "rgw health check" failed and what needs to be fixed.

## Procedure

In the information outputted by the goss test, look at the value of 'x' in "Expected \< int \>: x" (possible values are 1,2,3,4,5). Based on the value, navigate to corresponding numbered item below for troubleshooting this issue.

Optional: Manually run the rgw health check script to see descriptive output.

```bash
ncn-m001# GOSS_BASE=/opt/cray/tests/install/ncn /opt/cray/tests/install/ncn/scripts/rgw_health_check.sh
```


1. A value of 1 is returned if unable to connect to rgw-vip. This happens if any of the following three commands fail.

    ```bash
    ncn-m001# curl -i -s -S -k https://rgw-vip.nmn
    ncn-m001# curl -i -s -S http://rgw-vip.nmn
    ncn-m001# curl -i -s -S http://rgw-vip.hmn
    ```
    Log into a storage node ncn-s00\[123\] and look at the version and status of ceph.
    ```bash
    ncn-s001# ceph --version
    ncn-s001# ceph -s
    ```


1. A value of 2 is returned if a storage node is not able to be reached. In this case, run the "rgw_health_check.sh" as statued in the optional step above. Find which storage node(s) is not able to be reached, and run the following checks on that node.

    - Check HAProxy is running on the node.
        
        ```bash
        ncn-s001# systemctl status haproxy
        ```
        If HAProxy is not running, restart it and check the status again.
        ```bash
        ncn-s001# systemctl restart haproxy
        ncn-s001# systemctl status haproxy
        ```

    - Check keepalived is running on the node.

        ```bash
        ncn-s001# systemctl status keepalived.service
        ```
        If keepalived is not running, restart it and check the status again.
        ```bash
        ncn-s001# systemctl restart keepalived.service
        ncn-s001# systemctl status keepalived.service
        ```

    - Check ceph-rgw daemon is running.
        ```bash
        ncn-s001# ceph -s | grep rgw
        ```
        If ceph-rgw daemon is not running on 3 storage nodes, restart the deamon and watch it come up within a few seconds.

        ```bash
        ncn-s001# ceph orch ps | grep rgw           #use this to wach the daemon start
        ncn-s001# ceph orch damon restart <name>
        ```


1. A value of 3 is returned if a 'craysys' command fails. This implies 'cloud-init' is not healthy. Run the command below to determine the health.

    ```bash
    ncn-s001# cloud-init query -a
    ```

    If the command above fails, reinitialize 'cloud-init' using the following command.

    ```bash
    ncn-s001# cloud-init init
    ```


1. If a value of 4 or 5 is returned, then rgw-vip and the storage nodes are reachable. Thee error occured when attempting to create a bucket, upload an object to a bucket, or download an object from a bucket. This implies ceph may be unhealthy. Check ceph status with the following command.

    ```bash
    ncn-s001# ceph -s
    ```

    If ceph reports any status other than "HEALTH_OK", refer to [Utility Storage](Utility_Storage.md) for general ceph troubleshooting. 

1. Refer to point 4. 

