# Restrict Admin Privileges in Nexus

Prior to making the system available to users, change the ingress settings to disable connections to `packages.local` and `registry.local` from automatically gaining
administrative privileges.

Connections to `packages.local` and `registry.local` automatically login clients as the `admin` user. Administrative privileges enable any user to make anonymous writes to Nexus,
which means unauthenticated users can perform arbitrary actions on Nexus itself through the REST API, as well as in repositories by uploading or deleting assets.

Product installers currently do not expect to authenticate to Nexus, so it is necessary to retain the default ingress settings during installation.

- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
- [Removing the patch](#removing-the-patch)

## Prerequisites

CSM installation is complete.

## Procedure

1. Verify that the `registry` repository has `docker.forceBasicAuth` set to `true`.

    ```bash
    ncn-mw# curl -sS https://packages.local/service/rest/beta/repositories \
                | jq '.[] | select(.name == "registry") | .docker.forceBasicAuth = true' \
                | curl -sSi -X PUT 'https://packages.local/service/rest/beta/repositories/docker/hosted/registry' \
                    -H "Content-Type: application/json" -d @-
    ```

1. Set the `SYSTEM_DOMAIN_NAME` variable.

    ```bash
    ncn-mw# SYSTEM_DOMAIN_NAME=$(kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | \
                                    base64 -d | yq r - 'spec.network.dns.external')
    ncn-mw# echo "System domain name is: ${SYSTEM_DOMAIN_NAME}"
    ```

1. Patch the Nexus `VirtualService` resource in the `nexus` namespace to remove the `X-WEBAUTH-USER` request header when the `authority` matches `packages.local` or `registry.local`.

    ```bash
    ncn-mw# kubectl patch virtualservice -n nexus nexus --type merge --patch \
                "{\"spec\":{\"http\":[{\"match\":[{\"authority\":{\"exact\":\"packages.local\"}}],\
                    \"route\":[{\"destination\":{\"host\":\"nexus\",\"port\":{\"number\":80}},\"headers\":{\
                    \"request\":{\"remove\":[\"X-WEBAUTH-USER\"]}}}]},{\"match\":[{\"authority\":\
                    {\"exact\":\"registry.local\"}}],\"route\":[{\"destination\":{\"host\":\"nexus\",\
                    \"port\":{\"number\":5003}},\"headers\":{\"request\":{\"remove\":[\"X-WEBAUTH-USER\"]}}}]},\
                    {\"match\":[{\"authority\":{\"exact\":\"nexus.cmn.${SYSTEM_DOMAIN_NAME}\"}}],\"route\":\
                    [{\"destination\":{\"host\":\"nexus\",\"port\":{\"number\":80}},\"headers\":\
                    {\"request\":{\"add\":{\"X-WEBAUTH-USER\":\"admin\"},\"remove\":[\"Authorization\"]}}}]}]}}"
    ```

    The following is an example of the Nexus `VirtualService` resource before the patch:

    ```yaml
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

    ```yaml
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

## Removing the patch

If the patch needs to be removed for maintenance activities or any other purpose, then first make sure that `$SYSTEM_DOMAIN_NAME` is set, then run the following command:

```bash
ncn-mw# kubectl patch virtualservice -n nexus nexus --type merge --patch \
            "{\"spec\":{\"http\":[{\"match\":[{\"authority\":{\"exact\":\"packages.local\"}}]\
                ,\"route\":[{\"destination\":{\"host\":\"nexus\",\"port\":{\"number\":80}},\"headers\":\
                {\"request\":{\"add\":{\"X-WEBAUTH-USER\":\"admin\"},\"remove\":[\"Authorization\"]}}}]},\
                {\"match\":[{\"authority\":{\"exact\":\"registry.local\"}}],\"route\":[{\"destination\":\
                {\"host\":\"nexus\",\"port\":{\"number\":5003}},\"headers\":{\"request\":{\"add\":\
                {\"X-WEBAUTH-USER\":\"admin\"},\"remove\":[\"Authorization\"]}}}]},{\"match\":\
                [{\"authority\":{\"exact\":\"nexus.cmn.${SYSTEM_DOMAIN_NAME}\"}}],\"route\":\
                [{\"destination\":{\"host\":\"nexus\",\"port\":{\"number\":80}},\"headers\":\
                {\"request\":{\"add\":{\"X-WEBAUTH-USER\":\"admin\"},\"remove\":[\"Authorization\"]}}}]}]}}"
```
