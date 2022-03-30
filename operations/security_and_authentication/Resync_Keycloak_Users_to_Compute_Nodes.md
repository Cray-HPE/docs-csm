# Re-Sync Keycloak Users to Compute Nodes

Resubmit the `keycloak-users-localize` job and run the keycloak-users-compute.yml Ansible play to sync the users and groups from Keycloak to the compute nodes. This procedure alters the /etc/passwd and /etc/group files used on compute nodes.

Use this procedure to quickly synchronize changes made in Keycloak to the compute nodes.

### Procedure

1.  Resubmit the `keycloak-users-localize` job.

    The output might appear slightly different than in the example below.

    ```bash
    ncn-w001# kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize \
    -ojson | jq '.items[0]' > keycloak-users-localize-job.json

    ncn-w001# cat keycloak-users-localize-job.json | jq 'del(.spec.selector)' | \
    jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -
    job.batch "keycloak-users-localize-1" deleted
    job.batch/keycloak-users-localize-1 replaced
    ```

2.  Watch the pod to check the status of the job.

    The pod will go through the normal Kubernetes states. It will stay in a Running state for a while, and then it will go to Completed.

    ```bash
    ncn-w001# kubectl get pods -n services | grep keycloak-users-localize
    keycloak-users-localize-1-sk2hn                                0/2     Completed   0          2m35s
    ```

3.  Check the pod's logs.

    Replace the KEYCLOAK\_POD\_NAME value with the pod name from the previous step.

    ```bash
    ncn-w001# kubectl logs -n services KEYCLOAK_POD_NAME keycloak-localize
    <logs showing it has updated the "s3" objects and ConfigMaps>
    2020-07-20 18:26:15,774 - INFO    - keycloak_localize - keycloak-localize complete
    ```

4.  Sync the users and groups from Keycloak to the compute nodes.

    1.  Get the crayvcs password for pushing the changes.

        ```bash
        ncn-w001# kubectl get secret -n services vcs-user-credentials \
        --template={{.data.vcs_password}} | base64 --decode
        ```

    2.  Checkout content from the cos-config-management VCS repository.

        ```bash
        ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
        ncn-w001# cd cos-config-management
        ncn-w001# git checkout integration
        ```

    3.  Create the group\_vars/Compute/keycloak.yaml file.

        The file should contain the following values:

        ```bash
        ---
        keycloak_config_computes: True
        ```

    4.  Push the changes to VCS with the crayvcs username.

        ```bash
        ncn-w001# git add group_vars/Compute/keycloak.yaml
        ncn-w001# git commit -m "Configure keycloak on computes"
        ncn-w001# git push origin integration
        ```

    5.  Do a reboot with the Boot Orchestration Service \(BOS\).

        ```bash
        ncn-w001# cray bos session create --template-uuid BOS_TEMPLATE --operation reboot
        ```

