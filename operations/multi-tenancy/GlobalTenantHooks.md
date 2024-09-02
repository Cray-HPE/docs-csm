# Global Tenant Hooks

- [Overview](#overview)
- [Creating a global tenant hook CRD](#create-a-global-hook-crd)
- [Apply the global tenant hook CR](#apply-the-global-hook-cr)

## Overview

Global Tenant Hooks behave in a similar manner to hooks defined in the tenant definition, but apply to all tenants.  This is useful for cases where administrators want to be alerted to all tenant events regardless of the tenant definition.

## Create a Global Hook CRD

Creating a global tenant hook involves creating a Custom Resource Definition (CRD) and then applying the Custom Resource (CR).

- (`ncn-mw#`) The full schema is available by executing the following command:

    ```bash
    kubectl get customresourcedefinitions.apiextensions.k8s.io globaltenanthooks.tapms.hpe.com  -o yaml
    ```

- An example of a global tenant hook custom resource (CR):

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha3
    kind: GlobalTenantHook
    metadata:
      name: hook-test
    spec:
      name: notify-hook
      url: http://10.252.1.4:7000
      blockingcall: false
      eventtypes:
        - CREATE
        - UPDATE
        - DELETE
      hookcredentials:
        secretname: notify-hook-cm
        secretnamespace: services
    ```

## Apply the Global Hook CR

- (`ncn-mw#`) Once the CR has been crafted for the global hook, the following command will apply the definition:

    > All global tenant hooks should be applied in the `tenants` namespace.

    ```bash
    kubectl apply -n tenants -f <hook.yaml>
    ```

    Example output:

    ```text
    globaltenanthooks.tapms.hpe.com/hook-test created
    ```

- The global hook is created immediately and any tenant events that occur after this point will send data to the global hook endpoint.
