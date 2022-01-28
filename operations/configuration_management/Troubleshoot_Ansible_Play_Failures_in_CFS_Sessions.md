## Troubleshoot Ansible Play Failures in CFS Sessions

View the Kubernetes logs for a Configuration Framework Service \(CFS\) pod in an error state to determine whether the error resulted from the CFS infrastructure or from an Ansible play that was run by a specific configuration layer in a CFS session.

Use this procedure to obtain important triage information for Ansible plays being called by CFS.

### Prerequisites

A configuration session exists for CFS.

### Procedure

1.  Find the CFS pod that is in an error state.

    In the example below, the $CFS\_POD\_NAME is cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn.

    ```bash
    ncn# kubectl get pods -n services $CFS_POD_NAME
    ```

    Example output:

    ```
    NAME                                             READY   STATUS   RESTARTS   AGE
    cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn   0/3     Error    0          25h
    ```

2.  Check to see what containers are in the pod.

    ```bash
    ncn# kubectl logs -n services $CFS_POD_NAME
    ```

    Example output:

    ```
    Error from server (BadRequest): a container name must be specified for pod cfs-e8e48c2a-448f-4e6b-86fa-dae534b1702e-pnxmn, choose one of: [inventory ansible-0 istio-proxy] or one of the init containers: [git-clone-0 istio-init]
    ```

    Issues rarely occur in the istio-init and istio-proxy containers. These containers can be ignored for now.

3.  Check the git-clone-0, inventory, ansible-0 containers in that order.

    1.  Check the git-clone-0 container.

        ```bash
        ncn# kubectl logs -n services CFS_POD_NAME git-clone-0
        ```

    2.  Check the inventory container.

        ```bash
        # kubectl logs -n services CFS_POD_NAME inventory
        ```

        Example output:

        ```
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

    3.  Check the ansible-0 container.

        Look towards the end of the Ansible log in the PLAY RECAP section to see if any have failed. If it failed, look above at the immediately preceding play. In the example below, the ncmp\_hsn\_cns role has an issue when being run against the compute nodes.

        ```bash
        ncn# kubectl logs -n services CFS_POD_NAME ansible-0
        ```

        Example output:

        ```
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


Run the Ansible play again once the underlying issue has been resolved.



