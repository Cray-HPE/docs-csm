# Upgrade CANU

## Prerequisite

Before using the CSM Automated Network Utility (CANU) to test, validate, or configure the network, ensure that CANU is running on the latest version.

CANU can be run from your personal workstation (the instructions below are targeted at Mac users), or on the Shasta NCN nodes.

Since CANU is a python application, it can be run on Linux and Mac, but the RPM is not currently designed to support multiple operating system environments.

The CANU project can be cloned from GitHub and run directly by Python, but the project dependencies will need to be installed manually. This process is not supported by this documentation.

The Windows operating system is untested and currently not officially supported. We recommend that Windows users install or update CANU on the Shasta NCN nodes instead of attempting a workstation installation.

If CANU is already installed, then check the CANU version with following command.

```text
canu --version
```

### Upgrade/install procedure

1. Download the latest version of CANU.  

   * [CANU releases](https://github.com/Cray-HPE/canu/releases)

   * Once you have successfully downloaded the CANU RPM to your target system, issue the following command(s) to upgrade or install CANU.  

### To fresh install CANU on system

```text
rpm -ihv <canu.rpm>
```

### To upgrade an existing version of CANU

```text
rpm -Uhv <canu.rpm>
```

### Remove CANU

If it is necessary to remove CANU from the system, the following command can be used:

```text
rpm -e <canu.rpm>
```

[Back to README](README.md)
