#!/bin/bash

ADMIN_SECRET=$(kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 -d)
IP=$(kubectl get service/keycloak -n services -o json | jq -r '.spec.clusterIP')
TOKEN=$(curl -s http://$IP:8080/keycloak/realms/master/protocol/openid-connect/token -d grant_type=password -d client_id=admin-cli -d username=admin --data-urlencode password="$ADMIN_SECRET" | sed 's/.*access_token":"//g' | sed 's/".*//g')

echo "Get shasta client id"
CLIENT_ID=$(curl -s http://$IP:8080/keycloak/admin/realms/shasta/clients?clientId=shasta -H "Authorization: bearer $TOKEN" | jq '.[].id' | tr -d '"')
echo "client id is: $CLIENT_ID"

echo "Get read-only monitoring role id"
ROLE_ID=$(curl -s http://$IP:8080/keycloak/admin/realms/shasta/clients/$CLIENT_ID/roles -H "Authorization: bearer $TOKEN" | jq -r '.[] | select(.name=="monitor-ro") | .id')
if [ -z "$ROLE_ID" ]
then
    echo "ERROR: could not find monitor-ro role in shasta client"
    exit 1
else
    echo "monitor-ro role has id: $ROLE_ID"
fi

USER_NAME=ro-test-user
echo "Create user $USER_NAME"
curl -s http://$IP:8080/keycloak/admin/realms/shasta/users -H "Content-Type: application/json" -H "Authorization: bearer $TOKEN" -d '{"username":"'"$USER_NAME"'","enabled":true, "credentials":[{"type":"password","value":"ro-test-pass"}]}'

USER_ID=$(curl -s http://$IP:8080/keycloak/admin/realms/shasta/users/?username=$USER_NAME -H "Authorization: bearer $TOKEN" | jq '.[].id' | tr -d '"')
echo "user id is: $USER_ID"

echo "Configure role-mapping"
curl -s http://$IP:8080/keycloak/admin/realms/shasta/users/$USER_ID/role-mappings/clients/$CLIENT_ID -H "Content-Type: application/json" -H "Authorization: bearer $TOKEN" -d '[{"id": "'"$ROLE_ID"'", "name":"monitor-ro"}]'

echo "Verify role-mapping configuration"
RESULT=$(curl -s http://$IP:8080/keycloak/admin/realms/shasta/users/$USER_ID/role-mappings/clients/$CLIENT_ID -H "Authorization: bearer $TOKEN" | jq -r '.[] | select(.name=="monitor-ro") | .name')
if [ -z "$RESULT" ]
then
    echo "ERROR: could not find expected role-mapping"
    exit 2
fi

###################
#Test Case: Telemetry access test
echo "Verify access to Telemetry API"
DN=$(kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | grep "external:" | awk '{print $2}')
USER_TOKEN=$(curl -s -d 'client_id=shasta' -d 'username=ro-test-user' -d 'password=ro-test-pass' -d 'grant_type=password' https://auth.cmn.$DN/keycloak/realms/shasta/protocol/openid-connect/token)
ACCESS_TOKEN=$(echo ${USER_TOKEN}|jq -r .access_token)
TELEMETRY_API_URL="https://api-gw-service-nmn.local/apis/sma-telemetry-api"
STREAMS=$(curl -k -s ${TELEMETRY_API_URL} -H "Authorization: Bearer ${ACCESS_TOKEN}" ${TELEMETRY_API_URL}/v1|jq | grep api_endpoints)
if [[ "$STREAMS" =~ "api_endpoints" ]]; then
    echo "SUCCESS"
else
    echo "FAIL: $USER_NAME is unable to access Telemetry API. Is SMA installed on the system?"
    exit 3
fi

echo "Delete user $USER_NAME"
curl -X "DELETE" http://$IP:8080/keycloak/admin/realms/shasta/users/$USER_ID -H "Authorization: bearer $TOKEN"
