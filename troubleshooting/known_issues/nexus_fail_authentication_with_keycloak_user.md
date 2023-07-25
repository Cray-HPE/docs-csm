# Nexus Fails Authentication with Keycloak Users

There is a known issue where the Nexus chart gets created and setup before `keycloak-setup` has completed running.
This, in turn, causes an issue in Nexus while attempting to login to nexus with a Keycloak user.
This can also cause a Nexus test to fail during CSM health validation.

## Fix

To recover from this situation, the following can be done.

1. Get the correct client secret for the 'Nexus' Keycloak Client

   ```bash
   correct_secret=$(kubectl get secret -n nexus system-nexus-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)
   ```

1. Get the already setup Keycloak integration configuration secret from nexus

   ```bash
   old_config=$(kubectl get secret -n nexus nexus-keycloak-realm-config -o jsonpath='{.data.keycloak\.json}' | base64 -d)
   ```

1. Update the Keycloak integration configuration secret

   ```bash
   new_config=$(echo $old_config | jq -c --arg secret $correct_secret '.credentials.secret = $secret')
   ```

1. Update the Keycloak integration secret in Kubernetes

   ```bash
   kubectl patch secret -n nexus nexus-keycloak-realm-config --patch="{\"data\": { \"keycloak.json\": \"$(echo $new_config  | base64 -w0)\" }}"
   ```

1. Restart Nexus to update the configuration in Nexus

   ```bash
   kubectl rollout restart -n nexus deployment nexus
   ```
