# Change the LDAP Server IP Address for New LDAP Server Content

Delete the old LDAP user federation and create a new one. This procedure should only be done if the LDAP server is being replaced by a different LDAP server that has different contents.

Refer to [Change the LDAP Server IP Address for Existing LDAP Server Content](Change_the_LDAP_Server_IP_Address_for_Existing_LDAP_Server_Content.md) if the new LDAP server content matches the previous LDAP server content.

## Prerequisites

The LDAP server is being replaced by a different LDAP server that has different contents. For example, different users and groups.

## Procedure

1. Remove the LDAP user federation from Keycloak.

    Follow the procedure in [Remove the LDAP User Federation from Keycloak](Remove_the_LDAP_User_Federation_from_Keycloak.md).

1. Re-add the LDAP user federation in Keycloak.

    Follow the procedure in [Add LDAP User Federation](Add_LDAP_User_Federation.md).
