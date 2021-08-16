## Check and Set the `metal.no-wipe` Setting on NCNs

Configure the `metal.no-wipe` setting on non-compute nodes \(NCNs\) to preserve data on the nodes before doing an NCN reboot.

Run the `ncnGetXnames.sh`script to view the `metal.no-wipe` settings for each NCN. The xname and `metal.no-wipe` settings are also dumped out when executing the ncnHealthChecks.sh script.

### Prerequisites

This procedure requires administrative privileges.

It also requires that the CSM_SCRIPTDIR variable was previously defined as part of the execution of the steps in the csm-0.9.5 upgrade README. You can verify that it is set by running `echo $CSM_SCRIPTDIR` on the ncn-m001 cli. If that returns nothing, re-execute the setting of that variable from the csm-0.9.5 [README](../../README.md) file.

### Procedure

1.  Run the `${CSM_SCRIPTDIR}/ncnGetXnames.sh` script.

    The output will include a listing of all of the NCNs, their xnames, and what the `metal.no-wipe` setting is for each.

    ```bash
    ncn-m001# "${CSM_SCRIPTDIR}/ncnGetXnames.sh"
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

    The `metal.no-wipe` setting must be set to 1 \(metal.no-wipe=1\) if doing a reboot of an NCN to preserve the current data on it. If it is not set to 1 when the NCN is rebooted, it will be completely wiped and will subsequently have to be rebuilt. If the `metal.no-wipe` status for one or more NCNs is not returned, re-run the ncnGetXnames.sh script.

2.  Reset the `metal.no-wipe` settings for any NCN where it is set to 0.

    This step can be skipped if the `metal.no-wipe` is already set to 1 for any NCNs being rebooted.

    1.  Generate a token from any master or worker NCN.

        ```bash
        ncn-m001# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' \
        | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
        | jq -r '.access_token')
        ```

    2.  Update the `metal.no-wipe` settings.

        ```bash
        ncn-m001# csi handoff bss-update-param --set metal.no-wipe=1
        ```

    3.  Run the `${CSM_SCRIPTDIR}/ncnGetXnames.sh` script again to verify the no-wipe settings have been reset as expected.

        ```bash
        ncn-m001# "${CSM_SCRIPTDIR}/ncnGetXnames.sh"
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



