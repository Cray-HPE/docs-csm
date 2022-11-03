# Get a Long-Lived Token for a Service Account

Set up a long-lived offline token for a service account using the Keycloak REST API.
Keycloak implements the OpenID Connect protocol, so this is a standard procedure for any OpenID Connect server.

Refer to [Offline Access](https://www.keycloak.org/docs/latest/server_admin/index.html#_offline-access) in the official Keycloak documentation for more information.

## Prerequisites

- A client or service account has been created.
  - See [Create a Service Account in Keycloak](Create_a_Service_Account_in_Keycloak.md).
- The `CLIENT_SECRET` variable has been set up.
  - See [Retrieve the Client Secret for Service Accounts](Retrieve_the_Client_Secret_for_Service_Accounts.md).

## Get a long-lived token for a service account

- Replace the `my-test-client` value in the command below with the ID of the target client.
- The `scope` option should be set to `offline_access`.

(`ncn-mw#`) Get a long-lived token for a service account with the following command:

```bash
curl -s -d grant_type=client_credentials -d client_id="my-test-client" -d client_secret="${CLIENT_SECRET}" -d scope=offline_access \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq
```

Example output:

```json
{
  "access_token": "longAsciiStringTruncated",
  "expires_in": 31536000,
  "refresh_expires_in": 0,
  "refresh_token": "anotherLongAsciiStringTruncated",
  "token_type": "bearer",
  "not-before-policy": 0,
  "session_state": "80a96e21-0942-447e-b1d7-21da55d3ff4a",
  "scope": "profile offline_access email"
}
```

Two things are important in the returned response compared to when requesting an "online" token:

- The `refresh_expires_in` value is 0. The refresh token will not expire and become invalid by itself. The refresh tokens can be revoked via administrative action in Keycloak.
- The `refresh_token` value can be used to get a fresh token any time and will be needed if the access token expires \(which will happen in 31,536,000 seconds after the access token was issued\).

## Refresh a long-lived token for a service account

- Replace the `my-test-client` value in the command below with the ID of the target client.
- Replace the `REFRESH_TOKEN` value with the string returned in the previous section.
- The `grant_type` option is set to `refresh_token`.

(`ncn-mw#`) Refresh a long-lived token for a service account with the following command:

```bash
curl -s -d grant_type=refresh_token -d client_id="my-test-client" -d client_secret="${CLIENT_SECRET}" -d refresh_token="REFRESH_TOKEN" \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq
```

Example output:

```json
{
  "access_token": "longAsciiStringTruncated",
  "expires_in": 31536000,
  "refresh_expires_in": 0,
  "refresh_token": "anotherLongAsciiStringTruncated",
  "token_type": "bearer",
  "not-before-policy": 0,
  "session_state": "80a96e21-0942-447e-b1d7-21da55d3ff4a",
  "scope": "profile offline_access email"
}
```
