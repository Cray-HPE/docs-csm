# CAPMC Deprecation Notice

CAPMC was deprecated in CSM 1.5 and intended to be removed from CSM 1.6.  The
decision was made to not remove it in CSM 1.6 so that existing dependencies
that have not yet transitioned to PCS do not break.  Support for CAPMC however,
is removed starting in CSM 1.6.  Everyone is encouraged to transition to PCS as
soon as possible.

CAPMC has been end-of-life since the CSM 1.3 release. The remaining APIs and CLI commands
are officially deprecated.

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
