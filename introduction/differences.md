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

<a name="deprecating_features"></a>
### Deprecating Features

<a name="deprecated_features"></a>
### Deprecated Features

   * cray-conman pod.  This has been replaced by cray-console-node.

<a name="other_changes"></a>
### Other Changes

