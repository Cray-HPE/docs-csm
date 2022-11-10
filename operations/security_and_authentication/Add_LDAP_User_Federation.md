# Add LDAP User Federation

Add LDAP user federation using the Keycloak localization tool.

## Prerequisites

LDAP user federation is not currently configured in Keycloak. For example, if it was not configured in Keycloak when the system was initially installed or the LDAP user federation was removed.

## Procedure

1. Prepare to edit the `customizations.yaml` file.

   If the `customizations.yaml` file is managed in an external Git repository (as recommended), then clone a local working tree. Replace the `<URL>` value in the following command before running it.

   ```bash
   git clone <URL> /root/site-init
   cd /root/site-init
   ```

   If there is not a backup of `site-init`, perform the following steps to create a new one using the values stored in the Kubernetes cluster.

   1. Set the `CSM_DISTDIR` variable to the path to the unpacked CSM release tarball.

      See [Download and extract CSM product release](../../update_product_stream/README.md#download-and-extract-csm-product-release).

   1. Create a new `site-init` directory using the CSM tarball.

      ```bash
      cp -r ${CSM_DISTDIR}/shasta-cfg/* /root/site-init
      cd /root/site-init
      ```

   1. Extract `customizations.yaml` from the `site-init` Kubernetes secret.

      ```bash
      kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

   1. Extract the certificate and key used to create the sealed secrets.

      ```bash
      kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

   > **`NOTE`** All subsequent steps of this procedure should be performed within the `/root/site-init` directory created in this step.

1. Repopulate the `keycloak_users_localize` and `cray-keycloak` sealed secrets in the `customizations.yaml` file with the desired configuration.

   Update the LDAP settings with the desired configuration. LDAP connection information
   is stored in the `keycloak-users-localize` secret in the `customizations.yaml` file.

   - The `ldap_connection_url` key is required and is set to an LDAP URL.
   - The `ldap_bind_dn` and `ldap_bind_credentials` keys are optional.
      - If the LDAP server requires authentication. then the bind DN and credentials are set in these keys respectively.

   For example:

   ```yaml
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

   The example above puts an empty `certs.jks` in the `cray-keycloak` sealed secret.
   The next step will generate `certs.jks`.

   Other LDAP configuration settings are set in the `spec.kubernetes.services.cray-keycloak-users-localize` field in the `customizations.yaml` file.

   A list of the fields follows. The format of the entries in this list is:

   ```yaml
     * <cray-keycloak-users-localize chart option name> : <description>
       - default: <the default value if not overridden in customizations.yaml>
       - type: <type that the value in customizations.yaml has to be. e.g., if type is string and a number is entered then you need to quote it>
       - allowed values: <if only certain values are allowed they are listed here>
   ```

   The fields are:

   ```yaml
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
       - allowed values: `READ_ONLY`, `WRITEABLE`, or `UNSYNCED`
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
     * ldapRoleMapperDn: If this is an empty string then a role mapper is not created, otherwise this the DN used as the search base to find role entries.
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

1. (Optional) Add the LDAP CA certificate in the `certs.jks` section of `customizations.yaml`.

   If LDAP requires TLS (recommended), update the `cray-keycloak` sealed
   secret value by supplying a base-64-encoded Java KeyStore (JKS) that
   contains the CA certificate that signed with the LDAP server's host key. The
   password for the JKS file must be `password`.

   Administrators may use the `keytool` command from the `openjdk:11-jre-slim` container image
   packaged with CSM to create a JKS file that includes a PEM-encoded
   CA certificate to verify the LDAP host(s).

   1. Load the `openjdk` container image.

      > **`NOTE`** Requires a properly configured Docker or Podman environment.

      ```bash
      ${CSM_DISTDIR}/hack/load-container-image.sh artifactory.algol60.net/csm-docker/stable/docker.io/library/openjdk:11-jre-slim
      ```

      **Troubleshooting:**

      - If the output shows the `skopeo.tar` file cannot be found, then ensure that the `$CSM_DISTDIR` directory looks contains the `artifactory.algol60.net` directory which includes the originally installed docker images.

         The following is an example of the skopeo.tar file not being found:

         ```text
         ++ podman load -q -i ./hack/../vendor/skopeo.tar
         ++ sed -e 's/^.*: //'
         + SKOPEO_IMAGE=
         ```

      - If the following overlay error is returned, it could be caused by an earlier podman invocation using a different configuration:

         ```text
         "ERRO[0000] [graphdriver] prior storage driver overlay failed: 'overlay' is not supported over overlayfs, a mount_program is required: backing file system is unsupported for this graph driver"
         ```

         To recover podman, move the overlay directories to a backup folder as follows:

         ```bash
         mkdir /var/lib/containers/storage/backup
         mv /var/lib/containers/storage/overlay* /var/lib/containers/storage/backup
         ```

         This should allow `load-container-images.sh` to succeed.

   1. Create (or update) `cert.jks` with the PEM-encoded CA certificate for an LDAP host.

      > **IMPORTANT:** Replace `<ca-cert.pem>` and `<alias>` before running the command.

      ```bash
      podman run --rm -v "$(pwd):/data" artifactory.algol60.net/csm-docker/stable/docker.io/library/openjdk:11-jre-slim keytool \
         -importcert -trustcacerts -file /data/<ca-cert.pem> -alias <alias> -keystore /data/certs.jks \
         -storepass password -noprompt
      ```

   1. Set variables for the LDAP server.

      In the following example, the LDAP server has the hostname `dcldap2.us.cray.com` and is using the port `636`.

      ```bash
      LDAP=dcldap2.us.cray.com
      PORT=636
      ```

   1. Get the issuer certificate for the LDAP server at port `636`.

      Use `openssl s_client` to connect and show the certificate chain returned by the LDAP host.

      ```bash
      openssl s_client -showcerts -connect $LDAP:${PORT} </dev/null
      ```

   1. Generate `cacert.pem` containing the issuer's certificate.

      Either manually extract (cut/paste) the issuer's
      certificate into `cacert.pem`, or try the following commands to
      create it automatically.

      > **`NOTE`** The following commands were verified using OpenSSL
      > version `1.1.1d` and use the `-nameopt RFC2253` option to ensure
      > consistent formatting of distinguished names.
      > Older versions of OpenSSL may not support
      > `-nameopt` on the `s_client` command or may use a different
      > default format. However, administrators should be able to extract
      > the issuer certificate manually from the output of the above
      > `openssl s_client` example, if necessary.

      1. Observe the issuer's DN.

         For example:

         ```bash
         openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:${PORT} </dev/null 2>/dev/null | grep issuer= | sed -e 's/^issuer=//'
         ```

         Example output:

         ```text
         CN=DigiCert Global G2 TLS RSA SHA256 2020 CA1,O=DigiCert Inc,C=US
         ```

      1. Extract the issuer's certificate using the `awk` command.

         > **`NOTE`** The issuer DN is properly escaped as part of the
         > `awk` pattern below. If the value being used is
         > different, then be sure to escape it properly!

         ```bash
         openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:${PORT} </dev/null 2>/dev/null |
            awk '/s:CN=DigiCert Global G2 TLS RSA SHA256 2020 CA1,O=DigiCert Inc,C=US/,/END CERTIFICATE/' |
            awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > cacert.pem
         ```

   1. Verify the issuer's certificate was properly extracted and saved in `cacert.pem`.

      ```bash
      cat cacert.pem
      ```

      Expected output looks similar to the following:

      ```text
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

   1. Create `certs.jks`.

      ```bash
      podman run --rm -v "$(pwd):/data" artifactory.algol60.net/csm-docker/stable/docker.io/library/openjdk:11-jre-slim keytool -importcert \
        -trustcacerts -file /data/cacert.pem -alias cray-data-center-ca -keystore /data/certs.jks \
        -storepass password -noprompt
      ```

   1. Create `certs.jks.b64` by base-64 encoding `certs.jks`.

      ```bash
      base64 certs.jks > certs.jks.b64
      ```

   1. Inject and encrypt `certs.jks.b64` into `customizations.yaml`.

      ```console
      cat <<EOF | yq w - 'data."certs.jks"' "$(<certs.jks.b64)" | \
                    yq r -j - | /root/site-init/utils/secrets-encrypt.sh | \
                    yq w -f - -i /root/site-init/customizations.yaml \
                    spec.kubernetes.sealed_secrets.cray-keycloak
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

   1. Update `kafka` secrets with the new `certs.jks.b64`.

      ```bash
      kubectl get secret cray-shared-kafka-clients-ca-cert -n services -o json | jq --rawfile cert certs.jks.b64 '.data["ca.p12"]=$cert'
      kubectl get secret cray-shared-kafka-cluster-ca-cert -n services -o json | jq --rawfile cert certs.jks.b64 '.data["ca.p12"]=$cert'
      ```

      Restart the operator to apply the change:

      ```bash
      kubectl rollout restart -n services deployments cray-shared-kafka-entity-operator
      ```

1. Prepare to generate sealed secrets.

   Secrets are stored in `customizations.yaml` as `SealedSecret` resources
   (encrypted secrets), which are deployed by specific charts and decrypted by the
   sealed secrets operator. In order for that to happen, those Secrets must first be seeded,
   generated, and encrypted.

   ```bash
   ./utils/secrets-reencrypt.sh customizations.yaml ./certs/sealed_secrets.key ./certs/sealed_secrets.crt
   ```

1. Encrypt the static values in the `customizations.yaml` file after making changes.

   The following command must be run within the `site-init` directory.

   ```bash
   ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

   Expected output looks similar to:

   ```text
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

1. Decrypt the sealed secret to verify it was generated correctly.

   ```bash
   ./utils/secrets-decrypt.sh keycloak_users_localize | jq -r '.data.ldap_connection_url' | base64 --decode
   ```

   Expected output looks similar to the following:

   ```text
   ldaps://my_ldap.my_org.test
   ```

1. Upload the modified `customizations.yaml` file to Kubernetes.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Re-apply the `cray-keycloak` Helm chart with the updated `customizations.yaml` file.

   1. Retrieve the current `platform.yaml` manifest.

      ```bash
      kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > platform.yaml
      ```

   1. Remove all charts from the `platform.yaml` manifest except for `cray-keycloak`.

      Edit the `platform.yaml` file and delete all sections starting with `-name: <chart_name>`, except for the `cray-keycloak` section.

   1. Change the name of the manifest being deployed from `platform` to `cray-keycloak`.

      ```bash
      sed -i 's/name: platform/name: cray-keycloak/' platform.yaml
      ```

   1. Populate the platform manifest with data from the `customizations.yaml` file.

      ```bash
      manifestgen -i platform.yaml -c customizations.yaml -o new-platform.yaml
      ```

   1. Re-apply the platform manifest with the updated `cray-keycloak` chart.

      ```bash
      loftsman ship --manifest-path ./new-platform.yaml --charts-repo https://packages.local/repository/charts
      ```

   1. Wait for the `keycloak-certs` secret to reflect the new `cert.jks`.

      Run the following command until there is a non-empty value in the secret (this can take a minute or two):

      ```bash
      kubectl get secret -n services keycloak-certs -o yaml | grep certs.jks
        certs.jks: <REDACTED>
      ```

   1. Restart the `cray-keycloak-` pods.

      ```bash
      kubectl rollout restart statefulset -n services cray-keycloak
      ```

   1. Wait for the Keycloak pods to restart.

      ```bash
      kubectl rollout status statefulset -n services cray-keycloak
      ```

1. Re-apply the `cray-keycloak-users-localize` Helm chart with the updated `customizations.yaml` file.

   1. Determine the `cray-keycloak-users-localize` chart version that is currently deployed.

      ```bash
      helm ls -A -a | grep cray-keycloak-users-localize | awk '{print $(NF-1)}'
      cray-keycloak-users-localize-<VERSION>
      ```

   1. Create a manifest file that will be used to reapply the same chart version.

      Create the file `./cray-keycloak-users-localize-manifest.yaml` with the following contents:

      ```yaml
      apiVersion: manifests/v1beta1
      metadata:
        name: reapply-cray-keycloak-users-localize
      spec:
        charts:
          - name: cray-keycloak-users-localize
            namespace: services
            version: <VERSION FROM OUTPUT>
      ```

   1. Uninstall the current `cray-keycloak-users-localize` chart.

      ```bash
      helm del cray-keycloak-users-localize -n services
      ```

   1. Populate the deployment manifest with data from the `customizations.yaml` file.

      ```bash
      manifestgen -i cray-keycloak-users-localize-manifest.yaml -c customizations.yaml -o deploy.yaml
      ```

   1. Reapply the `cray-keycloak-users-localize` chart.

      ```bash
      loftsman ship --manifest-path ./deploy.yaml \
        --charts-repo https://packages.local/repository/charts
      ```

   1. Watch the pod to check the status of the job.

      The pod will go through the normal Kubernetes states. It will stay in a `Running` state for a while, and then it will go to `Completed`.

      ```bash
      kubectl get pods -n services | grep keycloak-users-localize
      ```

      Example output:

      ```text
      keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
      ```

   1. Check the pod's logs.

      Replace the `KEYCLOAK_POD_NAME` value with the pod name from the previous step.

      ```bash
      kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
      ```

      Example log entry showing that it has updated the "s3" objects and `ConfigMaps`:

      ```text
      2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
      ```

1. Sync the users and groups from Keycloak to the compute nodes.

   1. Get the `crayvcs` password.

      ```bash
      kubectl get secret -n services vcs-user-credentials \
        --template={{.data.vcs_password}} | base64 --decode
      ```

   1. Check out content from the `cos-config-management` VCS repository.

      ```bash
      git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
      cd cos-config-management
      git checkout integration
      ```

   1. Create the `group_vars/Compute/keycloak.yaml` file.

      The file contents should be:

      ```yaml
      ---
      keycloak_config_computes: True
      ```

   1. Push the changes to VCS with the `crayvcs` username.

      ```bash
      git add group_vars/Compute/keycloak.yaml
      git commit -m "Configure keycloak on computes"
      git push origin integration
      ```

   1. Update the Configuration Framework Service (CFS) configuration.

      ```bash
      cray cfs configurations update configurations-example --file ./configurations-example.json --format json
      ```

      Example output:

      ```json
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

   1. Reboot with the Boot Orchestration Service (BOS).

      ```bash
      cray bos session create --template-uuid BOS_TEMPLATE --operation reboot
      ```

1. Validate that LDAP integration was added successfully.

   1. Retrieve the `admin` user's password for Keycloak.

      ```bash
      kubectl get secrets -n services keycloak-master-admin-auth -ojsonpath='{.data.password}' | base64 -d
      ```

   1. Log in to the Keycloak UI using the `admin` user and the password obtained in the previous step.

      The Keycloak UI URL is typically similar to the following: `https://auth.cmn.<system_name>/keycloak`

   1. Click on the `Users` tab in the navigation pane on the left.

   1. Click on the `View all users` button and verify that the LDAP users appear in the table.

   1. Verify that a token can be retrieved from Keycloak using an LDAP user/password.

      In the example below, replace `myuser`, `mypass`, and `shasta` in the cURL command with
      site-specific values. The `shasta` client is created during the SMS install process.

      In the following example, the `jq` command is not required; it is simply used to
      format the output for readability.

      ```bash
      curl -s \
         -d grant_type=password \
         -d client_id=shasta \
         -d username=myuser \
         -d password=mypass \
         https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
      jq
      ```

      Expected output:

      ```json
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

   1. Validate that the `access_token` looks correct.

      Copy the `access_token` from the previous step and open a browser window.
      Navigate to `http://jwt.io` and paste the token in the `Encoded` field.

      Verify that the `preferred_username` is the expected LDAP user, and that the
      role is `admin` (or other role appropriate for the user).
