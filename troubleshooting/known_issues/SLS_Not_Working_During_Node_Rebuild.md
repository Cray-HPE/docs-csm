# SLS Not Working During Node Rebuild

During some node rebuilds (including those that happen during management node upgrades in the CSM upgrade process),
the SLS Postgres database gets into a bad state, causing SLS to become unhealthy. This page outlines how to detect if this has happened and provides a remediation procedure.

**Note:** If encountering this during a CSM upgrade, then at this point of the upgrade process, the system has not yet upgraded the CSM services
themselves. Because of that, the documentation for the source CSM version still applies, and this page includes links for both the current
CSM version (1.6) and for the previous CSM version (1.5).

## Detection

This procedure can be run on any master or worker NCN (unless it is the node being rebuilt).

1. Get a token to use for API requests to SLS.

    ```bash
    TOKEN=$(\
      set -o pipefail
      secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` &&
      curl -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret="$secret" \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
      jq -r '.access_token') ; [[ -n $TOKEN ]] && echo "Token obtained" || echo "Error getting token"
    ```

    Expected output:

    ```text
    Token obtained
    ```

1. Perform basic SLS health check.

    ```bash
    curl -iskH "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/sls/v1/health ; echo
    ```

    Example output if SLS is healthy:

    ```text
    HTTP/2 200
    date: Fri, 17 Jun 2022 16:23:22 GMT
    content-length: 58
    content-type: text/plain; charset=utf-8
    x-envoy-upstream-service-time: 4
    server: istio-envoy

    {"Vault":"Enabled and initialized","DBConnection":"Ready"}
    ```

    Note that the first line of expected output includes `200` as the status code of the response. If that
    is not the case, or if other errors are seen, proceed to [Remediation](#remediation).

1. Perform a basic SLS liveness check.

    ```bash
    curl -iskH "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/sls/v1/liveness ; echo
    ```

    Example output if SLS is functioning:

    ```text
    HTTP/2 204
    date: Fri, 17 Jun 2022 16:25:26 GMT
    x-envoy-upstream-service-time: 3
    server: istio-envoy
    ```

    As with the previous command, validate that the status code on the first line matches the expected output (`204` in
    this case). If a different status code is returned, or other errors are seen, proceed to [Remediation](#remediation).

1. Perform a basic SLS query.

    This query lists all nodes in the system with the `Management` role.

    ```bash
    curl -skH "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management | jq
    ```

    Example output if SLS is working:

    ```json
    [
      {
        "Parent": "x3000c0s1b0",
        "Xname": "x3000c0s1b0n0",
        "Type": "comptype_node",
        "Class": "River",
        "TypeString": "Node",
        "LastUpdated": 1654191069,
        "LastUpdatedTime": "2022-06-02 17:31:09.155802 +0000 +0000",
        "ExtraProperties": {
          "Aliases": [
            "ncn-m001"
          ],
          "NID": 100010,
          "Role": "Management",
          "SubRole": "Master"
        }
      },

      ["...omitting many lines for readability..."],

      {
        "Parent": "x3000c0s7b0",
        "Xname": "x3000c0s7b0n0",
        "Type": "comptype_node",
        "Class": "River",
        "TypeString": "Node",
        "LastUpdated": 1654191069,
        "LastUpdatedTime": "2022-06-02 17:31:09.155802 +0000 +0000",
        "ExtraProperties": {
          "Aliases": [
            "ncn-w004"
          ],
          "NID": 100004,
          "Role": "Management",
          "SubRole": "Worker"
        }
      }
    ]
    ```

    If the query fails, proceed to [Remediation](#remediation).

If all of the API calls provide expected output, then SLS appears to be working properly. In that case, the rest of this page should be skipped.

## Remediation

If a check in the previous section indicates that SLS is not working properly, then check the status of the SLS Postgres database.

```bash
kubectl get postgresql cray-sls-postgres -n services
```

Expected output if the database is healthy:

```text
NAME                TEAM       VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE    STATUS
cray-sls-postgres   cray-sls   11        3      1Gi                                     157d   Running
```

* If the `STATUS` is `SyncFailed`:
    * If currently doing a CSM upgrade, then see
      [(CSM 1.5) Postgres status `SyncFailed`](https://github.com/Cray-HPE/docs-csm/blob/release/1.5/operations/kubernetes/Troubleshoot_Postgres_Database.md#postgres-status-syncfailed).
    * Otherwise, see [Postgres status `SyncFailed`](../../operations/kubernetes/Troubleshoot_Postgres_Database.md#postgres-status-syncfailed).
* Otherwise, see the standard Postgres troubleshooting procedures for further avenues of investigation.
    * If currently doing a CSM upgrade, then see
      [(CSM 1.5) Troubleshoot Postgres Database](https://github.com/Cray-HPE/docs-csm/blob/release/1.5/operations/kubernetes/Troubleshoot_Postgres_Database.md).
    * Otherwise, see [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md).
