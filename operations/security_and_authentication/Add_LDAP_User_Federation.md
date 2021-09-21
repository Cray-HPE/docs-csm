

## Add LDAP User Federation

Add LDAP user federation using the Keycloak localization tool.


### Prerequisites

LDAP user federation is not currently configured in Keycloak. For example, if it was not configured in Keycloak when the system was initially installed or the LDAP user federation was removed.


### Procedure

1. Prepare to customize the customizations.yaml file.

   If the customizations.yaml file is managed in an external Git repository (as recommended), then clone a local working tree. Replace the `<URL>` value in the following command before running it.

   ```bash
   ncn-m001# git clone <URL> /root/site-init
   ncn-m001# cd /root/site-init
   ```

   If there is not a backup of site-init, perform the following steps to create a new one using the values stored in the Kubernetes cluster.

   1. Create a new site-init directory using from the CSM tarball.

      Determine the location of the initial install tarball and set ${CSM_DISTDIR} accordingly.

      ```bash
      ncn-m001# cp -r ${CSM_DISTDIR}/shasta-cfg /root/site-init
      ncn-m001# cd /root/site-init
      ```
  
   2. Extract customizations.yaml from the site-init secret.

      ```bash
      ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

   3. Extract the certificate and key used to create the sealed secrets.

      ```bash
      ncn-m001# mkdir certs
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

  > **NOTE:** All subsequent steps of this procedure should be performed within the `/root/site-init` directory created in this step.

2. Repopulate the keycloak_users_localize and cray-keycloak Sealed Secrets in the customizations.yaml file with the desired configuration.

   1. Check to see if the `generate:` sections of the Sealed Secrets have been populated with encrypted Sealed Secrets already:
      
      ```bash
      ncn-m001# yq read ./customizations.yaml spec.kubernetes.sealed_secrets.keycloak_users_localize
      apiVersion: bitnami.com/v1alpha1
      kind: SealedSecret
      metadata:
        annotations:
          sealedsecrets.bitnami.com/cluster-wide: "true"
        creationTimestamp: null
        name: keycloak-users-localize
      spec:
        encryptedData:
          ldap_connection_url: AgAmdO19GaLs3Yr9apnJ/JDuQS+6yMC+LlZrPO8g+9UvF2+0X1TifH/bPb0Dw4VMN/2MURx/vvwJE2DTz9yajuW3YJEdwD4o6z/OZ/qLDxu2u+HZSwRnWLWK6ROTBGMP7r0zOdQIDoeeAZw03+d4/UmiBlTlJhl+DJzcS8VbfJV+neNcZ0p5zcM7skqI5NL4teNItHoeuITC2QQ+TRQc/XOrkj3JxvrzFEtEstJz8fXOUXBOwakhRRzUZl9aAYcT6raK3mPQDg14AkM4JVCeku+h6O4OOoOIygC8FzfrXy+LWE93UZjw/0ZM+c6bqOLd7odGto5EylLaV7HS9V8trUPfKExBbYqoRzm+IU9eG3k8Gr7ijT9hRhr1wiV73DFy5NnNB0uAjFClnPXbqntbnSScLxHgFqrnitKM19RzcuHFaZ0Hq0S0VPO8az8BL7jiCkhlxqT0WN6I5RerHPt0PocikKJ/S58a2dc8uGwMgyAPCcJwNXnh7qoA3pgL72kD292ReCYUz6XR51XQAaW1S5O/OaI3VKCCHZAw+qCgW3tCraL3mjzuTYSQQQsDFicxcgQZVz26S/9ATW+3g8btOZlsJ8aA9zpSGAf+uo2N/OKDCmU60fxFTvddcYDlWZ9ZXM1q9lnDTzz1T+QMCZ/f+c2El4CgNvrKJvLueduuagGNfrYoVgGoQ76e/WVi866d1a0=
        template:
          metadata:
            annotations:
              sealedsecrets.bitnami.com/cluster-wide: "true"
            creationTimestamp: null
            name: keycloak-users-localize
      generate:
        data: {}
      ```

      If these sections were populated during the install, proceed to the next sub-step to 
      remove the existing keycloak_users_localize and cray-keycloak Sealed Secrets
      from customizations.yaml, and then add the `generate:` sections back in, 
      populated with the desired configuration.

   2. Update the LDAP settings with the desired configuration.
      
      LDAP connection information is stored in the keycloak-users-localize Secret in the services
      namespace in the customizations.yaml file.

      -   The ldap_connection_url key is required and is set to an LDAP URL.
      -   The ldap_bind_dn and ldap_bind_credentials keys are optional.
      -   If the LDAP server requires authentication. then the bind DN and credentials are set in these keys respectively.
      
      For example:

      ```bash
            cray-keycloak:
                generate:
                  name: keycloak-certs
                  data:
                    - type: static_b64
                      args:
                        name: certs.jks
                        value: /u3+7QAAAAIAAAAA5yXvSDt11bGXyBA9M2iy0/5i1Tg=
        
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

      Other LDAP configuration settings are set in the spec.kubernetes.services.cray-keycloak-users-localize field in the customizations.yaml file. 
        
      The fields are as follows:

      ```
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

