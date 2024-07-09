# Re-Sync Keycloak Users to Compute Nodes

Resubmit the `keycloak-users-localize` job and run the `keycloak-users-compute.yml` Ansible play to synchronize the users and groups from Keycloak to the compute nodes.
This procedure alters the `/etc/passwd` and `/etc/group` files used on compute nodes.

Use this procedure to quickly synchronize changes made in Keycloak to the compute nodes.

## Prerequisites

The COS product must be installed.

## Procedure

1. Resubmit the `keycloak-users-localize` job.

    The output might appear slightly different than in the example below.

    ```bash
    ncn-mw# kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize -ojson | jq '.items[0]' > keycloak-users-localize-job.json

    ncn-mw# cat keycloak-users-localize-job.json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -
    ```

    Expected output looks similar to the following:

    ```text
    job.batch "keycloak-users-localize-1" deleted
    job.batch/keycloak-users-localize-1 replaced
    ```

1. Watch the pod to check the status of the job.

    The pod will go through the normal Kubernetes states. It will stay in a `Running` state for a while, and then it will go to `Completed`.

    ```bash
    ncn-mw# kubectl get pods -n services | grep keycloak-users-localize
    ```

    Expected output looks similar to the following:

    ```text
    keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
    ```

1. Check the pod's logs.

    Replace the `KEYCLOAK_POD_NAME` value with the pod name from the previous step.

    ```bash
    ncn-mw# kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
    ```

    Expected output should contain the following line:

    ```text
    2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
    ```

1. Synchronize the users and groups from Keycloak to the compute nodes.

    1. Get the `crayvcs` password for pushing the changes.

        ```bash
        ncn-mw# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
        ```

    1. Checkout content from the `cos-config-management` VCS repository.

        ```bash
        ncn-mw# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
        ncn-mw# cd cos-config-management
        ncn-mw# git checkout integration
        ```

    1. Create the `group_vars/Compute/keycloak.yaml` file.

        The file should contain the following contents:

        ```yaml
        ---
        keycloak_config_computes: True
        ```

    1. Push the changes to VCS with the `crayvcs` username.

        ```bash
        ncn-mw# git add group_vars/Compute/keycloak.yaml
        ncn-mw# git commit -m "Configure keycloak on computes"
        ncn-mw# git push origin integration
        ```

    1. Eeboot the compute nodes with the Boot Orchestration Service \(BOS\).

        ```bash
        ncn-mw# cray bos session create --template-uuid BOS_TEMPLATE --operation reboot
        ```
