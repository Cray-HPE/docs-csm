# SAT/HSM/CAPMC Component Power State Mismatch

Because of various hardware or communication issues, the node state reported by SAT and HSM (Hardware State Manager) may
become out of sync with the actual hardware state reported by CAPMC or Redfish. In most cases this will be noticed
when trying to power on or off nodes with BOS/BOA, and will present as SAT or HSM reporting nodes are `On` while CAPMC
reports them as `Off` (or vice versa).

## Possible Causes

Possible reasons the power state got out of sync include but are not limited to:

* A known issue with Gigabyte nodes where Redfish power events can get sent out of order when rebooting nodes.
* Network issues preventing the flow of Redfish events (telemetry will also be affected).
* Issues with the `cray-hms-hmcollector` pod.

## Fix

In most cases, once the underlying cause has been corrected, this should correct itself when the node boots OS, starts
heartbeating, and goes to the `Ready` state. If not, the power state for the affected nodes can be re-synced by kicking
off HSM re-discovery of those nodes' BMCs.

```bash
ncn# cray hsm inventory discover create --xnames <list_of_BMC_xnames>
```

For example:

```bash
ncn# cray hsm inventory discover create --xnames x3000c0s0b0,x3000c0s1b0
```

The power state will be re-synced after all of the BMCs listed have a `LastDiscoveryStatus` of `DiscoverOK`.

```bash
ncn# cray hsm inventory redfishEndpoints describe x3000c0s0b0
```

Example output:

```json
{
  "ID": "x3000c0s0b0",
  "Type": "NodeBMC",
  "Hostname": "",
  "Domain": "",
  "FQDN": "x3000c0s0b0",
  "Enabled": true,
  "UUID": "808cde6e-debf-0010-e603-b42e993b708c",
  "User": "root",
  "Password": "",
  "RediscoverOnUpdate": true,
  "DiscoveryInfo": {
    "LastDiscoveryAttempt": "2021-08-12T16:00:56.937774Z",
    "LastDiscoveryStatus": "DiscoverOK",
    "RedfishVersion": "1.7.0"
  }
}
```

Any power operations done manually with CAPMC that alter the nodes' power state may also cause the power state to re-sync.
