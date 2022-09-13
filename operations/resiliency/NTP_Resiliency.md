# NTP Resiliency

Sync the time on all non-compute nodes \(NCNs\) via Network Time Protocol \(NTP\). Avoid a single point of failure for NTP when testing system resiliency.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Set the date manually, if the time on NCNs is off by more than a few hours.

    For example:

    ```bash
    timedatectl set-time "2021-02-19 15:04:00"
    ```

1. Configure NTP on the Pre-install Toolkit \(PIT\) node.

    > If the system no longer has a booted PIT node, then skip this step.

    ```bash
    /root/bin/configure-ntp.sh
    ```

1. Sync NTP on all other nodes.

    If the system still has a booted PIT node, then follow these substeps from it. Otherwise,
    they can be performed on any NCN.

    1. Get a token to use the REST API.

        ```bash
        TOKEN=$(curl -s -S -d grant_type=client_credentials -d client_id=admin-client \
                  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
        ```

    1. Generate list of NCNs from SLS.

        ```bash
        NCNS=$(curl -skH "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/hardware |
                 jq -r '.[] | select(.TypeString=="Node") | select(.ExtraProperties.Role=="Management") | .ExtraProperties.Aliases[] | .' | 
                 sort -u)
        ```

    1. Sync NTP on all other nodes.

        ```bash
        for i in ${NCNS} ; do
            # Skip ncn-m001 if we are on the PIT node
            [[ ${i} == ncn-m001 ]] && [[ -f /etc/pit-release ]] && continue
            echo "------${i}--------"
            ssh ${i} "TOKEN=${TOKEN} /srv/cray/scripts/common/chrony/csm_ntp.py"
        done
        ```
