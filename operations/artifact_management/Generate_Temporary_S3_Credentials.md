# Generate Temporary S3 Credentials

 Cray provides a simple token service \(STS\) via the API gateway for administrators to generate temporary Simple Storage Service \(S3\) credentials for use with S3 buckets. Temporary S3 credentials are generated using either cURL or Python.

The generated S3 credentials will expire after one hour.

### Procedure

1.  Retrieve temporary S3 credentials with cURL.

    1.  Obtain a JWT token.

        See [Retrieve an Authentication Token](../security_and_authentication/Retrieve_an_Authentication_Token.md) for more information.

    2.  Generate temporary S3 credentials.

        The following command to call STS assumes the environment variable $TOKEN contains the JWT.

        ```bash
        ncn# curl -X PUT -H "Authorization: Bearer $TOKEN" \
        https://api-gw-service-nmn.local/apis/sts/token
        ```

        Example output:

        ```
        {
          "Credentials": {
            "AccessKeyId": "KtSRFzmAkoDfgCnBLYt",
            "EndpointURL": "http://rgw.local:8080",
            "Expiration": "2019-10-14T15:15:43.480741+00:00",
            "SecretAccessKey": "6CD15EIY6DQOD3DMN0VZPV1XP3W9N4FFPRI0300",
            "SessionToken": "qbwVvv6w1ec/NwI0VzzOXuzFVczjdVICcij0s7kmqKvyZ59RrHJWjLKvmUhGeBATMtkEK72s+qL7Tdn06tPMCQr04MEOpyeUOLmfFyKN3Awm0/7Rlx7rKVaOejpeYaRzO2kWDu3llrpZOONSMPYfck6KjAfvqg/ZJPGEJ5Mzb9YfeSCBq0ghj3G51o9V4DhjjL0YoA/XARMnN0NTHav+OIUHBkXcxZIfT+ti9bSjmz6ExKsJj8zPLvGMK2TIo/Xp"
          }
        }
        ```

2.  Retrieve temporary S3 credentials with Python \(`s3creds.py`\).

    ```bash
    # /usr/bin/env python3
    # s3creds.py - Generate a temporary s3 token from the Cray Simple Token Service
    import os

    import oauthlib.oauth2
    import requests_oauthlib

    realm = 'shasta'
    client_id = 'shasta'
    username = 'testuser'  # Provide a user here
    password = os.environ.get('TESTUSER_PASSWORD')  # Obtain the password from the env, or elsewhere
    token_url = 'https://api-gw-service-nmn.local/keycloak/realms/%s/protocol/openid-connect/token' % realm
    sts_url = 'https://api-gw-service-nmn.local/apis/sts/token'

    # Create an OAuth2Session and request a token
    oauth_client = oauthlib.oauth2.LegacyApplicationClient(client_id=client_id)
    session = requests_oauthlib.OAuth2Session(
        client=oauth_client,
        token_updater=lambda t: None,
        auto_refresh_url=token_url,
        auto_refresh_kwargs={'client_id': client_id}
    )
    session.fetch_token(
        token_url=token_url,
        client_id=client_id,
        username=username,
        password=password
    )

    # Retrieve S3 credentials from STS
    sts_response = session.put(sts_url)
    sts_response.raise_for_status()
    if sts_response.ok:
        creds = sts_response.json()['Credentials']
        creds_kwargs = {
            'aws_access_key_id': creds['AccessKeyId'],
            'aws_secret_access_key': creds['SecretAccessKey'],
            'aws_session_token': creds['SessionToken'],
            'endpoint_url': creds['EndpointURL'],
        }
    ```

    The mapping creds\_kwargs can now be used for further interaction with S3 in Python.

