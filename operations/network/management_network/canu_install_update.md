# Upgrade CANU

## Prerequisite

Before using the [CSM Automatic Network Utility (CANU)](../../../glossary.md#csm-automatic-network-utility-canu) to test, validate, or configure the network,
ensure that CANU is running on the latest version.

CANU can be run from a personal workstation (the instructions below are targeted at Mac users), or on the
[Non-Compute Nodes (NCNs)](../../../glossary.md#non-compute-node-ncn).

Since CANU is a Python application, it can be run on Linux and Mac, but the RPM is not currently designed to support multiple operating system environments.

The CANU project can be cloned from GitHub and run directly by Python, but the project dependencies will need to be installed manually. This process is not supported by
this documentation.

The Windows operating system is untested and currently not officially supported. HPE Cray recommends that Windows users install or update CANU on the Shasta NCNs
instead of attempting a workstation installation.

If CANU is already installed, then check the CANU version with following command.

```bash
canu --version
```

## Upgrade/install procedure

1. Download the latest version of CANU from [CANU releases](https://github.com/Cray-HPE/canu/releases).

1. Upgrade or install CANU.

   * To fresh install CANU on system

      ```bash
      rpm -ihv <canu.rpm>
      ```

   * To upgrade an existing version of CANU

      ```bash
      rpm -Uhv <canu.rpm>
      ```

## Remove CANU

If it is necessary to remove CANU from the system, run the following command:

```bash
rpm -e canu
```

[Back to README](index.md)
