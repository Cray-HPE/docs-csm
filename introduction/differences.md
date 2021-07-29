# Differences from Previous Release

The most noteworthy changes since the previous release are described here.

### Topics:
   * [New Features](#new_features)
   * [Deprecating Features](#deprecating_features)
   * [Deprecated Features](#deprecated_features)
   * [Other Changes](#other_changes)


## Details

<a name="new_features"></a>
### New Features

   * Scaling improvements for larger systems
      * BOS
      * CAPMC
      * FAS
   * New hardware supported in this release:
      * Compute nodes
         * Milan-Based Grizzly Peak with A100 40 GB GPU
         * Milan-Based Windom Liquid Cooled System
         * Rome-Based HPE Apollo 6500 XL675d Gen10+ with A100 40 GB GPU
         * Rome-Based HPE Apollo 6500 XL645d Gen10+ with A100 40 GB GPU
      * User Access Nodes (UANs)
         * Milan-Based HPE DL 385(v2) Gen10+
         * Rome-Based HPE DL 385(v1) Gen10
   * Node consoles are now managed by cray-console-node which is based on conman.
   * HSM now has a v2 REST API

<a name="deprecating_features"></a>
### Deprecating Features

   * HSM v1 REST API has been deprecated as of CSM version 0.9.3. The v1 HSM APIs will be removed in the CSM version 1.3 release.
   * CAPMC Deprecation Notice. Further development of the Cray Advanced Platform Management and Control (CAPMC) service, command line, and telemetry APIs has stopped. CAPMC is being replaced with a Power Control Service (PCS) in a future release. CAPMC has entered end-of-life but will still be available. During this transition, services that call CAPMC must begin to transition to PCS. 

   * The Boot Orchestration Service (BOS) API is changing in the upcoming CSM-1.2.0 release:
        * The `--template-body` option for the Cray CLI `bos` command will be deprecated.
        * Performing a GET on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) currently returns a status code of 201, but instead it should return a status code of 200. This will be corrected to return 200.

<a name="deprecated_features"></a>
### Deprecated Features

   * cray-conman pod. This has been replaced by cray-console-node.

<a name="other_changes"></a>
### Other Changes

