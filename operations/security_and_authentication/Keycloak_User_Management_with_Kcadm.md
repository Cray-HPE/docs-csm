# Keycloak User Management with `kcadm.sh`

## Overview

The Cray CLI requires a valid Keycloak JWT token. If the token is not present it must be obtained by supplying valid user credentials at the time of CLI
initialization. During the installation or upgrade of a Shasta system, the Keycloak user LDAP federation state or credentials may not be known, or the external
LDAP system for which the user may have been federated may not be available. These scenarios make it impossible to initialize the Cray CLI with a previously
valid Keycloak user or LDAP federated Keycloak user. If for any reason the Keycloak UI is not available for the administrator to verify the state of the user,
using Keycloak's `kcadm.sh` utility from the command line will be required.

The `kcadm.sh` utility is included with the Shasta Keycloak container image and can be used as described below to:

* Perform troubleshooting operations that can verify the existence of a user.
* Determine if a user is federated.
* Change a user credential (for a Keycloak local account only).
* Create a new local Keycloak user that is compatible (has the correct role mappings) with the Cray CLI.

All of the operations described below must be run as `root` from the `ncn-m001` node.

Usage of Bash functions provided below will require making additions to the Linux environment. This can be accomplished by pasting the function into the shell, or pasting the function into a file and then sourcing the file, before running the indicated function.

### Topics