3. (Optional) Add the LDAP CA certificate in the certs.jks section of customizations.yaml.
   
   If LDAP requires TLS (recommended), update the `cray-keycloak` Sealed 
   Secret value by supplying a base64 encoded Java KeyStore (JKS) that
   contains the CA certificate that signed the LDAP server's host key. The
   password for the JKS file must be `password`.
   
   Administrators may use the `keytool` command from the `openjdk:11-jre-slim` container image
   packaged with CSM to create a JKS file that includes a PEM-encoded
   CA certificate to verify the LDAP host(s).

   1. Load the `openjdk` container image.

        > **NOTE:** Requires a properly configured Docker or Podman environment.

        ```bash
        ncn-m001# ${CSM_DISTDIR}/hack/load-container-image.sh dtr.dev.cray.com/library/openjdk:11-jre-slim
        ```

   2. Create (or update) `cert.jks` with the PEM-encoded CA certificate for an LDAP host.

        > **IMPORTANT:** Replace `<ca-cert.pem>` and `<alias>` before running the command.

        ```bash
        ncn-m001# podman run --rm -v "$(pwd):/data" dtr.dev.cray.com/library/openjdk:11-jre-slim keytool \
        -importcert -trustcacerts -file /data/<ca-cert.pem> -alias <alias> -keystore /data/certs.jks \
        -storepass password -noprompt
        ```
   
   3. Set variables for the LDAP server.

        In the following example, the LDAP server has the hostname `dcldap2.us.cray.com` and is using the port 636.

        ```bash
        ncn-m001# export LDAP=dcldap2.us.cray.com
        ncn-m001# export PORT=636
        ```

   4. Get the issuer certificate for the LDAP server at port 636. Use `openssl s_client` to connect
      and show the certificate chain returned by the LDAP host.

        ```bash
        ncn-m001# openssl s_client -showcerts -connect $LDAP:${PORT} </dev/null
        ```

        Either manually extract (cut/paste) the issuer's
        certificate into `cacert.pem`, or try the following commands to
        create it automatically.

        > **NOTE:** The following commands were verified using OpenSSL
        > version 1.1.1d and use the `-nameopt RFC2253` option to ensure
        > consistent formatting of distinguished names (DNs).
        > Unfortunately, older versions of OpenSSL may not support
        > `-nameopt` on the `s_client` command or may use a different
        > default format. As a result, mileage may vary; however,
        > administrators should be able to extract the issuer certificate manually
        > from the output of the above `openssl s_client` example if the
        > following commands are unsuccessful.

        Observe the issuer's DN. 
        
        For example:

        ```bash
        ncn-m001# openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:${PORT} </dev/null 2>/dev/null | grep issuer= | sed -e 's/^issuer=//'

        emailAddress=dcops@hpe.com,CN=Data Center,OU=HPC/MCS,O=HPE,ST=WI,C=US
        ```

        Then, extract the issuer's certificate using the `awk` command:

        > **NOTE:** The issuer DN is properly escaped as part of the
        > `awk` pattern below. If the value being used is
        > different, be sure to escape it properly!

        ```bash
        ncn-m001# openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:${PORT} </dev/null 2>/dev/null | \
                awk '/s:emailAddress=dcops@hpe.com,CN=Data Center,OU=HPC\/MCS,O=HPE,ST=WI,C=US/,/END CERTIFICATE/' | \
                awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > cacert.pem
        ```

    5. Verify the issuer's certificate was properly extracted and saved in `cacert.pem`.

        ```bash
        ncn-m001# cat cacert.pem
        ```

        Expected output looks similar to the following:

        ```
        -----BEGIN CERTIFICATE-----
        MIIDvTCCAqWgAwIBAgIUYxrG/PrMcmIzDuJ+U1Gh8hpsU8cwDQYJKoZIhvcNAQEL
        BQAwbjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldJMQwwCgYDVQQKDANIUEUxEDAO
        BgNVBAsMB0hQQy9NQ1MxFDASBgNVBAMMC0RhdGEgQ2VudGVyMRwwGgYJKoZIhvcN
        AQkBFg1kY29wc0BocGUuY29tMB4XDTIwMTEyNDIwMzM0MVoXDTMwMTEyMjIwMzM0
        MVowbjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldJMQwwCgYDVQQKDANIUEUxEDAO
        BgNVBAsMB0hQQy9NQ1MxFDASBgNVBAMMC0RhdGEgQ2VudGVyMRwwGgYJKoZIhvcN
        AQkBFg1kY29wc0BocGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
        AQEAuBIZkKitHHVQHymtaQt4D8ZhG4qNJ0cTsLhODPMtVtBjPZp59e+PWzbc9Rj5
        +wfjLGteK6/fNJsJctWlS/ar4jw/xBIPMk5pg0dnkMT2s7lkSCmyd9Uib7u6y6E8
        yeGoGcb7I+4ZI+E3FQV7zPact6b17xmajNyKrzhBGEjYucYJUL5iTgZ6a7HOZU2O
        aQSXe7ctiHBxe7p7RhHCuKRrqJnxoohakloKwgHHzDLFQzX/5ADp1hdJcduWpaXY
        RMBu6b1mhmwo5vmc+fDnfUpl5/X4i109r9VN7JC7DQ5+JX8u9SHDGLggBWkrhpvl
        bNXMVCnwnSFfb/rnmGO7rdJSpwIDAQABo1MwUTAdBgNVHQ4EFgQUVg3VYExUAdn2
        WE3e8Xc8HONy/+4wHwYDVR0jBBgwFoAUVg3VYExUAdn2WE3e8Xc8HONy/+4wDwYD
        VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAWLDQLB6rrmK+gwUY+4B7
        0USbQK0JkLWuc0tCfjTxNQTzFb75PeH+GH21QsjUI8VC6QOAAJ4uzIEV85VpOQPp
        qjz+LI/Ej1xXfz5ostZQu9rCMnPtVu7JT0B+NV7HvgqidTfa2M2dw9yUYS2surZO
        8S0Dq3Bi6IEhtGU3T8ZpbAmAp+nNsaJWdUNjD4ECO5rAkyA/Vu+WyMz6F3ZDBmRr
        ipWM1B16vx8rSpQpygY+FNX4e1RqslKhoyuzXfUGzyXux5yhs/ufOaqORCw3rJIx
        v4sTWGsSBLXDsFM3lBgljSAHfmDuKdO+Qv7EqGzCRMpgSciZihnbQoRrPZkOHUxr
        NA==
        -----END CERTIFICATE-----
        ```

    6. Create `certs.jks`.

        ```bash
        ncn-m001# podman run --rm -v "$(pwd):/data" dtr.dev.cray.com/library/openjdk:11-jre-slim keytool -importcert \
        -trustcacerts -file /data/cacert.pem -alias cray-data-center-ca -keystore /data/certs.jks \
        -storepass password -noprompt
        ```

    7. Create `certs.jks.b64` by base-64 encoding `certs.jks`.

        ```bash
        ncn-m001# base64 certs.jks > certs.jks.b64
        ```

    8.  Inject and encrypt `certs.jks.b64` into `customizations.yaml`.

        ```bash
        ncn-m001# cat <<EOF | yq w - 'data."certs.jks"' "$(<certs.jks.b64)" | \
        yq r -j - | /root/site-init/utils/secrets-encrypt.sh | \
        yq w -f - -i /root/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray-keycloak'
        {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
            "name": "keycloak-certs",
            "namespace": "services",
            "creationTimestamp": null
            },
            "data": {}
        }
        EOF
        ```

