# Update IMS Job Access Network
   In the CSM V1.2.0 and V1.2.1 releases, the IMS jobs template was set up with the wrong
   service address pool. This means that the IMS job pods are unable to start on the
   customer-management network where they have permission to run.

   To fix this on a running system, the `ims-config` configmap will need to updated to use
   the correct address pool when starting jobs.

   **IMPORTANT:** Once this procedure has been done, it will not fix jobs that are currently
   running. This will only impact new jobs created after the settings have been updated. Old 
   jobs that can not be accessed must be deleted and recreated.

## Procedure

1. Enter into editing mode for the `ims-config` settings.

    ```bash
    ncn-mw# kubectl -n services edit cm ims-config
    ```

2. Find the `JOB_CUSTOMER_ACCESS_NETWORK_ACCESS_POOL` variable and edit the value to:

    ```text
      JOB_CUSTOMER_ACCESS_NETWORK_ACCESS_POOL: customer-management
    ```

3. Exit the editor, saving the new value.

4. Restart the cray-ims pod.

    ```bash
    ncn-mw# IMS_POD=$(kubectl get pods -n services -o wide | grep cray-ims | awk '{print $1}')
    ncn-mw# kubectl -n services delete pod $IMS_POD
    ```

5. Wait for the new pod to be ready.

    ```bash
      ncn-mw# watch 'kubectl -n services get pods | grep cray-ims'
    ```

    Watch the status of the pod, you should see something like:

    ```text
    cray-ims-fbc5c5b45-lq4h7   0/2  PodInitializing 0 10s
    ```

    When it transitions to `2/2  Running`, use `Ctl-c` to exit the `watch` command.

6. New jobs will now be created with the correct network settings.
