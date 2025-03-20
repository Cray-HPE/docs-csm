#!/bin/bash

# Export a keycloak token so we can access BSS.
TOKEN=$(curl -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN

python3 ./cleanup.py
