# Configure NTP on NCNs

The management nodes serve Network Time Protocol (NTP) at stratum 10, except for `ncn-m001`, which serves at stratum 8 (or lower if an upstream NTP server is set). All management nodes peer with each other.

Until an upstream NTP server is configured, the time on the NCNs may not match the current time at the site, but they will stay in sync with each other.

## Topics

* [Fix BSS metadata](#fix-bss-metadata)
* [Fix broken configurations](#fix-broken-configuration)

## Fix BSS metadata

If nodes are missing metadata for NTP, then the data must be generated using `csi` and the system's `system_config.yaml` file.

The `csi` tool is not available on `ncn-m001` after the CSM install is completed. However, if the install recovery data is still available on `ncn-m001` or `ncn-m003`,
then the `csi` tool can be retrieved from the saved PIT ISO file. To do this, see the step used to obtain access to CSI in the
[Enable NCN Disk Wiping Safeguard](../../install/deploy_final_non-compute_node.md#5-enable-ncn-disk-wiping-safeguard) procedure.

If the seed data from `system_config.yaml` is not available, then open a support ticket to help generate the NTP data.

The following steps are structured to be executed on one node at a time. However, step #3 will generate all relevant files for each node. If multiple nodes are missing NTP data in BSS, then apply this fix to each node.

1. Update `system_config.yaml` to have the correct NTP settings:

    ```yaml
    ntp-servers:
      - ncn-m001
      - example.upstream.ntp.server
    ntp-timezone: UTC
    ```

1. Generate new configurations:

    ```bash
    csi config init
    ```

1. Change directory to the newly created `system/basecamp` directory and execute the `upgrade_ntp_timezone_metadata.sh` script.

    ```bash
    cd system/basecamp && /usr/share/doc/csm/upgrade/scripts/upgrade_ntp_timezone_metadata.sh
    ```

1. Find the relevant file for the node with missing metadata (such as `upgrade-metadata-000000000000.json`) based on the MAC address of the node.

1. Find the component name (xname) for the node that needs to be fixed:

    Run this command on the node that needs to be fixed in order to determine its xname.

    ```bash
    cat /etc/cray/xname
    ```

1. From `ncn-m001`, update BSS:

    ```bash
    csi handoff bss-update-cloud-init --user-data="upgrade-metadata-000000000000.json" --limit=<xname>`
    ```

1. Continue with the upgrade.

1. Set a token as described in [Identify Nodes and Update Metadata](Rebuild_NCNs/Identify_Nodes_and_Update_Metadata.md)

1. When the upgrade is completed, run this script on `ncn-m001` in order to ensure the time is set correctly on all NCNs:

    ```bash
    for i in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do 
                  ssh $i "TOKEN=$TOKEN /srv/cray/scripts/common/chrony/csm_ntp.py"; done
    ```

## Fix broken configuration

Clock sync is performed in increments instead of all at once, so it may take some time for the clocks to sync.
Before executing any commands, give the nodes some time to update. Sync typically happens within a few seconds, but on
occasion could up to 30 or more minutes. Periodically running `chronyc tracking` will show clock statistics and can be
used to determine if the clocks are gradually syncing.

On each affected NCN run the following:

1. Set a token as described in [Identify Nodes and Update Metadata](Rebuild_NCNs/Identify_Nodes_and_Update_Metadata.md).

1. Export the token.

    ```bash
    export TOKEN
    ```

1. Run the script:

```bash
/srv/cray/scripts/common/chrony/csm_ntp.py
```
