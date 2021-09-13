## Add LDAP User Federation

Add LDAP user federation using the Keycloak localization tool.

### Prerequisites

LDAP user federation is not currently configured in Keycloak. For example, if it was not configured in Keycloak when the system was initially installed or the LDAP user federation was removed.

### Procedure

1.  Update the LDAP settings in the customizations.yaml file.

    The LDAP server CA certificate goes into SealedSecret. Refer to the "Generate Sealed Secrets" header in the [Prepare Site Init](../../install/prepare_site_init.md) procedure for instructions on how to do that.

    1.  Update the customizations.yaml file.

        LDAP connection information is stored in the keycloak-users-localize Secret in the services namespace. In the customizations.yaml file, set the values for the keycloak\_users\_localize keys in the spec.kubernetes.sealed\_secrets field:

        -   The ldap\_connection\_url key is required and is set to an LDAP URL.
        -   The ldap\_bind\_dn and ldap\_bind\_credentials keys are optional.
        -   If the LDAP server allows anonymous searches of users and groups, then these keys must not be set.
        -   If the LDAP server requires authentication. then the bind DN and credentials are set in these keys respectively.
        For example:

        ```bash
        keycloak_users_localize:
                generate:
                  name: keycloak-users-localize
                  data:
                  - type: static
                    args:
                      name: ldap_connection_url
                      value: "ldaps://my_ldap.my_org.test"
                  - type: static
                    args:
                      name: ldap_bind_dn
                      value: "cn=my_admin"
                  - type: static
                    args:
                      name: ldap_bind_credentials
                      value: "my_ldap_admin_password"
        ```

        Other LDAP configuration settings are set in the spec.kubernetes.services.cray-keycloak-users-localize field in the customizations.yaml file. The fields are as follows:

        ```bash
        (
        Notes for the following table: format is

        * <cray-keycloak-users-localize chart option name> : <description>
          - default: <the default value if not overridden in customizations.yaml
          - type: <type that the value in customizations.yaml has to be. e.g., if type is string and a number is entered then you need to quote it>
          - allowed values: <if only certain values are allowed they are listed here>
        )

        * ldapProviderId : The Keycloak provider ID for the component. This must be "ldap"
          - default: ldap
          - type: string
        * ldapFederationName : The name of the LDAP provider in Keycloak. If a provider with this name already exists then this tool will not create a new provider.
          - default: shasta-user-federation-ldap
          - type: string
        * ldapPriority : The priority of this provider when looking up users or adding a user.
          - default: 1
          - type: string
        * ldapEditMode : If you want to be able to create or change users in Keycloak and have them created or modified in the LDAP server, and the LDAP server allows it, then this can be changed.
          - default: READ_ONLY
          - type: string
          - allowed values: READ_ONLY, WRITEABLE, or UNSYNCED
        * ldapSyncRegistrations : If true, then newly created users will be created in the LDAP server.
          - default: false
          - type: string
          - allowed values: true or false
        * ldapVendor: This determines some defaults for what mappers are created by default.
          - default: other
          - type: string
          - allowed values: Active Directory, Red Hat Directory Server, Tivoli, Novell eDirectory, or other
        * ldapUsernameLDAPAttribute: The LDAP attribute to map to the username in Keycloak.
          - default: uid
          - type: string
        * ldapRdnLDAPAttribute: The LDAP attribute being used as the users RDN.
          - default: uid
          - type: string
        * ldapUuidLDAPAttribute: The LDAP attribute being used as a unique ID.
          - default: uid
          - type: string
        * ldapUserObjectClasses: The object classes for user entries.
          - default: posixAccount
          - type: comma-separated string
        * ldapAuthType: Set to "none" if the LDAP server allows anonymous search for users and groups, otherwise set to "simple" to bind.
          - default: none
          - type: string
          - allowed values: none or simple
        * ldapSearchBase: The DN for the base entry to search for users and groups.
          - default: cn=default
          - type: string
        * ldapSearchScope: The search scope to use when searching for users or groups: 2 for subtree, 1 for onelevel
          - default: 2
          - type: string
          - allowed values: 1 or 2
        * ldapUseTruststoreSpi: Determines if the truststore is used to validate the server certificate when connecting to the server.
          - default: ldapsOnly
          - type: string
          - allowed values: ldapsOnly, always, never
        * ldapConnectionPooling: If true then Keycloak will use a connection pool of LDAP connections.
          - default: true
          - type: string
          - allowed values: true or false
        * ldapPagination: Set to true if the LDAP server supports or requires use of the paging extension.
          - default: true
          - type: string
          - allowed values: true or false
        * ldapAllowKerberosAuthentication:
          - Set to true to enable HTTP authentication of users with SPNEGO/Kerberos tokens.
          - default: false
          - type: string
        * ldapBatchSizeForSync: Count of LDAP users to be imported from LDAP to Keycloak in a single transaction.
          - default: 4000
          - type: string
        * ldapFullSyncPeriod: If a positive number, this is the number of seconds between automatic full user synchronization operations; if negative then full user synchronization operations will not be done automatically.
          - default: -1
          - type: string
        * ldapChangedSyncPeriod: f a positive number, this is the number of seconds between automatic changed user synchronization operations; if negative then changed user synchronization operations will not be done automatically.
          - default: -1
          - type: string
        * ldapDebug: Set to true to enable extra logging of LDAP operations.
          - default: true
          - allowed values: true or false
        * ldapUserAttributeMappers: Extra attribute mappers to create so that users have attributes required by Shasta software. The Keycloak attribute that the LDAP attribute maps to will be the same.
          - default: [uidNumber, gidNumber, loginShell, homeDirectory]
          - type: list of strings
        * ldapUserAttributeMappersToRemove: These attribute mappers will be removed, to be used in the case where the default attribute mappers are not appropriate. For example, this could be used to remove the email mapper if email addresses are not unique.
          - default: []
          - type: list of strings
        * ldapGroupNameLDAPAttribute: The LDAP attribute to map to the group name in Keycloak.
          - default: cn
          - type: string
        * ldapGroupObjectClass: The object classes for group entries.
          - default: posixGroup
          - type: comma-separated string
        * ldapPreserveGroupInheritance: Whether group inheritance should be propagated to Keycloak or not.
          - default: false
          - type: string
          - allowed values: true or false
        * ldapMembershipLDAPAttribute: Name of the LDAP attribute that refers to the group members.
          - default: memberUid
          - type: string
        * ldapMembershipAttributeType: If the member attribute contains the DN for the user, then set this to DN. If the member attribute is the UID of the entry then set this to UID.
          - default: UID
          - type: string
          - allowed values: UID or DN
        * ldapMembershipUserLDAPAttribute: If the ldapMembershipAttributeType is UID then this is the LDAP attribute containing the UID value, otherwise this is ignored.
          - default: uid
          - type: string
        * ldapGroupsLDAPFilter: Extra filter to include when searching for group entries. If this is not the empty string the value must start with the ( character and end with ).
          - default: ""
          - type: string
        * ldapUserRolesRetrieveStrategy: Defines how to retrieve groups for a user.
          - default: LOAD_GROUPS_BY_MEMBER_ATTRIBUTE
          - type: string
          - allowed values: LOAD_GROUPS_BY_MEMBER_ATTRIBUTE, GET_GROUPS_FROM_USER_MEMBEROF_ATTRIBUTE, LOAD_GROUPS_BY_MEMBER_ATTRIBUTE_RECURSIVELY
        * ldapMappedGroupAttributes: Attributes of the group that will be added as attributes of the user. Some Shasta REST API operations require the user to have a gidNumber and this adds that attribute from the LDAP group.
          - default: cn,gidNumber,memberUid
          - type: comma-separated string
        * ldapDropNonExistingGroupsDuringSync: If true, groups that are not in LDAP will be deleted when synchronizing.
          - default: false
          - type: string
          - allowed values: true or false
        * ldapDoFullSync: Tells the HPE Cray EX Keycloak localization tool to perform an immediate full user synchronization after configuring the LDAP integration.
          - default: true
          - type: string
        * ldapRoleMapperDn: If this is an empty string then a role mapper is not created, otherwise this the the DN used as the search base to find role entries.
          - default: ""
          - type: string
        * ldapRoleMapperRoleNameLDAPAttribute: The LDAP attribute to map to the role name in Keycloak.
          - default: cn
          - type: string
        * ldapRoleMapperRoleObjectClasses: The object classes for role entries.
          - default: groupOfNames
          - type: string
        * ldapRoleMapperLDAPAttribute: Name of the LDAP attribute that refers to the group members.
          - default: member
          - type: string
        * ldapRoleMapperMemberAttributeType: If the member attribute contains the DN for the user, then set this to DN. If the member attribute is the UID of the entry then set this to UID.
          - default: DN
          - type: string
          - allowed values: UID or DN
        * ldapRoleMapperUserLDAPAttribute: If the ldapRoleMapperMemberAttributeType is UID then this is the LDAP attribute containing the UID value, otherwise this is ignored.
          - default: sAMAccountName
          - type: string
        * ldapRoleMapperRolesLDAPFilter: Extra filter to include when searching for group entries. If this is not the empty string the value must start with the ( character and end with ).
          - default: ""
          - type: string
        * ldapRoleMapperMode: Specifies how to retrieve roles for the user.
          - default: READ_ONLY
          - allowed values: READ_ONLY, LDAP_ONLY, or IMPORT
        * ldapRoleMapperStrategy: Defines how to retrieve roles for a user.
          - default: LOAD_ROLES_BY_MEMBER_ATTRIBUTE
          - type: string
          - allowed values: LOAD_ROLES_BY_MEMBER_ATTRIBUTE, GET_ROLES_FROM_MEMBEROF_ATTRIBUTE, or LOAD_ROLES_BY_MEMBER_ATTRIBUTE_RECURSIVELY
        * ldapRoleMapperMemberOfLDAPAttribute: Only used when ldapRoleMapperStrategy is GET_ROLES_FROM_MEMBEROF_ATTRIBUTE where it is the LDAP attribute in the user entry that contains the roles that the user has.
          - default: memberOf
          - type: string
        * ldapRoleMapperUseRealmRolesMapping: If true then LDAP role mappings will be mapped to realm role mappings in Keycloak, otherwise the LDAP role mappings will be mapped to client role mappings.
          - default: false
          - type: string
          - allowed values: true or false
        * ldapRoleMapperClientId: If ldapRoleMapperUseRealmRolesMapping is false then this is the client ID to apply the roles to.
          - default: shasta
          - type: string
        ```

    2.  Encrypt the static values in the customizations.yaml file after making changes.

        ```bash
        ncn-w001# utils/secrets-seed-customizations.sh customizations.yaml
        ```

