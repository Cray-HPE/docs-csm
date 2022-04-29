# Introduction to CANU

The CSM Automatic Network Utility (CANU) guides administrators through the installation of new Shasta networks. CANU helps ensure the installation follows best practices and sets administrators up with supported configuration.

The following are some of the tasks that CANU can perform:

* Check if the management switches on a Shasta network meet the firmware version requirements
* Check the cabling status of the management switches on a Shasta network using LLDP.
* Use a CANU-generated configuration to compare an existing network configuration against the best practice configuration.

CANU reads switch version information from the `canu.yaml` file in the root directory.

CANU documentation can be found here: https://github.com/Cray-HPE/canu

If doing a CSM install or upgrade, a CANU RPM is located in the release tarball. For more information, see this procedure: [Update CANU From CSM Tarball](update_canu_from_csm_tarball.md)

[Back to Index](index.md)