* [Check the Status of a Keycloak User](#check-the-status-of-a-keycloak-user)
* [Update a Local Keycloak User Credential](#update-a-local-keycloak-user-credential)
* [Create a Local Keycloak Cray CLI User](#create-a-local-keycloak-cray-cli-user)
* [Delete a Local Keycloak User](#delete-a-local-keycloak-user)

## Check the Status of a Keycloak User

This procedure determines whether or not a user exists in Keycloak and whether or not that user is LDAP federated.

If a user is LDAP federated and the credential is not known, then that user credential must be updated in LDAP.

Add the following Bash function to your environment:

```bash
kc-find-user(){
  # Note that filtering does not use exact matching. For example, the below would
  # match the value of username attribute against "*$1*" pattern.

  if [ $# -eq 0 ]; then
    echo "Usage: ${FUNCNAME[0]} userName"
    return 1
  fi

  local MAA
  MAA=$(kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} |
        base64 --decode)
  if [ -z "$MAA" ]; then
    echo "Unable to get the master admin authentication credential"
    return 1
  fi

  kubectl -n services exec cray-keycloak-0 -c keycloak -- sh -c "
    echo 'Looking for the Keycloak user: $1' &&
    ./opt/keycloak/bin/kcadm.sh get users -r shasta -q username='$1' --no-config \
        --server http://localhost:8080/keycloak --realm master --user admin \
        --client admin-cli --password '$MAA'"
}
```

Example when the user account is LDAP federated, as indicated by the presence of the `federationLink` attribute:

```bash
kc-find-user vers
Looking for the Keycloak user: vers
Logging into http://localhost:8080/keycloak as user admin of realm master
[ {
  "id" : "4c494308-eeb9-4fba-a9c7-155ca42f3b7d",
  "createdTimestamp" : 1643219255179,
  "username" : "vers",
  "enabled" : true,
  "totp" : false,
  "emailVerified" : false,
  "firstName" : " ... ",
  "lastName" : " ... ",
  "email" : " ... ",
  "federationLink" : "0fe556b0-06a9-4628-84da-a35ff2f080ec",
  "attributes" : {
    "loginShell" : [ "/bin/bash" ],
    "homeDirectory" : [ "/home/users/vers" ],
    "LDAP_ENTRY_DN" : [ "uid=vers,ou=people,dc=dcldap,dc=dit" ],
    "uidNumber" : [ "1356" ],
    "gidNumber" : [ "11121" ],
    "createTimestamp" : [ "20200413200346Z" ],
    "modifyTimestamp" : [ "20211015174258Z" ],
    "LDAP_ID" : [ "vers" ]
  },
  "disableableCredentialTypes" : [ ],
  "requiredActions" : [ ],
  "notBefore" : 0,
  "access" : {
    "manageGroupMembership" : true,
    "view" : true,
    "mapRoles" : true,
    "impersonate" : true,
    "manage" : true
  }
} ]
```

If the user is a local Keycloak user and the credential is not known, then see [Update a Local Keycloak User Credential](#update-a-local-keycloak-user-credential).

Example when the user account is a local Keycloak user (no `federationLink` attribute):

```bash
kc-find-user localcli
Looking for the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
[ {
  "id" : "b49abdcc-a314-4355-89d7-44f4d8d33ab8",
  "createdTimestamp" : 1649193410108,
  "username" : "localcli",
  "enabled" : true,
  "totp" : false,
  "emailVerified" : false,
  "disableableCredentialTypes" : [ ],
  "requiredActions" : [ ],
  "notBefore" : 0,
  "access" : {
    "manageGroupMembership" : true,
    "view" : true,
    "mapRoles" : true,
    "impersonate" : true,
    "manage" : true
  }
} ]
```

If the user does not exist and it is necessary to create a local Keycloak user for use with the Cray CLI, then see [Create a Local Keycloak Cray CLI User](#create-a-local-keycloak-cray-cli-user).

Example when the user account is not known to Keycloak:

```bash
kc-find-user nouser
Looking for the Keycloak user: nouser
Logging into http://localhost:8080/keycloak as user admin of realm master

[ ]ncn-m001#
```

## Update a Local Keycloak User Credential

This procedure resets the credential for a local Keycloak user. This procedure will not work if the user is LDAP federated.

Add the following Bash function to your environment:

```bash
kc-set-local-user-password(){

  if [ $# -eq 0 ]; then
    echo "Usage: ${FUNCNAME[0]} userName"
    return 1
  fi

  local MAA
  MAA=$(kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} |
        base64 --decode)
  if [ -z "$MAA" ]; then
    echo "Unable to get the master admin authentication credential"
    return 1
  fi

  # Specify a new default password.
  # Set KC_USER_NEWPASSWD to a specific password override the default
  # before calling this function.
  # i.e.: KC_USER_NEWPASSWD=someNewPassword
  : ${KC_USER_NEWPASSWD:=changeme1}

  kubectl -n services exec cray-keycloak-0 -c keycloak -- sh -c "
    echo 'Resetting password for the Keycloak user: $1' &&
    ./opt/keycloak/bin/kcadm.sh set-password -r shasta --username '$1' \
        --new-password '$KC_USER_NEWPASSWD' --no-config --server http://localhost:8080/keycloak \
        --realm master --user admin --client admin-cli --password '$MAA'"
}
```

> If desired, set the `KC_USER_NEWPASSWD` variable to override the default before calling the function.

Example of updating the credential with an overridden password:

```bash
KC_USER_NEWPASSWD=wax0nwax0ff kc-set-local-user-password localcli
Resetting password for the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
```

If the user cannot be found by username, then the account credential will not be updated, as in this example:

```bash
kc-set-local-user-password localc
Resetting password for the Keycloak user: localc
Logging into http://localhost:8080/keycloak as user admin of realm master
User not found for username: localc
command terminated with exit code 1
```

If the user is LDAP federated, then the account credential will not be updated, as in this example:

```bash
KC_USER_NEWPASSWD=wax0nwax0ff && kc-set-local-user-password vers
Resetting password for the Keycloak user: vers
Logging into http://localhost:8080/keycloak as user admin of realm master
null [Can't reset password as account is read only]
command terminated with exit code 1
```

## Create a Local Keycloak Cray CLI User

This procedure creates a new local Keycloak user that is compatible with the Cray CLI. This may be needed because it is not possible to use a federated user account to initialize the Cray CLI if LDAP is not available.

Add the following Bash function to your environment:

```bash
kc-create-local-cli-user(){
  if [ $# -eq 0 ]; then
    echo "Usage: ${FUNCNAME[0]} userName"
    return 1
  fi

  local MAA
  MAA=$(kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} |
        base64 --decode)
  if [ -z "$MAA" ]; then
    echo "Unable to get the master admin authentication credential"
    return 1
  fi

  # Specify a new default password.
  # Set KC_USER_NEWPASSWD to a specific password to override the default
  # before calling this function.
  # i.e.: KC_USER_NEWPASSWD=someNewPassword
  : ${KC_USER_NEWPASSWD:=changeme1}

  kubectl -n services exec cray-keycloak-0 -c keycloak -- sh -c "
    echo 'Creating the Keycloak user: $1' &&
    ./opt/keycloak/bin/kcadm.sh create users -r shasta -s enabled=true -s username='$1' \
        --no-config --server http://localhost:8080/keycloak --realm master --user admin \
        --client admin-cli --password '$MAA' &&
    echo 'Resetting password for the Keycloak user: $1' &&
    ./opt/keycloak/bin/kcadm.sh set-password -r shasta --username '$1' \
        --new-password '$KC_USER_NEWPASSWD' --no-config --server http://localhost:8080/keycloak \
        --realm master --user admin --client admin-cli --password '$MAA' &&
    echo 'Adding the Cray client admin role to the user: $1' &&
    ./opt/keycloak/bin/kcadm.sh add-roles -r shasta --uusername '$1' --cclientid cray \
        --rolename admin --no-config --server http://localhost:8080/keycloak --realm master \
        --user admin --client admin-cli --password '$MAA' &&
    echo 'Adding the Shasta client admin role to the user: $1' &&
    ./opt/keycloak/bin/kcadm.sh add-roles -r shasta --uusername '$1' --cclientid shasta \
        --rolename admin --no-config --server http://localhost:8080/keycloak --realm master \
        --user admin --client admin-cli --password '$MAA'"
}
```

> If desired, set the `KC_USER_NEWPASSWD` variable to override the default before calling the function.

Example of creating a user:

```bash
KC_USER_NEWPASSWD=wax0ffwax0n kc-create-local-cli-user localcli
Creating the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
Created new user with id 'b49abdcc-a314-4355-89d7-44f4d8d33ab8'
Resetting password for the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
Adding the Cray client admin role to the user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
Adding the Shasta client admin role to the user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
```

If desired, the user creation may be verified by checking the status of the new user. See [Check the Status of a Keycloak User](#check-the-status-of-a-keycloak-user).

Initializing the Cray CLI is possible using this new user and credential. See [Configure the Cray CLI](../configure_cray_cli.md).

If the user to be created already exists, then the function will just exit, as in this example:

```bash
kc-create-local-cli-user localcli
Creating the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
User exists with same username
command terminated with exit code 1
```

## Delete a Local Keycloak User

This procedure deletes a local Keycloak user. This will not work if the user is LDAP federated.

Add the following Bash function to your environment:

```bash
kc-delete-local-user(){
  if [ $# -eq 0 ]; then
    echo "Usage: ${FUNCNAME[0]} userID"
    echo "where 'userID' is the 'id' of the user as reported by kc-find-user"
    return 1
  fi

  local confirm
  read -p "This will delete the Keycloak userID $1. Continue? (y/N): " \
        confirm && [[ $confirm == [yY] ]] || return 1

  local MAA
  MAA=$(kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} |
        base64 --decode)
  if [ -z "$MAA" ]; then
    echo "Unable to get the master admin authentication credential"
    return 1
  fi

  kubectl -n services exec cray-keycloak-0 -c keycloak -- sh -c "
    echo 'Deleting the Keycloak user UUID: $1' &&
    ./opt/keycloak/bin/kcadm.sh delete 'users/$1' -r shasta --no-config \
        --server http://localhost:8080/keycloak --realm master --user admin \
        --client admin-cli --password '$MAA'"
}
```

Example usage:

```bash
kc-find-user localcli
Looking for the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master
[ {
  "id" : "b49abdcc-a314-4355-89d7-44f4d8d33ab8",
  "createdTimestamp" : 1649193410108,
  "username" : "localcli",
  "enabled" : true,
  "totp" : false,
  "emailVerified" : false,
  "disableableCredentialTypes" : [ ],
  "requiredActions" : [ ],
  "notBefore" : 0,
  "access" : {
    "manageGroupMembership" : true,
    "view" : true,
    "mapRoles" : true,
    "impersonate" : true,
    "manage" : true
  }
} ]
kc-delete-local-user b49abdcc-a314-4355-89d7-44f4d8d33ab8
This will delete the Keycloak userID b49abdcc-a314-4355-89d7-44f4d8d33ab8. Continue? (y/N): y
Deleting the Keycloak user UUID: b49abdcc-a314-4355-89d7-44f4d8d33ab8
Logging into http://localhost:8080/keycloak as user admin of realm master
kc-find-user localcli
Looking for the Keycloak user: localcli
Logging into http://localhost:8080/keycloak as user admin of realm master

[ ]
```

If the user can not be found by ID, then it will not be removed, as in this example:

```bash
kc-delete-local-user b49abdcc-a314-4355-89d7-44f4d8d33ab8
This will delete the Keycloak userID b49abdcc-a314-4355-89d7-44f4d8d33ab8. Continue? (y/N): y
Deleting the Keycloak user UUID: b49abdcc-a314-4355-89d7-44f4d8d33ab8
Logging into http://localhost:8080/keycloak as user admin of realm master
Resource not found for url: http://localhost:8080/keycloak/admin/realms/shasta/users/b49abdcc-a314-4355-89d7-44f4d8d33ab8
command terminated with exit code 1
```
