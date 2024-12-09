# CFS Component With Zero-Length ID

It is possible in some situations for a CFS component to be created with a zero-length string for an `id` field.
Such a component cannot be deleted using the Cray CLI or the CFS API.

## Symptoms

An administrator may notice the invalid component when listing components in CFS. The presence of such a component
could cause problems in different ways:

- It may also cause the `cmsdev` test to fail. For details on these test failure symptoms, see
  [Invalid CFS component](sms_health_check.md#invalid-cfs-component).
- Any tooling which parses CFS component listings may fail in unexpected ways when confronted with
  the zero-length ID string.

## Remediation

Follow this procedure to remove the invalid CFS component.

1. (`ncn-mw#`) Identify a running CFS server Kubernetes pod.

    ```bash
    POD=$(kubectl get pods -n services -l 'app.kubernetes.io/instance=cray-cfs-api' --no-headers | grep -w Running | awk '{ print $1 }' | head -1)
    echo "${POD}"
    ```

    Example output:

    ```text
    cray-cfs-api-7dfb78c7b8-clrjq
    ```

1. (`ncn-mw#`) Delete the CFS component with the zero-length ID.

    > No output is expected from the following command.

    ```bash
    kubectl exec -it -n services "${POD}" -- python3 -c 'from cray.cfs.api.controllers.components import delete_component_v2 ; delete_component_v2("")'
    ```

1. (`ncn-mw#`) Verify that the invalid component has been removed from CFS. If this problem was detected by `cmsdev`, then run
   the following command to perform only the CFS subtest.

    ```bash
    /usr/local/bin/cmsdev test -q cfs
    ```
