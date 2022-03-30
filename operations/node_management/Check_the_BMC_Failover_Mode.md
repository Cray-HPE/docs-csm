# Check the BMC Failover Mode

Gigabyte BMCs must have their failover mode disabled to prevent incorrect network assignment.

If Gigabyte BMC failover mode is not disabled, some BMCs may receive incorrect IP addresses. Specifically, a BMC may request an IP address on the wrong subnet and be unable to re-acquire a new IP address on the correct subnet. If this occurs, administrators should ensure that the impacted BMC has its failover feature disabled.

### Procedure

1.  Check the failover setting on a Gigabyte BMC.

    For example:

    ```bash
    ncn-m001# export USERNAME=root
    ncn-m001# export IPMI_PASSWORD=changeme
    ncn-m001# ipmitool -I lanplus -U $USERNAME -E -H 172.30.52.247 raw 0x0c 0x02 0x01 210 0 0
    11 00 00
    ```

    The output can be interpreted as follows:

    -   `11 00 01` - failover mode is enabled.
    -   `11 00 00` – failover mode is disabled \(this is the desired state\).
    Please note that if a Gigabyte BMC is reset to defaults for any reason, or upgraded, the failover mode will need to be disabled again to switch the BMC to manual mode as the default setting is for failover mode to be enabled.

