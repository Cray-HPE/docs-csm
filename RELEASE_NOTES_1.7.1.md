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

## Customer-requested

## Bug fixes

* After upgrading to Kubernetes 1.32 in CSM 1.7.0, some Pod Security Policy (PSP) Role Bindings and Service Accounts still exist.

  Since PSP is not supported in Kubernetes 1.25+, these unneeded Role Bindings and Service Accounts are removed after Kubernetes
  is upgraded to 1.32.

## Known issues

* In multi-tenant configurations leveraging Slingshot networking as described in the "HPE Slingshot Network Operator for CSM Multi-Tenancy"
  section of the HPE Slingshot Administration Guide, the iSCSI protocol cannot be routed over the High-Speed Network (HSN). While compute
  nodes remain in the same HSN subnet, they are assigned to a different VLAN than Non-Compute Nodes (NCNs). This VLAN isolation prevents
  compute nodes from accessing iSCSI services hosted on NCNs via the HSN.

  Compute nodes must be configured to use iSCSI over the Node Management Network (NMN) to successfully boot and to prevent iSCSI access
  issues when running nodes are moved into tenant-specific VLANs.
  
For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).
