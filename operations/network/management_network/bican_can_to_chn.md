# BICAN CHN SLS Update

## Overview

- This operation will update the system SLS file to use the CHN.
- This removes the CAN entries from SLS.
- More details on BICAN can be found here [BICAN Technical Summary](bican_technical_summary.md)

### Retrieve SLS data as JSON

1. (`ncn-m001#`) Obtain a token.

   ```bash
   export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. (`ncn-m001#`) Create a working directory.

   ```bash
   mkdir /root/sls_upgrade && cd /root/sls_upgrade
   ```

1. (`ncn-m001#`) Extract SLS data to a file.

   ```bash
   curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

- **Note:**: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UANs, login
  nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure that subnet reservations are correct in order to prevent any data mismatches.

### Update SLS to use CHN

Example: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

The `CHN VLAN` and `CHN IPV4 SUBNET` should be discussed and agreed upon with the site networking team.
For sizing requirements, reference the sizing guide, [CAN or CHN sizing and requirements](./bican_support_matrix.md#can-or-chn-sizing-and-requirements)

   (`ncn-m001#`)

   ```bash
   export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ${DOCDIR}/sls_can_to_chn.py --sls-input-file sls_input_file.json \
                         --customer-highspeed-network REPLACE_CHN_VLAN REPLACE_CHN_IPV4_SUBNET
   ```

### Upload migrated SLS file to SLS service

If the following command does not complete successfully, check if the `TOKEN` environment variable is set correctly.

   (`ncn-m001#`)

   ```bash
   curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
   ```
