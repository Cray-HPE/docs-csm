# Cray System Management (CSM) 1.7.1 Release Notes

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.7 release notes page, including links to other patch release notes,
see [CSM 1.7 release notes](RELEASE_NOTES.md).

* [Additions and improvements](#additions-and-improvements)
* [Bug fixes](#bug-fixes)
* [Known issues](#known-issues)

## Additions and improvements

### Hardware support

### General

### Security

### Tests

* Many improvements were made to automated SAT functional tests included in the `csm-testing` RPM.
  This includes the following:
    * Created additional functional tests for `sat status`, `sat bootprep`, and `sat hwinv`
    * Split `sat bootprep` tests into separate test cases that can run in parallel
    * Added cleanup of deleted images and completed IMS jobs created by `sat bootprep` tests
    * Added dynamic generation of SAT Goss tests
    * Fixed bugs and improved resiliency of tests for `sat version`, `sat nid2xname`, `sat
      firmware`, and `sat bootprep`
    * Extended timeout to 30m for SAT functional tests

## Customer-requested

* Updated the `sat bmccreds` command to log a warning and prompt whether the user wants to continue
  if the provided password is longer than 20 characters. This is the maximum password length
  supported by `ipmitool`, which is required to control management nodes during system boot and
  shutdown procedures.

## Bug fixes

* Fixed a bug in `sat hwinv` that caused values in multi-value fields to be printed in a
  non-deterministic order. Such fields are now always printed in sorted order.
* Fixed a bug in `sat bootsys` that resulted in an `AttributeError` exception when the `known_hosts`
  file contains invalid lines with the incorrect number of fields.
* Fixed `sat bootprep` to no longer perform its own resolution of branch names to commit hashes when
  creating CFS configurations with CFS v3. This allows the use of external repositories with branch
  names for CFS configurations created by `sat bootprep`.

## Known issues

* In multi-tenant configurations leveraging Slingshot networking as described in the "HPE Slingshot Network Operator for CSM Multi-Tenancy"
  section of the HPE Slingshot Administration Guide, the iSCSI protocol cannot be routed over the High-Speed Network (HSN). While compute
  nodes remain in the same HSN subnet, they are assigned to a different VLAN than Non-Compute Nodes (NCNs). This VLAN isolation prevents
  compute nodes from accessing iSCSI services hosted on NCNs via the HSN.

  Compute nodes must be configured to use iSCSI over the Node Management Network (NMN) to successfully boot and to prevent iSCSI access
  issues when running nodes are moved into tenant-specific VLANs.
  
For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).
