# Air cooled hardware is not getting properly discovered with Aruba leaf switches.

## Symptoms:
   - The System has Aruba leaf switches.
   - Air cooled hardware is reported to not be present under State Components and Inventory Redfish Endpoints in Hardware State Manager by the hsm_discovery_verify.sh script.
   - BMCs have IP addresses given out by DHCP, but in DNS their xname hostname does not resolve.

## Procedure to determine if you affected by this known issue

Run the `arubafix.sh` script. Executed with no arguments, this script will
see if this problem currently exists on the system, and if so, fix it.

**NOTE: This script requires the admin to enter the Aruba switch management interface's admin password.**  This script is thus not completely automatic.

```
Usage: arubafix.sh [-h] [-d] [-t]

   -h    Help text
   -d    Print debug info during execution.
   -t    Test mode, don't touch Aruba switches.
```

#### Multiple Runs Are Potentially Needed

This script needs to be run twice if the first run finds issues; if it finds no issues, one run is sufficient.  

The first run is to check for the issue and fix issues it finds; the second run is to verify that the issue is fixed.

If two runs are needed, sufficient time needs to be allowed between runs for an HSM discovery job to run. This job runs every five minutes; thus the admin should wait at least 6 minutes to be sure the discovery job has run before running a second execution.

Example:

```
ncn# /opt/cray/csm/scripts/hms_verification/arubafix.sh

 
==> Getting Aruba leaf switch info from SLS...
 
==> Fetching switch hostnames...
==> Looking for completed HMS discovery pod...
 
==> Looking for undiscovered MAC addrs in discovery log...
 
Found unknown/undiscovered MACs in discovery log.
 
==> Looking for unknown/undiscovered MAC addrs in discovery log...
 
==> Identifying undiscovered MAC mismatches...
 
============================================
= Aruba undiscovered MAC mismatches found! =
= Performing switch SNMP resets.           =
============================================
 
==> Applying SNMP reset to Aruba switches...
 
 ==> PASSWORD REQUIRED for Aruba access. Enter Password:  

Performing SNMP Reset on Aruba leaf switch: sw-leaf-001
 
Aruba switch sw-leaf-001 SNMP reset succeeded.

ncn#
```

Since the previous run in this example found issues and fixed them, wait at least 6 minutes and run again to verify the fixes corrected the issue.

```
ncn# /opt/cray/csm/scripts/hms_verification/arubafix.sh

==> Getting Aruba leaf switch info from SLS...
 
==> Fetching switch hostnames...
==> Looking for completed HMS discovery pod...
 
==> Looking for undiscovered MAC addrs in discovery log...
 
Found unknown/undiscovered MACs in discovery log.
 
==> Looking for unknown/undiscovered MAC addrs in discovery log...
 
==> Identifying undiscovered MAC mismatches...

============================
= No Aruba MAC mismatches. =
============================

ncn#
```

The script returns 0 if all went well, non-zero if there was a problem, in which case the admin should examine the system manually.

### Debugging: If Script Fails

If the script fails and returns non-zero, there has been some sort of error in
one of its operations, in which case the script output will show the problem.

If the script appears to run but the discovery is still failing (after 
potentially two runs of the script), then either the initial indications of 
the discovery problem were mis-interpreted or the Aruba switches did not 
properly respond to the corrective action.

To test the former, re-run the script with maximum debugging output enabled:

```
ncn# /opt/cray/csm/scripts/hms_verification/arubafix.sh -d -d -d
```

If this does not show anything significant, then the switches may not be 
responding to an SNMP reset. Apply the workaround described 
in [the following procedure](../../install/configure_aruba_aggregation_switch.md) 
-- particuarly the "Configure SNMP" section -- to the Aruba leaf switches in the system.

