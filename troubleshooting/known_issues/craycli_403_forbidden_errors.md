# Cray CLI 403 Forbidden Errors 

There is a known issue where the keycloak configuration obtained from LDAP is incomplete causing the keycloak-users-localize job to fail to complete.  This, in turn, causes 403 Forbidden errors when trying to use the craycli.

## Fix
To recover from this situation, the following can be done. 

1. Log into the Keycloak admin console. See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md)
1. Delete the shasta-user-federation-ldap entry from the “User Federation” page.
1. Wait three minutes for the configuration to resync.
1. Check to see if the keycloak-users-localize job has completed.
   ```
   kubectl -n services wait --for=condition=complete --timeout=10s job/`kubectl -n services get jobs | grep users-localize | awk '{print $1}'`
   ```
1. If the above command returns output containing `condition met` then the issue is resolved and you can skip the rest of the steps.
1. If the above command returns output containing `error: timed out waiting for the condition` then check the logs of the keycloak-users-localize pod.
   ```
   kubectl -n services logs `kubectl -n services get pods | grep users-localize | awk '{print $1}'` keycloak-localize
   ```
1. If you see an error showing that there is a duplicate group, complete the next step. 
1. Go to the Groups page in the Keycloak admin console and delete the groups. 
1. Wait three minutes for the configuration to resync. 
1. Check again to make sure the job has now completed.
   ```
   kubectl -n services wait --for=condition=complete --timeout=10s job/`kubectl -n services get jobs | grep users-localize | awk '{print $1}'`
   ```
   You should see output containing `condition met`

