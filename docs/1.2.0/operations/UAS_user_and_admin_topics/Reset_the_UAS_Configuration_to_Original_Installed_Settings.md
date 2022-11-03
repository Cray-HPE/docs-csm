# Clear UAS Configuration

**WARNING:** The procedure described here will remove all UAS configuration including some configuration that is installed upon installation / upgrade of the HPE Cray EX system.
If this procedure is used, the `update-uas` Helm chart must be removed and re-deployed to restore the full HPE provided configuration.
This procedure should only be used in an extreme situation where the UAS configuration has become corrupted to the point where it can no longer be managed.
All UAS configuration can normally be managed through the `cray uas admin config ...` commands.

**WARNING:** Configuration lost using this procedure is not recoverable.

How to remove a customized UAS configuration and restore the base installed configuration.

The configuration set up using the Cray CLI to interact with UAS persists as long as UAS remains installed and survives upgrades. This is called the running configuration and it is both persistent and malleable.
During installation and localization, however, the installer creates a base installed configuration. It may be necessary to return to this base configuration.
To do this, delete the running configuration, which will cause the UAS to reset to the base installed configuration.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

1. Delete the running configuration.

    ```bash
    ncn-w001 # cray uas admin config delete
    This will delete all locally applied configuration, Are you sure? [y/N]:
    ```

2. Confirm the command. This will delete the running configuration and cannot be undone.

    ```bash
    ncn-w001 # cray uas admin config delete
    This will delete all locally applied configuration, Are you sure? [y/N]: y
    ```

    Alternatively, note that the interactive prompt can be bypassed by supplying the `-y` option.

    ```bash
    ncn-w001 # cray uas admin config delete -y
    ```

[Top: User Access Service (UAS)](index.md)
