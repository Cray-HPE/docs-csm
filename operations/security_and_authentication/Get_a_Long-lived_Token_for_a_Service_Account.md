## Get a Long-Lived Token for a Service Account

et up a long-lived offline token for a service account using the Keycloak REST API. Keycloak implements the OpenID Connect protocol, so this is a standard procedure for any OpenID Connect server.

Refer to [https://www.keycloak.org/docs/latest/server\_admin/index.html\#\_offline-access](https://www.keycloak.org/docs/latest/server_admin/index.html#_offline-access) for more information.

### Prerequisites

- A client or service account has been created. See [Create a Service Account in Keycloak](Create_a_Service_Account_in_Keycloak.md).
- The CLIENT\_SECRET variable has been set up. See [Retrieve the Client Secret for Service Accounts](Retrieve_the_Client_Secret_for_Service_Accounts.md).

### Procedure

1.  Get a long-lived token for a service account.

    Ensure the following have been done before running the command below:

    - Replace the my-test-client value in the command below with the ID of the target client
    - The scope option should be set to offline\_access
    - The $CLIENT\_SECRET variable is set

    ```bash
    ncn-w001# curl -s -d grant_type=client_credentials -d client_id=my-test-client \
    -d client_secret=$CLIENT_SECRET -d scope=offline_access \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq
    ```

    Example output:

    ```
    {
      "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ6OE5xSFQ5YUZQUjI0a1RSZWtPU0VaX19WY0pJWXUybE5YXzBraVRjTGZZIn0.eyJqdGkiOiI0MjkyYmJlNC0yZTg3LTQ2YjUtYjgwNC02MjU3MWQwZDJhMzQiLCJleHAiOjE2MzI4NTE0OTQsIm5iZiI6MCwiaWF0IjoxNjAxMzE1NDk0LCJpc3MiOiJodHRwczovL2F1dGgudnNoYXN0YS5pby9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbInNoYXN0YSIsImFjY291bnQiXSwic3ViIjoiNTMzMWMzM2ItYTVkNi00ODE3LThhOGEtODE4ZGZlOGZjYTM1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXktdGVzdC1jbGllbnQiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI4MGE5NmUyMS0wOTQyLTQ0N2UtYjFkNy0yMWRhNTVkM2ZmNGEiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJzaGFzdGEiOnsicm9sZXMiOlsiYWRtaW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoicHJvZmlsZSBvZmZsaW5lX2FjY2VzcyBlbWFpbCIsImNsaWVudEhvc3QiOiIxMC40NC4wLjAiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImNsaWVudElkIjoibXktdGVzdC1jbGllbnQiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXktdGVzdC1jbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuNDQuMC4wIn0.jiYELnxC2r5OFu4mJMQIuuH5o9ktupEZNf9k5cT0P58jv0FamE8437Tie3Ix6o8kfwu_z3ASk-0NVZkxk9s28SNtntlYT3kaVUJJHNKLlv24RWq0sxc-oGGBAfYxWF52unr_VUxvJwB7YQ-DyHH71hjMrmJLKQTTT5OYhgiw2oJ5W7jKrqxtFO8wZYyCzCSJkOKIn48Cxd3KBfYyoT53h9yFF5tOONGNFntRbAtPc3tqLYP0ov0FJLzOU98HUUgxObyb_xvBHuexckvwQ2c3ndHJW72PtKkrATpSGsMmByNVbQdgkT50mCYjH5XDqAYD5308qGVQhqSQnd7jl4ghpA",
      "expires_in": 31536000,
      "refresh_expires_in": 0,
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI5ZGNmM2E1Ni0yMmY4LTRlNWYtOWZjNS05ZmEzY2Q3ZDhjYWYifQ.eyJqdGkiOiJhNWYxZmIzNi1mMDM5LTQzNTMtYmQ1Ni05NTUxNjJlNzdlM2IiLCJleHAiOjAsIm5iZiI6MCwiaWF0IjoxNjAxMzE1NDk0LCJpc3MiOiJodHRwczovL2F1dGgudnNoYXN0YS5pby9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjoiaHR0cHM6Ly9hdXRoLnZzaGFzdGEuaW8va2V5Y2xvYWsvcmVhbG1zL3NoYXN0YSIsInN1YiI6IjUzMzFjMzNiLWE1ZDYtNDgxNy04YThhLTgxOGRmZThmY2EzNSIsInR5cCI6Ik9mZmxpbmUiLCJhenAiOiJteS10ZXN0LWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjgwYTk2ZTIxLTA5NDItNDQ3ZS1iMWQ3LTIxZGE1NWQzZmY0YSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsic2hhc3RhIjp7InJvbGVzIjpbImFkbWluIl19LCJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6InByb2ZpbGUgb2ZmbGluZV9hY2Nlc3MgZW1haWwifQ.jxk_81lpFciAuU2z_mFXDWRbImUkNO3HF8Ug958U6xs",
      "token_type": "bearer",
      "not-before-policy": 0,
      "session_state": "80a96e21-0942-447e-b1d7-21da55d3ff4a",
      "scope": "profile offline_access email"
    }
    ```

    Two things are important in the returned response compared to when requesting an "online" token:

    - The `refresh_expires_in` value is 0. The refresh token will not expire and become invalid by itself. The refresh tokens can be revoked via administrative action in Keycloak.
    - The `refresh_token` value can be used to get a fresh token any time and will be needed if the access token expires \(which will happen in 31,536,000 seconds after the access token was issued\).

2.  Refresh the access token.

    Ensure the following have been done before running the command below:

    - Replace the my-test-client value in the command below with the ID of the target client
    - Replace the REFRESH\_TOKEN value with the string returned in the previous step
    - The grant\_type option is set to refresh\_token
    - The $CLIENT\_SECRET variable is set
    
    To refresh the access token, use a grant\_type of refresh\_token and provide the client ID, client secret, and refresh token.

    ```bash
    ncn-w001# curl -s -d grant_type=refresh_token -d client_id=my-test-client \
    -d client_secret=$CLIENT_SECRET -d refresh_token=REFRESH_TOKEN \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq
    ```

    Example output:

    ```
    {
      "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ6OE5xSFQ5YUZQUjI0a1RSZWtPU0VaX19WY0pJWXUybE5YXzBraVRjTGZZIn0.eyJqdGkiOiI0ZGU4MGYwMi05ZjczLTRlMzItODEzMS1mYWQ3ZTA2MjY5NjgiLCJleHAiOjE2MzI4NTI0ODksIm5iZiI6MCwiaWF0IjoxNjAxMzE2NDg5LCJpc3MiOiJodHRwczovL2F1dGgudnNoYXN0YS5pby9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbInNoYXN0YSIsImFjY291bnQiXSwic3ViIjoiNTMzMWMzM2ItYTVkNi00ODE3LThhOGEtODE4ZGZlOGZjYTM1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXktdGVzdC1jbGllbnQiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI4MGE5NmUyMS0wOTQyLTQ0N2UtYjFkNy0yMWRhNTVkM2ZmNGEiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJzaGFzdGEiOnsicm9sZXMiOlsiYWRtaW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoicHJvZmlsZSBvZmZsaW5lX2FjY2VzcyBlbWFpbCIsImNsaWVudEhvc3QiOiIxMC40NC4wLjAiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImNsaWVudElkIjoibXktdGVzdC1jbGllbnQiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXktdGVzdC1jbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuNDQuMC4wIn0.UhFP_EZX6JTvVrqclyaDGbmxg5neKgZ_dn_DE42hR7MF8vToKVMPssKcogoYW5FUH5DpZFeveYj4mAPthblJVxCdW2lbDE_iX6HdvEl7Y64Fna3W3zZZRkkuUNuKhbzXPgfAs8_2tFsBwU6whrkwVetzUMax3_GKNNgKu-u6sPVhK0eJvSQ2Le2j88psT6RA8C2JKv9wmy5az-9vti67OmSDiDWGWsYOCNYPqxoINMC6xHo7LJooplxO2F8Q1rn2fnHUMn84MWyEiQNq1huKx5yN8W-b9_Bkd24ewh8rksPn9CvdCeP5SCVDA-amP0HGR3ojF3uxlzwIJ4WhfMiTCA",
      "expires_in": 31536000,
      "refresh_expires_in": 0,
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI5ZGNmM2E1Ni0yMmY4LTRlNWYtOWZjNS05ZmEzY2Q3ZDhjYWYifQ.eyJqdGkiOiJmOTE1ZWYzYi1mYzY5LTQ5NWYtYTllNC00Mjg3Yjg2YTFmNjYiLCJleHAiOjAsIm5iZiI6MCwiaWF0IjoxNjAxMzE2NDg5LCJpc3MiOiJodHRwczovL2F1dGgudnNoYXN0YS5pby9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjoiaHR0cHM6Ly9hdXRoLnZzaGFzdGEuaW8va2V5Y2xvYWsvcmVhbG1zL3NoYXN0YSIsInN1YiI6IjUzMzFjMzNiLWE1ZDYtNDgxNy04YThhLTgxOGRmZThmY2EzNSIsInR5cCI6Ik9mZmxpbmUiLCJhenAiOiJteS10ZXN0LWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjgwYTk2ZTIxLTA5NDItNDQ3ZS1iMWQ3LTIxZGE1NWQzZmY0YSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsic2hhc3RhIjp7InJvbGVzIjpbImFkbWluIl19LCJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6InByb2ZpbGUgb2ZmbGluZV9hY2Nlc3MgZW1haWwifQ.kT_xiLTFH-jXqdu9pydnr8ddIknC5hGbrAEuwi82iDs",
      "token_type": "bearer",
      "not-before-policy": 0,
      "session_state": "80a96e21-0942-447e-b1d7-21da55d3ff4a",
      "scope": "profile offline_access email"
    }
    ```


