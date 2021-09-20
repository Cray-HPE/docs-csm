

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

      ```bash
      ncn-m001# cp -r ${CSM_DISTDIR}/shasta-cfg /root/site-init
      ncn-m001# cd /root/site-init
      ```
  
   1. Extract customizations.yaml from the site-init secret.

      ```bash
      ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

   1. Extract the certificate and key used to create the sealed secrets.

      ```bash
      ncn-m001# mkdir certs
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

  > **NOTE:** All subsequent steps of this procedure should be performed within the `/root/site-init` directory created in this step.
   
2. Update the LDAP settings in the customizations.yaml file.

   1. Modify the customizations.yaml file to put the LDAP server CA certificate into the SealedSecret.
   
   2. Update the LDAP settings.
  
      LDAP connection information is stored in the keycloak-users-localize Secret in the services namespace. 
      In the customizations.yaml file, set the values for the keycloak_users_localize keys in the spec.kubernetes.sealed_secrets field:

      -   The ldap_connection_url key is required and is set to an LDAP URL.
      -   The ldap_bind_dn and ldap_bind_credentials keys are optional.
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

3. Prepare to generate Sealed Secrets.
   
   Secrets are stored in customizations.yaml as `SealedSecret` resources 
   (encrypted secrets), which are deployed by specific charts and decrypted by the
   Sealed Secrets operator. But first, those Secrets must be seeded generated and
   encrypted.

   1. Mount the PITDATA so that helm charts are available for the re-install (it might already be mounted).

      ```bash
      ncn-m001# mkdir -pv /mnt/pitdata
      ncn-m001# mount -L PITDATA /mnt/pitdata
      ```
   
   2. Load the `zeromq` container image required by Sealed Secret Generators.

      > **NOTE:** A properly configured Docker or Podman environment is required.

      ```bash
      ncn-m001# /mnt/pitdata/${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/zeromq/zeromq:v4.0.5
      ```

   3. Re-encrypt the existing secrets:

      ```bash
      ncn-m001# /mnt/pitdata/prep/site-init/utils/secrets-reencrypt.sh customizations.yaml \
      /mnt/pitdata/prep/site-init/certs/sealed_secrets.key /mnt/pitdata/prep/site-init/certs/sealed_secrets.crt
      ```
      
4. Encrypt the static values in the customizations.yaml file after making changes.

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

5. Re-apply the cray-keycloak-users-localize Helm chart with the updated customizations.yaml file.

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
            values:
              imagesHost: dtr.dev.cray.com
            version: 0.12.2
        EOF
        ```

    3. Determine the CSM_RELEASE version that is currently running and set an environment variable.

        For example:

        ```bash
        ncn-m001# CSM_RELEASE=1.10.54
        ```

    4. Uninstall the current cray-keycloak-users-localize chart.

        ```bash
        ncn-m001# helm del cray-keycloak-users-localize -n services
        ```

    5. Populate the deployment manifest with data from the customizations.yaml file.

        ```bash
        ncn-m001# manifestgen -i cray-keycloak-users-localize-manifest.yaml -c customizations.yaml -o deploy.yaml
        ```
   
    6. Reapply the cray-keycloak-users-localize chart based on the CSM_RELEASE.

        ```bash
        ncn-m001# loftsman ship --manifest-path ./deploy.yaml \
        --charts-repo https://packages.local/repository/charts
        ```

    7. Watch the pod to check the status of the job.

        The pod will go through the normal Kubernetes states. It will stay in a Running state for a while, and then it will go to Completed.

        ```bash
        ncn-m001# kubectl get pods -n services | grep keycloak-users-localize
        keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
        ```

    8.  Check the pod's logs.

        Replace the `KEYCLOAK_POD_NAME` value with the pod name from the previous step.

        ```bash
        ncn-m001# kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
        <logs showing it has updated the "s3" objects and ConfigMaps>
        2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
        ```

6. Sync the users and groups from Keycloak to the compute nodes.

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




