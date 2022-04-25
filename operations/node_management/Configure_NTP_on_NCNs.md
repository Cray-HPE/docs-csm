# Configure NTP on NCNs

The management nodes serve Network Time Protocol (NTP) at stratum 10, except for `ncn-m001`, which serves at stratum 8 (or lower if an upstream NTP server is set). All management nodes peer with each other.

Until an upstream NTP server is configured, the time on the NCNs may not match the current time at the site, but they will stay in sync with each other.

**Topics**
   * [Fix BSS Metadata](#fix-bss-metadata)
   * [Fix broken configs](#fix-broken-configs)

<a name="fix-bss-metadata"></a>

###### Fix BSS Metadata

If nodes are missing metadata for NTP, you will be required to generate the data using `csi` and your system's `system_config.yaml`. If you do not have your seed data in the `system_config.yaml` then you will need to open a ticket to help generate the NTP data.

The following steps are structured to be executed on one node at a time. However, step #3 will generate all relevant files for each node. If multiple nodes are missing NTP data in BSS, you can apply this fix to each node.

1. Update system_config.yaml to have the correct NTP settings:
    ```yaml
    ntp-servers:
      - ncn-m001
      - time.nist.gov
    ntp-timezone: UTC
    ```
2. Generate new configs:
    ```bash
    ncn# csi config init
    ```
3. In the newly created `system/basecamp` directory, copy in and execute the metadata script that is included in the upgrade scripts of this documentation:
    ```bash
    ncn# ./upgrade_ntp_timezone_metadata.sh
    ```
4. Find the relevant file(s) to the node(s) with missing metadata, such as `upgrade-metadata-000000000000.json` based on the mac address of the node.
5. Find the xname for the node that needs to be fixed:
    ```bash
    ncn# cat /etc/cray/xname
    ```
6. From `ncn-m001` execute the following command to update BSS:
    ```bash
    ncn# csi handoff bss-update-cloud-init --user-data="upgrade-metadata-000000000000.json" --limit=<xname>`
    ```

7. Continue with the upgrade.
8. When the upgrade is completed, run this script on each NCN to ensure the time is set correctly:

    > If more than nine NCNs are in use on the system, update the for loop in the following command accordingly.

    ```bash
    ncn-m002# for i in ncn-{w,s}00{1..3} ncn-m00{2..3}; do echo \
    "------$i--------"; ssh $i '/srv/cray/scripts/common/chrony/csm_ntp.py'; done
    ```

<a name="fix-broken-configs"></a>

###### Fix Broken Configs

On each NCN, run:

```
ncn# csm_ntp.py
```