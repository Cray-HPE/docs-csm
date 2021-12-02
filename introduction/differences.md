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
   * PowerDNS authoriative DNS server
      * Introduces the cray-dns-powerdns, cray-dns-powerdns-postgres, and cray-powerdns-manager pods
      * Supports zone transfer to external DNS servers via AXFR query and DNSSEC
      * Please refer to the [DNS overview](../operations/network/dns/DNS.md) and [PowerDNS Configuration Guide](../operations/network/dns/PowerDNS_Configuration.md) for further information.
   * NCN user password and SSH key management is available for both root and
     non-root users via NCN personalization. Please refer to [Configure Non-Compute Nodes with CFS](../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md).

<a name="deprecating_features"></a>
### Deprecating Features

   * HSM v1 REST API has been deprecated as of CSM version 0.9.3. The v1 HSM APIs will be removed in the CSM version 1.3 release.
   * Many CAPMC v1 REST API and CLI features are being deprecated as part of CSM version 1.0; Full removal of the deprecated CAPMC features will happen in CSM version 1.3. Further development of CAPMC service or CLI has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced with the Power Control Service (PCS) in a future release. The current API/CLI portfolio for CAPMC are being pruned to better align with the future direction of PCS. More information about PCS and the CAPMC transition will be released as part of subsequent CSM releases.
   * HMNFD v1 REST API has been deprecated as of CSM version 1.2.  The v1 HMNFD APIs will be removed in the CSM version 1.5 release.
     * For more information on what features have been deprecated please view the CAPMC swagger doc or read the [CAPMC deprecation notice](../introduction/CAPMC_deprecation.md)
   * The Boot Orchestration Service (BOS) API is changing in the upcoming CSM-1.2.0 release:
        * The `--template-body` option for the Cray CLI `bos` command will be deprecated.
        * Performing a GET on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) currently returns a status code of 201, but instead it should return a status code of 200. This will be corrected to return 200.
   * PowerDNS will replace Unbound as the authoritative DNS source in CSM version 1.2.
        * The cray-dns-unbound-manager CronJob will be deprecated in a future release once all DNS records are migrated to PowerDNS.
        * The introduction of PowerDNS and Bifurcated CAN will introduce some node and service naming changes.
        * Please see the [PowerDNS migration notice](../introduction/PowerDNS_migration.md) for more information.
   * The Compute Rolling Upgrade Service (CRUS) will be deprecated in the CSM-1.3.0 release. Enhanced BOS functionality will replace CRUS. This includes the ability to stage changes to nodes that can be acted upon later when the node reboots. It also includes the ability to reboot nodes without specifying any boot artifacts. This latter ability relies on the artifacts already having been staged.

<a name="deprecated_features"></a>
### Deprecated Features

   * cray-conman pod. This has been replaced by cray-console-node.
   * The cray-externaldns-coredns, cray-externaldns-etcd, and cray-externaldns-wait-for-etcd pods have been removed. PowerDNS is now the provider of the external DNS service.

<a name="other_changes"></a>
### Other Changes