4. Prepare to generate Sealed Secrets.
   
   Secrets are stored in customizations.yaml as `SealedSecret` resources 
   (encrypted secrets), which are deployed by specific charts and decrypted by the
   Sealed Secrets operator. But first, those Secrets must be seeded, generated, and
   encrypted.
   
   1. Load the `zeromq` container image required by Sealed Secret Generators.

      > **NOTE:** A properly configured Docker or Podman environment is required.

      ```bash
      ncn-m001# ${CSM_DISTDIR}/hack/load-container-image.sh dtr.dev.cray.com/zeromq/zeromq:v4.0.5
      ```

      Expected output looks similar to the following:

      ```bash
      + command -v podman
      + for conf in graphRoot graphDriverName runRoot
      ++ echo graphRoot
      ++ tr '[:upper:]' '[:lower:]'
      + conf_lc=graphroot
      ++ podman info -f json
      ++ jq -r .store.graphRoot
      + conf_val=/var/lib/containers/storage
      + '[' /var/lib/containers/storage == null ']'
      + declare graphroot=/var/lib/containers/storage
      + for conf in graphRoot graphDriverName runRoot
      ++ echo graphDriverName
      ++ tr '[:upper:]' '[:lower:]'
      + conf_lc=graphdrivername
      ++ podman info -f json
      ++ jq -r .store.graphDriverName
      + conf_val=vfs
      + '[' vfs == null ']'
      + declare graphdrivername=vfs
      + for conf in graphRoot graphDriverName runRoot
      ++ echo runRoot
      ++ tr '[:upper:]' '[:lower:]'
      + conf_lc=runroot
      ++ podman info -f json
      ++ jq -r .store.runRoot
      + conf_val=/var/run/containers/storage
      + '[' /var/run/containers/storage == null ']'
      + declare runroot=/var/run/containers/storage
      ++ realpath /var/lib/containers/storage
      + graphroot=/var/lib/containers/storage
      ++ realpath /var/run/containers/storage
      + runroot=/run/containers/storage
      + mounts='-v /var/lib/containers/storage:/var/lib/containers/storage'
      + transport=containers-storage
      + run_opts='--rm --network none --privileged --ulimit=host'
      + skopeo_dest='containers-storage:[vfs@/var/lib/containers/storage+/run/containers/storage]dtr.dev.cray.com/zeromq/zeromq:v4.0.5'
      ++ dirname ./hack/load-container-image.sh
      + ROOTDIR=./hack/..
      + source ./hack/../lib/install.sh
      ++ : https://packages.local
      ++ : registry.local
      ++ : ./hack/..
      ++ [[ no == \y\e\s ]]
      ++ requires find podman realpath
      ++ [[ 3 -gt 0 ]]
      ++ command -v find
      ++ shift
      ++ [[ 2 -gt 0 ]]
      ++ command -v podman
      ++ shift
      ++ [[ 1 -gt 0 ]]
      ++ command -v realpath
      ++ shift
      ++ [[ 0 -gt 0 ]]
      ++ vendor_images=()
      ++ load-vendor-image ./hack/../vendor/skopeo.tar
      ++ set -o pipefail
      ++ podman load -q -i ./hack/../vendor/skopeo.tar
      ++ sed -e 's/^.*: //'
      + SKOPEO_IMAGE=docker.io/library/skopeo:csm-1.0.0-beta.76
      ++ realpath ./hack/../docker
      + podman run --rm --network none --privileged --ulimit=host -v /var/lib/containers/storage:/var/lib/containers/storage -v /mnt/pitdata/csm-1.0.0-beta.76/docker:/image:ro docker.io/library/skopeo:csm-1.0.0-beta.76 copy dir:/image/dtr.dev.cray.com/zeromq/zeromq:v4.0.5 'containers-storage:[vfs@/var/lib/containers/storage+/run/containers/storage]dtr.dev.cray.com/zeromq/zeromq:v4.0.5'
      Getting image source signatures
      Copying blob sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4
      Copying blob sha256:3ce16febdf7832163becc8fe98757c0a7149617b8cda952459b2a1227f7eda21
      Copying blob sha256:392d00c08b0fe0c235ef1718d7272970f6d384fc0859d927951adbaee868a06a
      Copying blob sha256:c62605fa7f3e9b00d940258c4705a51750965de5ed5f2f6528645b50cfd6e31a
      Copying blob sha256:2bddd7683cba11ada1f657f7f8a2557b638582a2b39ebd2696e6dc43cae08ba7
      Copying blob sha256:404ed4835f8dfa88e541a546951e76e024c5566e0202367cd659761311b8c864
      Copying blob sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4
      Copying blob sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4
      Copying blob sha256:9ed53610e4ed4d4d58f0c9119c019809bc3b51c90b494fa6440ac27115293b33
      Copying blob sha256:ab88839926fbac86516f78ab0687febd1dd9882b9f56cc8ea2d1c4c1f31024c0
      Copying blob sha256:cdf2fc9fdc1935aae9386bffa518fb6ba366ca9f1bbf9603b5b78f50841cec39
      Copying blob sha256:f9520ccb0f8364dd282cb916f8f8e1a1d508547539cd39750b0585a41e642c3c
      Copying blob sha256:8bc0759c6bf76ffb0fea353dcc02d92ad805aa79758f9357bd40fbc492cbab1b
      Copying blob sha256:e132f5c26e132cfb044ee1209526c2e54ed8569e580562c3dd371059abbc3e32
      Copying blob sha256:d1d7f70258fff8ddb78e13a78f2285f8b9fead38eb287d7779ee9ee70de22972
      Copying config sha256:1648d2dfc45f081dde3e9bead9864c54d136be929ec1e272bb144e9034505574
      Writing manifest to image destination
      Storing signatures
      ```
    
   2. Verify the load worked.

      ```bash
      ncn-m001# podman images | grep zeromq
      dtr.dev.cray.com/zeromq/zeromq         v4.0.5           1648d2dfc45f  6 years ago    462 MB
      ```

   3. Re-encrypt the existing secrets.

      ```bash
      ncn-m001# ./utils/secrets-reencrypt.sh customizations.yaml ./certs/sealed_secrets.key ./certs/sealed_secrets.crt
      ```
      
