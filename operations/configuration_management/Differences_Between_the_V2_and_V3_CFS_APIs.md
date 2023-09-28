# Differences Between the V2 and V3 CFS APIs

The v3 CFS API contains a number of differences and improvements over the previous v2 API.
For convenience all changes are listed here.

* The v3 API supports paging through records for components, sessions and configurations.
  See [Paging CFS Records](Paging_CFS_Records.md) for more information.
* The v3 API uses `snake_case` rather than `camelCase` for all parameters in queries and responses.
  This brings the API inline with other CSM APIs.
* The response format has changed for queries listing components, sessions or configurations.
  Responses are no longer a list of records, and will instead contain a key for the record type which contains the list of records.
  (E.g. `{"components":[]}` for the components endpoint).
  Responses will also include a `next` section that is used for paging through records.
  See [Paging CFS Records](Paging_CFS_Records.md) for more information.
* Component records no longer include the `state` list of applied playbooks by default.
  The `state` can requested with the `state_details` parameter.
* Some fields now have maximum sizes:
  * Configuration names are now limited to 60 characters
  * Additional inventory URLs are limited to 240 characters
  * Configuration layer names are limited to 45 characters
* The v3 API has three new global options: `default_page_size`, `debug_wait_time` and `include_ara_links`.
  See [CFS Global Options](CFS_Global_Options.md) for more information.
* Session and component records now include a `logs` field with a link to the ARA UI with the appropriate filter for that session or component.
* The `default_playbook` option is now deprecated.
  It can still be read using the v3 API but can not be set using the v3 API.
  Any value set using the v2 API will still be usable by configurations, even v3 configurations, until the v2 API is removed.
* Sessions now support a `debug_on_failure` option that will cause sessions that fail during Ansible execution to remain up for a limited time so that users can exec into the AEE container and debug the problem.
  See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.
* The CFS v3 supports new debugging playbooks which are included by default.
This can be accessed by specifying `debug_fail`, `debug_facts` or `debug_noop` as the configuration for a session if a configuration has hot already been created with that name.
  See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.