2.  Resubmit the Kubernetes Job that runs the Keycloak localization tool.

    1.  Re-apply the cray-keycloak-users-localize Helm chart.

        Re-apply the cray-keycloak-users-localize Helm chart with the updated customizations.yaml file.

        ```bash
        ncn-w001# kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize \
        -ojson | jq '.items[0]' > keycloak-users-localize-job.json 
        
        ncn-w001# cat keycloak-users-localize-job.json | jq 'del(.spec.selector)' | \
        jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -
        job.batch "keycloak-users-localize-1" deleted     
        job.batch/keycloak-users-localize-1 replaced
        ```

    2.  Watch the pod to check the status of the job.

        The pod will go through the normal Kubernetes states. It will stay in a Running state for a while, and then it will go to Completed.

        ```bash
        ncn-w001# kubectl get pods -n services | grep keycloak-users-localize
        keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
        ```

    3.  Check the pod's logs.

        Replace the KEYCLOAK\_POD\_NAME value with the pod name from the previous step.

        ```bash
        ncn-w001# kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
        <logs showing it has updated the "s3" objects and ConfigMaps>
        2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
        ```

3.  Sync the users and groups from Keycloak to the compute nodes.

    1.  Get the crayvcs password for pushing the changes.

        ```bash
        ncn-w001# kubectl get secret -n services vcs-user-credentials \
        --template={{.data.vcs_password}} | base64 --decode
        ```

    2.  Checkout content from the cos-config-management VCS repository.

        ```bash
        ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
        ncn-w001# cd cos-config-management
        ncn-w001# git checkout integration
        ```

    3.  Create the group\_vars/Compute/keycloak.yaml file.

        The file should contain the following values:

        ```bash
        ---
        keycloak_config_computes: True
        ```

    4.  Push the changes to VCS with the crayvcs username.

        ```bash
        ncn-w001# git add group_vars/Compute/keycloak.yaml
        ncn-w001# git commit -m "Configure keycloak on computes"
        ncn-w001# git push origin integration
        ```

    5.  Do a reboot with the Boot Orchestration Service \(BOS\).

        ```bash
        ncn-w001# cray bos session create --template-uuid BOS_TEMPLATE --operation reboot
        ```




