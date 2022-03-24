# Keycloak Operations

A service may need to access Keycloak to perform various tasks. These typical uses for a service to access Keycloak include creating a new service account, creating a new user, etc. These operations require Keycloak administrative access. As part of the System Management Services \(SMS\) installation process, Keycloak is initialized with a Master realm. An administrative client and user are created within this realm. The system installation process adds the information needed for the Keycloak administrator's authentication into a Kubernetes secret that can be accessed by any pod. Using this information and the Keycloak REST API, a service can create an account in the `Shasta` realm. The Keycloak master administrative authentication information is located in the `keycloak-master-admin-auth` secret, which includes the following fields:

- `client-id` - Client ID for administrative operations
- `user` - Username for the Keycloak Master admin.
- `password` - Password for the Keycloak Master admin.
- `internal_token_url` - URL that can be used to get a token, such as https://istio-ingressgateway.istio-system.svc.cluster.local/keycloak/realms/master/protocol/openid-connect/token.

    The pod in the following example gets a Keycloak Master admin token and makes a request to create a client with a user ID attribute mapper.

    ```bash
    ncn# kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: kc-admin-example
      namespace: services
    spec:
      containers:
        - name: kc-admin-example
          image: alpine
          command:
          - sh
          - -c
          - >-
            apk update &&
            apk add --no-cache curl jq &&
            echo endpoint: \$(cat /mnt/auth/internal_token_url) &&
            echo client_id: \$(cat /mnt/auth/client-id) &&
            echo user: \$(cat /mnt/auth/user) &&
            TOKEN=\$(curl -s
            --cacert /mnt/shasta-ca/certificate_authority.crt
            -d grant_type=password
            -d client_id=\$(cat /mnt/auth/client-id)
            -d username=\$(cat /mnt/auth/user)
            -d password=\$(cat /mnt/auth/password)
            \$(cat /mnt/auth/internal_token_url) | jq -r .access_token) &&
            echo "=== Making request with token \$(echo \$TOKEN | head -c10)... ===" &&
            curl -is
            --cacert /mnt/shasta-ca/certificate_authority.crt
            -H "Authorization: Bearer \$TOKEN"
            -H "Content-Type: application/json"
            -d '{"clientId": "example", "publicClient": true,
            "standardFlowEnabled": false, "implicitFlowEnabled": false,
            "directAccessGrantsEnabled": true,
            "protocolMappers": [
            {"name": "uid-user-attribute-mapper",
            "protocolMapper": "oidc-usermodel-attribute-mapper",
            "protocol": "openid-connect",
            "config": {"user.attribute": "uid", "claim.name": "uid",
            "access.token.claim": false, "userinfo.token.claim": true}}]}'
            https://istio-ingressgateway.istio-system.svc.cluster.local/keycloak/admin/realms/shasta/clients
          volumeMounts:
          - name: ca-vol
            mountPath: /mnt/shasta-ca
          - name: auth-vol
            mountPath: '/mnt/auth'
            readOnly: true
      volumes:
        - name: ca-vol
          configMap:
            name: cray-configmap-ca-public-key
        - name: auth-vol
          secret:
            secretName: keycloak-master-admin-auth
      restartPolicy: Never
    EOF
    ```

    ```bash
    ncn# kubectl logs -n services kc-admin-example
    ```

    Example output:

    ```
    fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/main/x86_64/APKINDEX.tar.gz
    fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/community/x86_64/APKINDEX.tar.gz
    v3.8.1-115-ge3ed6b4e31 [http://dl-cdn.alpinelinux.org/alpine/v3.8/main]
    v3.8.1-112-g45bdd0edfb [http://dl-cdn.alpinelinux.org/alpine/v3.8/community]
    OK: 9546 distinct packages available
    fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/main/x86_64/APKINDEX.tar.gz
    fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/community/x86_64/APKINDEX.tar.gz
    (1/7) Installing ca-certificates (20171114-r3)
    (2/7) Installing nghttp2-libs (1.32.0-r0)
    (3/7) Installing libssh2 (1.8.0-r3)
    (4/7) Installing libcurl (7.61.1-r1)
    (5/7) Installing curl (7.61.1-r1)
    (6/7) Installing oniguruma (6.8.2-r0)
    (7/7) Installing jq (1.6_rc1-r1)
    Executing busybox-1.28.4-r1.trigger
    Executing ca-certificates-20171114-r3.trigger
    OK: 7 MiB in 20 packages
    endpoint: https://istio-ingressgateway.istio-system.svc.cluster.local/keycloak/realms/master/protocol/openid-connect/token
    client_id: admin-cli
    user: admin
    === Making request with token eyJhbGciOi... ===
    HTTP/1.1 201 Created
    Content-Length: 0
    Connection: keep-alive
    Location: https://istio-ingressgateway.istio-system.svc.cluster.local/keycloak/admin/realms/shasta/clients/070c8537-6c46-43a4-b0bb-209b3c4b94c6
    Date: Fri, 30 Nov 2018 20:07:39 GMT
    X-Kong-Upstream-Latency: 27
    X-Kong-Proxy-Latency: 1
    Via: kong/0.14.1
    ```

  The new example client is now visible in the Keycloak administrative web application.

