# Check the BMC Failover Mode

Gigabyte BMCs must have their failover mode disabled to prevent incorrect network assignment.

If Gigabyte BMC failover mode is not disabled, then some BMCs may receive incorrect IP addresses. Specifically, a BMC may request an IP address on the wrong subnet and be unable
to re-acquire a new IP address on the correct subnet. If this occurs, administrators should ensure that the impacted BMC has its failover feature disabled.

(`ncn#`) Check the failover setting on a Gigabyte BMC.

> `read -s` is used to prevent the password from being written to the screen or the shell history.

```bash
USERNAME=root
read -r -s -p "BMC ${USERNAME} password: " IPMI_PASSWORD
export IPMI_PASSWORD
ipmitool -I lanplus -U "${USERNAME}" -E -H BMC_HOSTNAME_OR_IP raw 0x0c 0x02 0x01 210 0 0
```

Example output:

```text
11 00 00
```

The output can be interpreted as follows:

- `11 00 01` - failover mode is enabled.
- `11 00 00` – failover mode is disabled \(this is the desired state\).

> Note: On Gigabyte BMCs, the default setting is for failover mode to be enabled. Therefore, if a Gigabyte BMC is reset to defaults for any reason, or upgraded, then failover
> mode must be disabled again in order to switch the BMC to manual mode.
