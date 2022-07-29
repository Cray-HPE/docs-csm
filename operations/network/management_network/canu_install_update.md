# Upgrade Canu

## Prerequisite

Before using the CSM Automated Network Utility (CANU) to test, validate, or configure the network, ensure that CANU is running on the latest version. 

If CANU is already installed, then check the CANU version with following command: 

```text
canu --version
```

Upgrade/Install procedure:

1. Download the latest version of CANU.  

   * [Canu releases](https://github.com/Cray-HPE/canu/releases)

   * Once you have succesfully moved the new RPM to your system, wether that is your workstation or live system. You can issue the following command(s) to upgrade or install Canu:   


To fresh install Canu on system: 

```text
rpm -ihv <canu.rpm>
```

To upgrade existing version of Canu: 

```text
rpm -Uhv <canu.rpm>
```

To remove Canu from your system: 

```text
rpm -e <canu.rpm>
```

[Back to README](index.md)

