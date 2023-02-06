# Troubleshoot Failed CFS Sessions

View the Kubernetes logs for a Configuration Framework Service \(CFS\) pod in an error state to determine whether the error resulted from the
CFS infrastructure or from an Ansible play that was run by a specific configuration layer in a CFS session.

Use this procedure to obtain important triage information for Ansible plays being called by CFS.

## Prerequisites

* A failed configuration session exists in CFS.

## Procedure

1. (`ncn-mw#`) Find the CFS pod that is in an error state.

    1. List all CFS pods in error state.

        ```bash
        kubectl get pods -n services | grep -E "^cfs-.*[[:space:]]Error[[:space:]]"
        ```

        Example output:

        ```text
        cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn   0/3     Error    0          25h
        ```

    1. Set `CFS_POD_NAME` to the name of the pod to be investigated.

        > Use the pod name identified in the previous substep.

        ```bash
        CFS_POD_NAME=cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn
        ```

1. (`ncn-mw#`) Check to see what containers are in the pod.

    ```bash
    kubectl logs -n services "${CFS_POD_NAME}"
    ```

    Example output:

    ```text
    Error from server (BadRequest): a container name must be specified for pod cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn, choose one of: [inventory ansible istio-proxy] or one of the init containers: [git-clone istio-init]
    ```

    Issues rarely occur in the `istio-init` and `istio-proxy` containers. These containers can be ignored for now.

1. (`ncn-mw#`) Check the `git-clone`, `inventory`, and `ansible` containers, in that order.

    1. Check the `git-clone` container.

        ```bash
        kubectl logs -n services "${CFS_POD_NAME}" git-clone
        ```

    1. Check the `inventory` container.

        ```bash
        kubectl logs -n services "${CFS_POD_NAME}" inventory
        ```

        Example output:

        ```text
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
          0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (7) Failed to connect to localhost port 15000: Connection refused
        Waiting for Sidecar
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
          0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
        HTTP/1.1 200 OK
        content-type: text/html; charset=UTF-8
        cache-control: no-cache, max-age=0
        x-content-type-options: nosniff
        date: Thu, 05 Dec 2019 15:00:11 GMT
        server: envoy
        transfer-encoding: chunked

        Sidecar available
        2019-12-05 15:00:12,160 - INFO    - cray.cfs.inventory - Starting CFS Inventory version=0.4.3, namespace=services
        2019-12-05 15:00:12,171 - INFO    - cray.cfs.inventory - Inventory target=dynamic for cfsession=boa-2878e4c0-39c2-4df0-989e-053bb1edee0c
        2019-12-05 15:00:12,227 - INFO    - cray.cfs.inventory.dynamic - Dynamic inventory found a total of 2 groups
        2019-12-05 15:00:12,227 - INFO    - cray.cfs.inventory - Writing out the inventory to /inventory/hosts
        ```

    1. Check the `ansible` container.

        Look towards the end of the Ansible log in the `PLAY RECAP` section to see if any targets failed.
        If a target failed, then look above in the log at the immediately preceding play.
        In the example below, the `ncmp_hsn_cns` role has an issue when being run against the compute nodes.

        ```bash
        kubectl logs -n services "${CFS_POD_NAME}" ansible
        ```

        Example output:

        ```text
        Waiting for Inventory
        Waiting for Inventory
        Inventory available
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
          0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0

        [...]

        TASK [ncmp_hsn_cns : SLES Compute Nodes (HSN): Create/Update ifcfg-hsnx File(s)] ***
        fatal: [x3000c0s19b1n0]: FAILED! => {"msg": "'interfaces' is undefined"}
        fatal: [x3000c0s19b2n0]: FAILED! => {"msg": "'interfaces' is undefined"}
        fatal: [x3000c0s19b3n0]: FAILED! => {"msg": "'interfaces' is undefined"}
        fatal: [x3000c0s19b4n0]: FAILED! => {"msg": "'interfaces' is undefined"}

        NO MORE HOSTS LEFT *************************************************************

        PLAY RECAP *********************************************************************
        x3000c0s19b1n0             : ok=28   changed=20   unreachable=0    failed=1    skipped=77   rescued=0    ignored=1
        x3000c0s19b2n0             : ok=27   changed=19   unreachable=0    failed=1    skipped=63   rescued=0    ignored=1
        x3000c0s19b3n0             : ok=27   changed=19   unreachable=0    failed=1    skipped=63   rescued=0    ignored=1
        x3000c0s19b4n0             : ok=27   changed=19   unreachable=0    failed=1    skipped=63   rescued=0    ignored=1
        ```

Debugging beyond this point is determined by the specific Ansible failure.
If there is not enough information to determine a next step, see the documentation on how to [Increase the Ansible Verbosity](Change_the_Ansible_Verbosity_Logs.md).
