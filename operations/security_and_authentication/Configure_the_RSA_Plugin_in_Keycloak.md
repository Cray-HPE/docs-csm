# Configure the RSA Plugin in Keycloak

Use Keycloak to configure a plugin that enables RSA token authentication.

### Prerequisites

Access to the Keycloak UI is needed.

### Procedure

1.  Verify the Shasta domain is being used.

    This is indicated in the dropdown in the upper left of the UI.

2.  Click on **Authentication** under the Configure header of the navigation area on the left side of the page.

3.  Click on the **Flows** tab.

4.  Click the dropdown button in the table header and switch to **Browser**.

    1.  Click the **Copy** button in the table header.

    2.  Enter RSA - Browser for the New Name type.

    3.  Click the **Add execution** button in the table header.

    4.  Switch the Provider to RSA and click **Save**.

    5.  Update the Requirement field.

        Set the table values to the following:

        |Field|Requirement|
        |-----|-----------|
        |RSA - Browser Forms|REQUIRED|
        |Username Password Form|REQUIRED|
        |RSA - Browser - Conditional OTP|CONDITIONAL|
        |Condition - User Configured|DISABLED|
        |OTP Form|DISABLED|
        |RSA|REQUIRED|

    6.  Click the **Actions** dropdown on the RSA line of the table, then select **Config**.

    7.  Enter the different configuration options:

        | Configuration Field                   | Value                                                        |
        | ------------------------------------- | ------------------------------------------------------------ |
        | Alias                                 | Enter the desired alias. For example, "RSA" could be used.   |
        | RSA URL                               | The base URL of the RSA API service. For example, `https://rsa.mycompany.com:5555/` |
        | RSA Verify Endpoint                   | `/mfa/v1_1/authn/initialize`                                 |
        | Keycloak Client ID                    | The authentication agent. For example, `rsa.mycompany.com`. The value is from **Access** \> **Authentication Agents** \> **Manage Existing in the RSA Console**. |
        | RSA Authentication Manager Client Key | The key for the RSA API.                                     |

    8. Set the **Shared username** if applicable.

       If the usernames are the same in Keycloak and RSA, then this can be set to ON. This means the browser flow will not ask for the username for the RSA validation.

    9. Click **Save**.

5.  Return to the **Flows** tab on the Authentication page.

6.  Click the dropdown button in the table header and switch to **Direct Grant**.

    1.  Click the **Copy** button in the table header.

    2.  Enter RSA - CLI for the New Name type.

    3.  Click the **Add execution** button in the table header.

    4.  Switch the Provider to RSA - CLI and click **Save**.

    5.  Update the Requirement field.

        Set the table values to the following:

        |Field|Requirement|
        |-----|-----------|
        |RSA - CLI|REQUIRED|
        |RSA - CLI Direct Grant - Conditional OTP|DISABLED|

    6.  Click **Save**.

7.  Switch to the **Bindings** tab in the Authentication page.

    1.  Change Browser Flow to RSA - Browser.

    2.  Change Direct Grant Flow to RSA - CLI.

    3.  Click **Save**.


Here are a couple of things to try after this is set up to verify that it is working:

-   Point a browser at the following URL:

    ```screen
    http://auth.SYSTEM_DOMAIN_NAME/keycloak/realms/shasta/account
    ```

    The browser will be directed to the user login page. The first screen will ask for the username and password in Keycloak. After logging in this way, the next page will ask for the RSA username and token code.

-   Get a token using the direct grant flow.

    Run the following cURL command from `ncn-w001`. Replace USER with a user in Keycloak, PWD\_NAME with the user's password, RSA\_USER with the user in RSA, and TOKEN\_CODE with the token code:

    ```screen
    ncn-w001# curl -i -d grant_type=password -d client_id=shasta -d username=USER \
    -d password=PWD_NAME -d rsa_username=RSA_USER -d rsa_otp=TOKEN_CODE \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token
    ```

