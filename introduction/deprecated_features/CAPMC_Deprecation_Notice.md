# CAPMC Deprecation Notice

Many CAPMC v1 REST API and CLI features are being deprecated as of CSM version 1.0. Full removal of the following deprecated CAPMC features will happen in a future CSM release.
Further development of CAPMC service and CLI has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced with the Power Control
Service (PCS) in a future release. The current API/CLI portfolio for CAPMC is being pruned to better align with the future direction of PCS. More information about PCS and the CAPMC
transition will be released as part of subsequent CSM releases.

The API endpoints that remain un-deprecated will remain supported until their phased transition into PCS. For example, Power Capping is not deprecated and will be supported in PCS.
As PCS is developed, CAPMC Power Capping and PCS Power Capping will both function. Eventually callers of the CAPMC Power Capping API/CLI will need to transition to call PCS, because
the API will be different.

Here is a list of deprecated API endpoints (the corresponding CLI commands are also deprecated):

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
