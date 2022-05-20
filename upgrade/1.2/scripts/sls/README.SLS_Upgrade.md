# Upgrade SLS Offline from CSM 1.0.x to CSM 1.2

## Abstract

During the update of SLS, at a minimum, answers to the following questions must be known prior to upgrading:

1. By default in 1.2 non-administrative user traffic will be migrated from the CAN to the CHN while minimizing changes. If
   you want it to continue to come in via the CAN, or if the site is air-gapped, specify the correct options Will user
   traffic (non-administrative) come in via the CAN, CHN or is the site air-gapped?

1. What is the internal VLAN and the site-routable IP subnet for the new CAN or CHN?

1. Is there a need to preserve any existing IP address(es) during the CAN-to-CMN migration?

   * One example is the `external-dns` IP address used for DNS lookups of system resources from site DNS servers. Changes to
     `external-dns` often require changes to site resources with requisite process and timeframes from other groups. For
     preserving `external-dns` IP addresses, the flag is `--preserve-existing-subnet-for-cmn external-dns`.

     **WARNING:** It is up to the user to compare pre-upgraded and post-upgraded SLS files for sanity. Specifically, in the
     case of preserving `external-dns` values, to prevent site-networking changes that might result in NCN IP addresses
     overlapping during the upgrade process. This requires network subnetting expertise and EXPERT mode below.
   * Another, mutually exclusive example is the need to preserve all NCN IP addresses related to the old CAN while migrating
     the new CMN. This preservation is not often needed as the transition of NCN IP addresses for the CAN-to-CMN is automatically
     handled during the upgrade. The flag to preserve CAN-to-CMN NCN IP addresses is mutually exclusive with other preservations
     and the flag is `--preserve-existing-subnet-for-cmn ncns`.
   * Should no preservation flag be set, the default behavior is to recalculate every IP address on the existing CAN while migrating
     to the CMN. The behavior in this case is to calculate the subnet sizesbased on number of devices (with a bit of spare room),
     while maximizing IP address pool sizes for (dynamic) services.

## Procedure

1. Get a token:

    ```bash
    ncn# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. Extract SLS data to a file:

    ```bash
    ncn# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
    ```

1. Upgrade SLS data.

    * Example 1: Upgrade, using the CHN as the system default route (will by default output to `migrated_sls_file.json`).

        ```bash
        ncn# ./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                --bican-user-network-name CHN \
                --customer-highspeed-network 5 10.103.11.192/26
        ```

    * Example 2: Upgrade, using the CAN as the system default route, keep the generated CHN (for testing), and preserve the existing external-dns entry.

        ```bash
        ncn# ./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                --bican-user-network-name CAN \
                --customer-highspeed-network 5 10.103.11.192/26 \
                --preserve-existing-subnet-for-cmn external-dns \
                --retain-unused-user-network
        ```

    NOTE: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components
    (UAN, login nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure subnet reservations are correct to prevent any data loss.

1. Upload migrated SLS file to SLS service:

    ```bash
    ncn# curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
    ```

## SLS Updater Help

For help and all options, run the following:

```bash
ncn# ./sls_updater_csm_1.2.py --help
```

[Go Back to Stage 0.2 - Update SLS](../../Stage_0_Prerequisites.md#update-sls)