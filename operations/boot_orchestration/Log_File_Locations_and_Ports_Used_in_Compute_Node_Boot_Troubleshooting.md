
## Log File Locations and Ports Used in Compute Node Boot Troubleshooting

Provides port IDs and log file locations of components associated with the node boot process.

### Log File Locations

-   ConMan logs are located within the conman pod at /var/log/conman.log.
-   Use the following command to retrieve DHCP and TFTP logs:
    -   DHCP:

        ```bash
        ncn-m001# kubectl logs DHCP_pod_ID
        ```

    -   TFTP:

        ```bash
        ncn-m001# kubectl logs -n services TFTP_pod_ID
        ```


|Component|Port|
|---------|----|
|DHCP server|67|
|DHCP client|68|
|TFTP server|69|


