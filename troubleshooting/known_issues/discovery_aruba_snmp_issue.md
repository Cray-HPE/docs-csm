# Air-cooled hardware is not getting properly discovered with Aruba leaf switches.

## Symptoms:
   - The System has Aruba leaf switches.
   - Air-cooled hardware is reported to not be present under State Components and Inventory Redfish Endpoints in Hardware State Manager by the `hsm_discovery_verify.sh` script.
   - BMCs have IP addresses given out by DHCP, but in DNS their xname hostname does not resolve.

## Procedure to determine if you affected by this known issue:

1. Determine the name of the last HSM discovery job that ran.
   ```bash
   ncn# HMS_DISCOVERY_POD=$(kubectl -n services get pods -l app=hms-discovery | tail -n 1 | awk '{ print $1 }')
   ncn# echo $HMS_DISCOVERY_POD
   hms-discovery-1624314420-r8c49
   ```

1. Look at the logs of the HMS discovery job to find the MAC addresses associated with instances of the `MAC address in HSM not found in any switch!` error messages. The following command will parse the logs are report these MAC addresses.
   > Each of the following MAC address does not contain a ComponentID in Hardware State Manager in the Ethernet interfaces table, which can be viewed with: `cray hsm inventory ethernetInterfaces list`.
   ```bash
   ncn# UNKNOWN_MACS=$(kubectl -n services logs $HMS_DISCOVERY_POD hms-discovery | jq 'select(.msg == "MAC address in HSM not found in any switch!").unknownComponent.ID' -r -c)
   ncn# echo "$UNKNOWN_MACS"
   b42e99dff361
   9440c9376780
   b42e99bdd255
   b42e99dfecf1
   b42e99dfebc1
   b42e99dfec49
   ```

1. Look at the logs of the HMS discovery job to find the MAC address associated with instances of the `Found MAC address in switch.` log messages. The following command will parse the logs are report these MAC addresses.
   ```bash
   ncn# FOUND_IN_SWITCH_MACS=$(kubectl -n services logs $HMS_DISCOVERY_POD hms-discovery | jq 'select(.msg == "Found MAC address in switch.").macWithoutPunctuation' -r)
   ncn# echo "$FOUND_IN_SWITCH_MACS"
   b42e99bdd255
   ```

1. Perform a `diff` between the 2 sets of collected MAC addresses to see if the Aruba leaf switches in the system are affected by a known SNMP issues with Aruba switches.
   ```bash
   ncn# diff -y <(echo "$UNKNOWN_MACS" | sort -u) <(echo "$FOUND_IN_SWITCH_MACS" | sort -u)
   9440c9376780                                                  <
   b42e99bdd255                                                    b42e99bdd255
   b42e99dfebc1                                                  <
   b42e99dfec49                                                  <
   b42e99dfecf1                                                  <
   b42e99dff361                                                  <
   ```

   If there are any MAC addresses on the left column that are not on the right column, then it is likely the leaf switches in the system are being affected by the SNMP issue. Apply the workaround described in [the following procedure](../../install/aruba_snmp_known_issue_10_06_0010.md) to the Aruba leaf switches in the system.

   If all of the MAC addresses on the left column are present in the right column, then you are not affected by this known issue.