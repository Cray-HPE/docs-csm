# Restrict Admin Privileges in Nexus

Prior to making the system available to users, change the ingress settings to disable connections to `packages.local` and `registry.local` from automatically gaining `admin` privileges.

Connections to `packages.local` and `registry.local` automatically login clients as the `admin` user. Admin privileges enable any user to make anonymous writes to Nexus, which means unauthenticated users can perform arbitrary actions on Nexus itself through the REST API, as well as in repositories by uploading or deleting assets.

Product installers currently do not expect to authenticate to Nexus, so it is necessary to retain the default ingress settings during installation.

### Prerequisites

The system is fully installed.


### Procedure

1.  Verify that the `registry` repository has `docker.forceBasicAuth` set to `true`.

    ```bash
    ncn# curl -sS https://packages.local/service/rest/beta/repositories \
    | jq '.[] | select(.name == "registry") | .docker.forceBasicAuth = true' \
    | curl -sSi -X PUT 'https://packages.local/service/rest/beta/repositories/docker/hosted/registry' \
    -H "Content-Type: application/json" -d @-
    ```

2.  Patch the `nexus` VirtualService resource in the nexus namespace to remove the `X-WEBAUTH-USER` request header when the `authority` matches `packages.local` or `registry.local`.

    Replace SYSTEM_DOMAIN_NAME in the following command before running it.

    ```bash
    ncn# kubectl patch virtualservice -n nexus nexus --type merge --patch \
    '{"spec":{"http":[{"match":[{"authority":{"exact":"packages.local"}}],\
    "route":[{"destination":{"host":"nexus","port":{"number":80}},"headers":{\
    "request":{"remove":["X-WEBAUTH-USER"]}}}]},{"match":[{"authority":\
    {"exact":"registry.local"}}],"route":[{"destination":{"host":"nexus",\
    "port":{"number":5003}},"headers":{"request":{"remove":["X-WEBAUTH-USER"]}}}]},\
    {"match":[{"authority":{"exact":"nexus.cmn.SYSTEM_DOMAIN_NAME"}}],"route":\
    [{"destination":{"host":"nexus","port":{"number":80}},"headers":\
    {"request":{"add":{"X-WEBAUTH-USER":"admin"},"remove":["Authorization"]}}}]}]}}'
    ```

    The following is an example of the `nexus` VirtualService resource before the patch:

    ```bash
    spec:
      http:
      - match:
        - authority:
            exact: packages.local
        route:
        - destination:
            host: nexus
            port:
              number: 80
        headers:
          request:
            add:
              X-WEBAUTH-USER: admin
            remove:
            - Authorization
      - match:
        - authority:
            exact: registry.local
        route:
        - destination:
            host: nexus
            port:
              number: 5003
        headers:
          request:
            add:
              X-WEBAUTH-USER: admin
            remove:
            - Authorization
    ```

    The patch will update the information to the following:

    ```bash
    spec:
      http:
      - match:
        - authority:
            exact: packages.local
        route:
        - destination:
            host: nexus
            port:
              number: 80
        headers:
          request:
            remove:
            - X-WEBAUTH-USER
      - match:
        - authority:
            exact: registry.local
        route:
        - destination:
            host: nexus
            port:
              number: 5003
        headers:
          request:
            remove:
            - X-WEBAUTH-USER
    ```


**Troubleshooting:** If the patch needs to be removed for maintenance activities or any other purpose, run the following command:

Replace SYSTEM_DOMAIN_NAME in the following command before running it.

```bash
ncn# kubectl patch virtualservice -n nexus nexus --type merge \
--patch '{"spec":{"http":[{"match":[{"authority":{"exact":"packages.local"}}]\
,"route":[{"destination":{"host":"nexus","port":{"number":80}},"headers":\
{"request":{"add":{"X-WEBAUTH-USER":"admin"},"remove":["Authorization"]}}}]},\
{"match":[{"authority":{"exact":"registry.local"}}],"route":[{"destination":\
{"host":"nexus","port":{"number":5003}},"headers":{"request":{"add":\
{"X-WEBAUTH-USER":"admin"},"remove":["Authorization"]}}}]},{"match":\
[{"authority":{"exact":"nexus.cmn.SYSTEM_DOMAIN_NAME"}}],"route":\
[{"destination":{"host":"nexus","port":{"number":80}},"headers":\
{"request":{"add":{"X-WEBAUTH-USER":"admin"},"remove":["Authorization"]}}}]}]}}'
```

