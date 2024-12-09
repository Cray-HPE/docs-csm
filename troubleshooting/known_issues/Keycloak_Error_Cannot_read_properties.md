# Keycloak Error "Cannot read properties" in Web UI

There is a known error that occurs after upgrading CSM from 1.4 to CSM 1.5.0 and later. This error
is shown when looking at users in Keycloak's web UI. The error occurs due to a change in how the LDAP
configuration is done in earlier versions of Keycloak. This should not occur on fresh installs. The
error occurs when looking at the user lists on Keycloak Web UI, and once looking at the page leaves a
error message on the page stating "Cannot read properties of undefined (reading 0)"

## Fix

To recover from this situation, perform the following procedure.

1. After seeing the error page you will need to refresh the page and ensure you are on the correct realm again

1. Go to the `User Federation` section

1. Click on the LDAP configuration page

1. Click on the switch before `Enabled` to disable the LDAP configuration

1. Click on `Disable` on the pop-up to disable the configuration

1. Click on the switch again to enable the LDAP configuration
