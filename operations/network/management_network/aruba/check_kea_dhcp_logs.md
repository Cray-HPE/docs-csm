# Check KEA DHCP Logs

Use this procedure to check the logs for a cray-dhcp-kea pod.

## Procedure

1. Retrieve the pod name.
   
   The pod name is required to check the logs for the pod in question.

    ```
    kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea
    ```

    Example:

    ```
    ncn-w001# kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea

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

2. View the Kea logs.

    ```
    ncn-w001# kubectl logs -n services -l app.kubernetes.io/instance=cray-dhcp-kea -c cray-dhcp-kea | grep -i error
    ```

3. Shell into a Kea Pod.

    ```
    ncn-w001# kubectl exec -n services -it pod/$(kubectl get -n services pods | grep kea | head -n 1) -c cray-dhcp-kea -- /bin/bash
    ```

[Back to Index](../index_aruba.md)