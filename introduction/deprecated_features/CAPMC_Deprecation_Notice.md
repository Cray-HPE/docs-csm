# CAPMC Deprecation Notice

## CAPMC enters final life cycle before removal

CSM 1.5 is the last release that will contain the CAPMC service. It has been
replaced by PCS. CAPMC continues to co-exist with PCS to assist in transition to
PCS. CAPMC is slated to be permanently removed from the system beginning with
CSM 1.6.

### Deprecated Features in CSM 1.5

CAPMC has been end-of-life since the CSM 1.3 release. The remaining APIs and CLI commands
are officially deprecated and will be removed in the CSM 1.6 release.

Many CAPMC v1 REST API and CLI features have been deprecated and removed as part
of CSM version 1.3. Further development of CAPMC service and CAPMC CLI has
stopped. CAPMC has been replaced with the Power Control Service (PCS) in 1.5 and
future releases.

See [PCS API](../../api/power-control.md) for more information about PCS.

Here is a list of deprecated API (CLI) endpoints:

* `/get_xname_status`
* `/xname_reinit`
* `/xname_on`
* `/xname_off`
* `/get_power_cap`
* `/get_power_cap_capabilities`
* `/set_power_cap`
* `/health`
* `/liveness`
* `/readiness`
