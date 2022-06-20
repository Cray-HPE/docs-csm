set -eu

argoUrl=$(kubectl get VirtualService/cray-argo -n argo -o json | jq -r '.spec.hosts[0]')

export TOKEN=$(curl -k -s -S -d grant_type=password \
   -d client_id=`kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.client-id}' -n services | base64 -d` \
   -d username=`kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.user}' -n services | base64 -d` \
   -d password=`kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.password}' -n services | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/master/protocol/openid-connect/token | jq -r '.access_token')

foundArgoInRedirectUris=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .redirectUris' | grep "https://argo.cmn" | wc -l)
redirectUris=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .redirectUris')

foundArgoInWebOrigins=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .webOrigins' | grep "https://argo.cmn" | wc -l)
webOrigins=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .webOrigins')

id=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .id')

curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}" > client.json
if [[ ${foundArgoInRedirectUris} -ge 1 ]];then
    echo "Argo URL is set in RedirectUris"
    echo ${redirectUris}
else
    echo
    cat client.json | jq ".redirectUris[.redirectUris | length] |= . + \"https://$argoUrl/oauth/callback\""  | tee client.json
fi

if [[ ${foundArgoInWebOrigins} -ge 1 ]];then
    echo "Argo URL is set in WebOrigins"
    echo ${webOrigins}
else
    echo
    cat client.json | jq ".webOrigins[.webOrigins | length] |= . + \"https://$argoUrl\"" | tee client.json
fi

curl -k -XPUT \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d @client.json \
    "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}" > /dev/null
