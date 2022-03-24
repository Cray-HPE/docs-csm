# Log File Locations and Ports Used in Compute Node Boot Troubleshooting

This section includes the port IDs and log file locations of components associated with the node boot process.

### Log File Locations

The log file locations for ConMan, DHCP, and TFTP.

- ConMan logs are located within the `conman` pod at /var/log/conman.log.
- DHCP:

    ```bash
    ncn-m001# kubectl logs DHCP_POD_ID
    ```
- TFTP:

    ```bash
    ncn-m001# kubectl logs -n services TFTP_POD_ID
    ```

### Port IDs

The following table includes the port IDs for DHCP and TFTP.

|Component|Port|
|---------|----|
|DHCP server|67|
|DHCP client|68|
|TFTP server|69|

