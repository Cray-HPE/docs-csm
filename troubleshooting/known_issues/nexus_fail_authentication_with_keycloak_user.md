# Nexus Fails Authentication with Keycloak Users

There is a known issue where the Nexus chart gets created and setup before `keycloak-setup` has completed running.
This causes an issue while attempting to log in to Nexus with a Keycloak user.
This can also cause a Nexus test to fail during CSM health validation.

## Fix

To recover from this situation, perform the following procedure.

1. (`ncn-mw#`) Get the correct client secret for the Nexus Keycloak client.

   ```bash
   correct_secret=$(kubectl get secret -n nexus system-nexus-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)
   ```

1. (`ncn-mw#`) Get the already setup Keycloak integration configuration secret from Nexus.

   ```bash
   old_config=$(kubectl get secret -n nexus nexus-keycloak-realm-config -o jsonpath='{.data.keycloak\.json}' | base64 -d)
   ```

1. (`ncn-mw#`) Update the Keycloak integration configuration secret.

   ```bash
   new_config=$(echo $old_config | jq -c --arg secret $correct_secret '.credentials.secret = $secret')
   ```

1. (`ncn-mw#`) Update the Keycloak integration secret in Kubernetes.

   ```bash
   kubectl patch secret -n nexus nexus-keycloak-realm-config --patch="{\"data\": { \"keycloak.json\": \"$(echo $new_config  | base64 -w0)\" }}"
   ```

1. (`ncn-mw#`) Restart Nexus to update its configuration.

   ```bash
   kubectl rollout restart -n nexus deployment nexus
   ```
