# Differences from Previous Release

The most noteworthy changes since the previous release are described here.

## Topics

* [New Features](#new-features)
* [Deprecated Features](#deprecated-features)
* [Removed Features](#removed-features)

## New Features

The following features are new in this release:

* Scaling improvements for larger systems to the following services:
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
* Node consoles are now managed by `cray-console-node` which is based on ConMan
* HSM now has a v2 REST API
* NCN user password and SSH key management is available for both root and
  non-root users via NCN personalization. See [Configure Non-Compute Nodes with CFS](../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md).

## Deprecated features

The following features are no longer supported and are planned to be removed in a future release:

* HSM v1 REST API has been deprecated as of CSM version 0.9.3. The v1 HSM APIs will be removed in the CSM version 1.3 release.
* Many CAPMC v1 REST API and CLI features were deprecated as part of CSM version 1.0; Full removal of the deprecated CAPMC features will happen in CSM version 1.3. Further
  development of CAPMC service or CLI has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced with the Power Control
  Service (PCS) in a future release. The current API/CLI portfolio for CAPMC is being pruned to better align with the future direction of PCS. More information about PCS and
  the CAPMC transition will be released as part of subsequent CSM releases.
  * For more information on what features have been deprecated, see the [CAPMC deprecation notice](CAPMC_deprecation.md).
* HMNFD v1 REST API has been deprecated as of CSM version 1.2. The v1 HMNFD APIs will be removed in the CSM version 1.5 release.
* The Boot Orchestration Service (BOS) API is changing in the CSM V1.2.0 release:
  * The `--template-body` option for the Cray CLI `bos` command is deprecated.
  * Prior to CSM V1.2.0, performing a successful `GET` on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) incorrectly returned
    a status code of 201. It now correctly returns a status code of 200.
* The Compute Rolling Upgrade Service (CRUS) was deprecated in CSM 1.2.0 and it will be removed in CSM 1.6.0.
  * Enhanced BOS functionality will replace CRUS. See [Rolling Upgrades using BOS](../operations/boot_orchestration/Rolling_Upgrades.md).

## Removed features

The following features have been completely removed:

* `cray-conman` pod. This has been replaced by `cray-console-node`.
* CFS v1 API and CLI. The v2 API and CLI have been the default since CSM 0.9 (Shasta 1.4).
* SLS support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs.
