# Configure Keycloak for LDAP/AD authentication

Keycloak enables users to be in an LDAP or Active Directory \(AD\) server. This allows users to get their tokens using their regular username and password, and use those tokens to perform operations on the system's REST API.

Configuring Keycloak can be done using the admin GUI or through Keycloak's web API.

For more information on setting up LDAP federation, see the Keycloak administrative documentation in a section titled [https://www.keycloak.org/docs/latest/server\_admin/index.html\#\_ldap](https://www.keycloak.org/docs/latest/server_admin/index.html#_ldap).

Users are expected to have the following attributes:

-   uidNumber
-   gidNumber
-   homeDirectory
-   loginShell

These attributes are added to the users by adding a "User Attribute Mapper" to the LDAP User Federation object. For each of these, there should be a User Attribute Mapper that maps the "LDAP Attribute" in the LDAP Directory to the "User Model Attribute," which will be uidNumber, gidNumber, and more.

The `shasta` client that is created during the install maps these specific user model attributes into the JWT token so that it is available to the REST APIs.

