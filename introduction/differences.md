# Differences from Previous Release

The most noteworthy changes since the previous release are described here.

### Topics

   * [New Features](#new_features)
   * [Deprecated Features](#deprecated_features)
   * [Removed Features](#removed_features)
   * [Other Changes](#other_changes)


## Details

<a name="new_features"></a>
### New Features

The following features are new in this release:

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

<a name="deprecated_features"></a>
### Deprecated Features

The following features are no longer supported and are planned to be removed in a future release:

   * HSM v1 REST API has been deprecated as of CSM version 0.9.3. The v1 HSM APIs will be removed in the CSM version 1.3 release.
   * Many CAPMC v1 REST API and CLI features are being deprecated as part of CSM version 1.0.1; Full removal of the deprecated CAPMC features will happen in CSM version 1.3. Further development of CAPMC service or CLI has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced with the Power Control Service (PCS) in a future release. The current API/CLI portfolio for CAPMC are being pruned to better align with the future direction of PCS. More information about PCS and the CAPMC transition will be released as part of subsequent CSM releases.
     * For more information on what features have been deprecated please view the CAPMC swagger doc or read the [CAPMC deprecation notice](../introduction/CAPMC_deprecation.md)

   * The Boot Orchestration Service (BOS) API is changing in the upcoming CSM-1.2.0 release:
        * The `--template-body` option for the Cray CLI `bos` command will be deprecated.
        * Performing a GET on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) currently returns a status code of 201, but instead it should return a status code of 200. This will be corrected to return 200.

<a name="removed_features"></a>
### Removed Features

The following features have been completely removed:

   * cray-conman pod. This has been replaced by cray-console-node.
   * The `csi config init` command has changed the option from `-ntp-pool` to `ntp-pools` to support a comma-separated list of NTP pools.

<a name="other_changes"></a>
### Other Changes