5. Encrypt the static values in the customizations.yaml file after making changes.

   The following command must be run within the site-init directory.

   ```bash
   ncn-m001# ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

   Expected output looks similar to:

      ```bash
      Creating Sealed Secret keycloak-certs
      Generating type static_b64...
      Creating Sealed Secret keycloak-master-admin-auth
      Generating type static...
      Generating type static...
      Generating type randstr...
      Generating type static...
      Creating Sealed Secret cray_reds_credentials
      Generating type static...
      Generating type static...
      Creating Sealed Secret cray_meds_credentials
      Generating type static...
      Creating Sealed Secret cray_hms_rts_credentials
      Generating type static...
      Generating type static...
      Creating Sealed Secret vcs-user-credentials
      Generating type randstr...
      Generating type static...
      Creating Sealed Secret generated-platform-ca-1
      Generating type platform_ca...
      Creating Sealed Secret pals-config
      Generating type zmq_curve...
      Generating type zmq_curve...
      Creating Sealed Secret munge-secret
      Generating type randstr...
      Creating Sealed Secret slurmdb-secret
      Generating type static...
      Generating type static...
      Generating type randstr...
      Generating type randstr...
      Creating Sealed Secret keycloak-users-localize
      Generating type static...
      ```

6. Decrypt the Sealed Secret to verify it was generated correctly.
   
   ```bash
   ncn-m001# ./utils/secrets-decrypt.sh keycloak_users_localize | jq -r '.data.ldap_connection_url' | base64 --decode
   ldaps://my_ldap.my_org.test
   ```

7. Re-apply the cray-keycloak Helm chart with the updated customizations.yaml file.
   
    1. Retrieve the current platform.yaml manifest.
       
       ```bash
       ncn-m001# kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > platform.yaml
       ```

    2. Remove all charts from the platform.yaml except for cray-keycloak.
   
       Edit the platform.yaml file and delete all sections starting with `-name: <chart_name>`, except for the cray-keycloak section.

       Then, change the name of the manifest being deployed from platform to cray-keycloak:
      
       ```bash
       ncn-m001:# sed -i 's/name: platform/name: cray-keycloak/' platform.yaml
       ```

    3. Populate the platform manifest with data from the customizations.yaml file.
       
       ```bash
       ncn-m001# manifestgen -i platform.yaml -c customizations.yaml -o new-platform.yaml
       ```

    4. Re-apply the platform manifest with the updated cray-keycloak chart.
   
       ```bash
       ncn-m001# loftsman ship --manifest-path ./new-platform.yaml --charts-repo https://packages.local/repository/charts
       ```

    5. Wait for the keycloak-certs secret to reflect the new `cert.jks`.
       
       Run the following command until there is a non-empty value in the secret (this can take a minute or two):
       
       ```bash
       ncn-m001# kubectl get secret -n services keycloak-certs -o yaml | grep certs.jks.b64
         certs.jks.b64: <REDACTED>
       ```

    6. Restart the `cray-keycloak-[012]` pods.

       ```bash
       ncn-m001# kubectl rollout restart statefulset -n services cray-keycloak
       ```

    7. Wait for the Keycloak pods to restart before moving on to the next step.
       
       Once the `cray-keycloak-[012]` pods have restarted, proceed to the next step.

       ```bash
       ncn-m001# kubectl get po -n services | grep cray-keycloak
       ```

8. Re-apply the cray-keycloak-users-localize Helm chart with the updated customizations.yaml file.

    1.  Determine the cray-keycloak-users-localize chart version that is currently deployed.

        ```bash
        ncn-m001# helm ls -A -a | grep cray-keycloak-users-localize
        ```

    2.  Create a manifest file that will be used to reapply the same chart version.

        ```bash
        ncn-m001# cat << EOF > ./cray-keycloak-users-localize-manifest.yaml
        apiVersion: manifests/v1beta1
        metadata:
          name: reapply-cray-keycloak-users-localize
        spec:
          charts:
            - name: cray-keycloak-users-localize
              namespace: services
              version: 0.12.2
        EOF
        ```

    3. Uninstall the current cray-keycloak-users-localize chart.

        ```bash
        ncn-m001# helm del cray-keycloak-users-localize -n services
        ```

    4. Populate the deployment manifest with data from the customizations.yaml file.

        ```bash
        ncn-m001# manifestgen -i cray-keycloak-users-localize-manifest.yaml -c customizations.yaml -o deploy.yaml
        ```
   
    5. Reapply the cray-keycloak-users-localize chart.

        ```bash
        ncn-m001# loftsman ship --manifest-path ./deploy.yaml \
        --charts-repo https://packages.local/repository/charts
        ```

    6. Watch the pod to check the status of the job.

        The pod will go through the normal Kubernetes states. It will stay in a Running state for a while, and then it will go to Completed.

        ```bash
        ncn-m001# kubectl get pods -n services | grep keycloak-users-localize
        keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
        ```

    7.  Check the pod's logs.

        Replace the `KEYCLOAK_POD_NAME` value with the pod name from the previous step.

        ```bash
        ncn-m001# kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
        <logs showing it has updated the "s3" objects and ConfigMaps>
        2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
        ```

9.  Sync the users and groups from Keycloak to the compute nodes.

    1. Get the crayvcs password for pushing the changes.

        ```bash
        ncn-m001# kubectl get secret -n services vcs-user-credentials \
        --template={{.data.vcs_password}} | base64 --decode
        ```

    2. Checkout content from the cos-config-management VCS repository.

        ```bash
        ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
        ncn-m001# cd cos-config-management
        ncn-m001# git checkout integration
        ```

    3. Create the group_vars/Compute/keycloak.yaml file.

        The file should contain the following values:

        ```bash
        ---
        keycloak_config_computes: True
        ```

    4. Push the changes to VCS with the crayvcs username.

        ```bash
        ncn-m001# git add group_vars/Compute/keycloak.yaml
        ncn-m001# git commit -m "Configure keycloak on computes"
        ncn-m001# git push origin integration
        ```
    
    5. Update the Configuration Framework Service (CFS) configuration.

        ```bash
        ncn-m001# cray cfs configurations update configurations-example \
        --file ./configurations-example.json --format json
        {
          "lastUpdated": "2021-07-28T03:26:30:37Z",
          "layers": [
             {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
              "commit": "<git commit id>",
              "name": "configurations-layer-example-1",
              "playbook": "site.yml"
             }
           ],
           "name": "configurations-example"
        }
        ```

    6. Reboot with the Boot Orchestration Service (BOS).

        ```bash
        ncn-m001# cray bos session create --template-uuid BOS_TEMPLATE --operation reboot
        ```

10. Validate that LDAP integration was added successfully.
   
    1. Retrieve the admin password for Keycloak.

       ```bash
       ncn-m001: # kubectl get secrets -n services keycloak-master-admin-auth -ojsonpath='{.data.password}' | base64 -d
       ```
   
    2. Login to the Keycloak UI using the `admin` user and the password obtained in the previous step.
      
       The Keycloak UI URL is typically similar to the following:
      
       ```
       https://auth.<system_name>/keycloak
       ```

    3. Click on the "Users" tab in the navigation pane on the left.

    4. Click on the "View all users" button and verify the LDAP users appear in the table.

    5. Verify a token can be retrieved from Keycloak using an LDAP user/password.

       In the example below, replace myuser, mypass, and shasta in the cURL command with
       site-specific values. The shasta client is created during the SMS install process.

       In the following example, the `python -mjson.tool` is not required; it is simply used to
       format the output for readability.

       ```bash
       ncn-w001# curl -s \
         -d grant_type=password \
         -d client_id=shasta \
         -d username=myuser \
         -d password=mypass \
         https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
         python -mjson.tool
       ```

       Expected output:

       ```bash
       {
           "access_token": "ey...IA", <<-- NOTE this value, used in the following step
           "expires_in": 300,
           "not-before-policy": 0,
           "refresh_expires_in": 1800,
           "refresh_token": "ey...qg",
           "scope": "profile email",
           "session_state": "10c7d2f7-8921-4652-ad1e-10138ec6fbc3",
           "token_type": "bearer"
       }
       ```

    6. Validate that the `access_token` looks correct.

       Copy the `access_token` from the previous step and open a browser window.
       Navigate to http://jwt.io, and paste the token in the "Encoded" field.

       Verify the `preferred_username` is the expected LDAP user and the
       role is `admin` (or other role based on the user).
  


