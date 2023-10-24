# Check and Set the `metal.no-wipe` Setting on NCNs

Configure the `metal.no-wipe` setting on non-compute nodes \(NCNs\) to preserve data on the nodes before doing an NCN reboot.

Run the `ncnGetXnames.sh`script to view the `metal.no-wipe` settings for each NCN. The component name (xname) and `metal.no-wipe` settings are also dumped out when executing the `/opt/cray/platform-utils/ncnHealthChecks.sh` script.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Run the `ncnGetXnames.sh` script.

    The output will end with a listing of all of the NCNs, their component names (xnames), and what the `metal.no-wipe` setting is for each.

    ```bash
    ncn# /opt/cray/platform-utils/ncnGetXnames.sh
    ```

    Example of the NCN listing at the end of the output:

    ```text
    ncn-m001: x3000c0s1b0n0 - metal.no-wipe=1
    ncn-m002: x3000c0s2b0n0 - metal.no-wipe=1
    ncn-m003: x3000c0s3b0n0 - metal.no-wipe=1
    ncn-w001: x3000c0s4b0n0 - metal.no-wipe=1
    ncn-w002: x3000c0s5b0n0 - metal.no-wipe=1
    ncn-w003: x3000c0s6b0n0 - metal.no-wipe=1
    ncn-s001: x3000c0s7b0n0 - metal.no-wipe=1
    ncn-s002: x3000c0s8b0n0 - metal.no-wipe=1
    ncn-s003: x3000c0s9b0n0 - metal.no-wipe=1
    ```

    The `metal.no-wipe` setting must be set to 1 (that is, `metal.no-wipe=1`) if doing a reboot of an NCN, in order to preserve the
    current data on it. If it is not set to 1 when the NCN is rebooted, then the NCN will be completely wiped and will subsequently
    have to be rebuilt. If the `metal.no-wipe` status for one or more NCNs is not returned, then re-run the `ncnGetXnames.sh` script.

1. Reset the `metal.no-wipe` settings for any NCN where it is set to 0.

    This step can be skipped if the `metal.no-wipe` is already set to 1 for any NCNs being rebooted.

    1. Generate an API token and export it.

        ```bash
        ncn# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' \
                | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                | jq -r '.access_token')
        ```

    1. Update the `metal.no-wipe` settings.

        ```bash
        ncn# /tmp/csi handoff bss-update-param --set metal.no-wipe=1
        ```

    1. Run the `ncnGetXnames.sh` script again to verify the `metal.no-wipe` settings have been updated as expected.
