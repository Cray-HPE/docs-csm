# Configure the RSA Plugin in Keycloak

Use Keycloak to configure a plugin that enables RSA token authentication.

- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
- [Verification](#verification)

## Prerequisites

Access to the Keycloak UI is needed.

## Procedure

1. Verify the Shasta domain is being used.

    This is indicated in the dropdown in the upper left of the UI.

1. Click on `Authentication` under the `Configure` header of the navigation area on the left side of the page.

1. Click on the `Flows` tab.

1. Click on the `Browser` flow.

    1. Click the `Actions` dropdown and click on duplicate.

    1. Enter `RSA - Browser` for the `New Name` type.

    1. Click on `Duplicate`

    1. Click the `Add Step` button in the table header.

    1. Search `RSA` and click on the `RSA` then click add.

    1. Update the `Requirement` field.

        Set the table values to the following:

        |Field|Requirement|
        |-----|-----------|
        |`Cookie`|`Alternative`|
        |`Kerberos`|`Disabled`|
        |`Identity Provider Redirector`|`Alternative`|
        |`RSA - Browser Forms`|`REQUIRED`|
        |`Username Password Form`|`REQUIRED`|
        |`RSA - Browser - Conditional OTP`|`CONDITIONAL`|
        |`Condition - User Configured`|`DISABLED`|
        |`OTP Form`|`DISABLED`|
        |`RSA`|`REQUIRED`|

    1. Click the `Gear` icon on the `RSA` line of the table.

    1. Enter the different configuration options:

        | Configuration Field                   | Value                                                        |
        | ------------------------------------- | ------------------------------------------------------------ |
        | `Alias`                                 | Enter the desired alias. For example, `RSA` could be used.   |
        | `RSA URL`                               | The base URL of the RSA API service. For example, `https://rsa.mycompany.com:5555/` |
        | `RSA Verify Endpoint`                   | `/mfa/v1_1/authn/initialize`                                 |
        | `Keycloak Client ID`                    | The authentication agent. For example, `rsa.mycompany.com`. The value is from `Access` \> `Authentication Agents` \> `Manage Existing in the RSA Console`. |
        | `RSA Authentication Manager Client Key` | The key for the RSA API.                                     |

    1. Set the `Shared username` if applicable.

       If the usernames are the same in Keycloak and RSA, then this can be set to `ON`. This means that the browser flow will not ask for the username for the RSA validation.

    1. Click `Save`.

1. Return to the `Flows` tab on the `Authentication` page.

1. Click on the `Direct Grant` flow.

    1. Click the `Actions` dropdown and click on duplicate.

    1. Enter `RSA - CLI` for the `New Name` type.

    1. Click on `Duplicate`.

    1. Click the `Add Step` button in the table header.

    1. Click the `Add Step` button in the table header.

    1. Search `RSA` and click on the `RSA-CLI` then click add.

        Set the table values to the following:

        |Field|Requirement|
        |-----|-----------|
        |`RSA - CLI`|`REQUIRED`|
        |`RSA - CLI Direct Grant - Conditional OTP`|`DISABLED`|

    1. Click `Save`.

1. Return to the `Flows` tab on the `Authentication` page.

    1. Click on the `RSA - Browser` flow.

    1. Click the `Actions` dropdown and click on `Bind flow`.

    1. Choose the `Browser flow` from the dropdown and click `Save`.

    1. Return to the `Flows` tab on the `Authentication` page.

    1. Click on the `RSA - CLI` flow.

    1. Click the `Actions` dropdown and click on `Bind flow`.

    1. Choose the `Direct grant flow` from the dropdown and click `Save`.

1. Switch to the `Relm Settings` under then `Configure` header of the navigation area on the left side of the page.

    1. Go to the `Themes` tab.

    1. Under the `Login theme` dropdown select `shasta-rsa`.

    1. Click on `Save`.

## Verification

After this is set up, verify that it is working:

1. Point a browser at the following URL: `http://auth.cmn.SYSTEM_DOMAIN_NAME/keycloak/realms/shasta/account`

    The browser will be directed to the user login page. The first screen will ask for the username and password in Keycloak. After logging in this way, the next page will ask for the RSA username and token code.

1. (`ncn-mw#`) Get a token using the direct grant flow.

    Replace `USER` with a user in Keycloak, `PWD_NAME` with the user's password, `RSA_USER` with the user in RSA, and `TOKEN_CODE` with the token code:

    ```bash
    curl -i -d grant_type=password -d client_id=shasta -d username=USER \
        -d password=PWD_NAME -d rsa_username=RSA_USER -d rsa_otp=TOKEN_CODE \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token
    ```
