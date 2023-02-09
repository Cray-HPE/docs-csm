# CAPMC Deprecation Notice

## CAPMC enters final life cycle before deletion

PCS v1 has been released to production and indicated the beginning of the final life cycle for CAPMC. CAPMC will
continue to co-exist with PCS until its final deletion. CAPMC is slated to be permanently removed from the system
beginning with the first release of software in 2024. Please begin to migrate to PCS.

### Deprecated Features in CSM 1.0

Many CAPMC v1 REST API and CLI features are being deprecated as part of CSM version 1.0; Full removal of the
following deprecated CAPMC features will happen in CSM version 1.3. Further development of CAPMC service or CLI
has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced
with the Power Control Service (PCS) in a future release. The current API/CLI portfolio for CAPMC are being pruned
to better align with the future direction of PCS. More information about PCS and the CAPMC transition will be
released as part of subsequent CSM releases.

The API endpoints that remain un-deprecated will remain supported until their 'phased transition' into PCS (e.g.
Power Capping is not 'deprecated' and will be supported in PCS; As PCS is developed, CAPMC's Power Capping and
PCS's Power Capping will both function, eventually callers of the CAPMC power capping API/CLI will need to will
need transition to call PCS as the API will be different.)

Here is a list of deprecated API (CLI) endpoints:

* node control
  * `/get_node_rules`
  * `/get_node_status`
  * `/node_on`
  * `/node_off`
  * `/node_reinit`
* group control
  * `/group_reinit`
  * `/get_group_status`
  * `/group_on`
  * `/group_off`
* node energy
  * `/get_node_energy`
  * `/get_node_energy_stats`
  * `/get_node_energy_counter`
* system monitor
  * `/get_system_parameters`
  * `/get_system_power`
  * `/get_system_power_details`
* EPO
  * `/emergency_power_off`
* utilities
  * `/get_nid_map`
