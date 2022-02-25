## Repopulate Data in etcd Clusters When Rebuilding Them

When an etcd cluster is not healthy, it needs to be rebuilt. During that process, the pods that rely on etcd clusters lose data. That data needs to be repopulated in order for the cluster to go back to a healthy state.

The following services need their data repopulated in the etcd cluster:

-   Boot Orchestration Service \(BOS\)
-   Boot Script Service \(BSS\)
-   Content Projection Service \(CPS\)
-   Compute Rolling Upgrade Service \(CRUS\)
-   External DNS
-   Firmware Action Service \(FAS\)
-   HMS Notification Fanout Daemon \(HMNFD\)
-   Mountain Endpoint Discovery Service \(MEDS\)
-   River Endpoint Discovery Service \(REDS\)

### Prerequisites

A etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).


### BOS

1.  Reconstruct boot session templates for impacted product streams to repopulate data.

    Boot preparation information for other product streams can be found in the following locations:

    -   UANs: Refer to the UAN product stream repository and search for the "PREPARE UAN BOOT SESSION TEMPLATES" header in the "Install and Configure UANs" procedure.
    -   Cray Operating System \(COS\): Refer to the "Create a Boot Session Template" header in the "Boot COS" procedure in the COS product stream documentation.


### CPS

1.  Repopulate clusters for CPS.

    -   If there are no clients using CPS when the etcd cluster is rebuilt, then nothing needs to be done other than to rebuild the cluster and make sure all of the components are up and running. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md) for more information.
    -   If any clients have already mounted content provided by CPS, that content should be unmounted before rebuilding the etcd cluster, and then re-mounted after the etcd cluster is rebuilt. Compute nodes that use CPS to access their root file system must be shut down to unmount, and then booted to perform the re-mount.


### CRUS

1.  View the progress of existing CRUS sessions.

    1.  List the existing CRUS sessions to find the upgrade\_id for the desired session.

        ```bash
        ncn-w001# cray crus session list
        [[results]]
        api_version = "1.0.0"
        completed = false
        failed_label = "failed-nodes"
        kind = "ComputeUpgradeSession"
        messages = [ "Quiesce requested in step 0: moving to QUIESCING", "All nodes quiesced in step 0: moving to QUIESCED", "Began the boot session for step 0: moving to BOOTING",]
        starting_label = "slurm-nodes"
        state = "UPDATING"
        upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242" <<-- Note this value
        upgrade_step_size = 50
        upgrade_template_id = "boot-template"
        upgrading_label = "upgrading-nodes"
        workload_manager_type = "slurm"
        ```

    2.  Describe the CRUS session to see if the session failed or is stuck.

        If the session continued and appears to be in a healthy state, proceed to the [BSS](#bss) section.

        ```bash
        ncn-w001# cray crus session describe CRUS_UPGRADE_ID
        api_version = "1.0.0"
        completed = false
        failed_label = "failed-nodes"
        kind = "ComputeUpgradeSession"
        messages = [ "Quiesce requested in step 0: moving to QUIESCING", "All nodes quiesced in step 0:
        moving to QUIESCED", "Began the boot session for step 0: moving to BOOTING",]
        starting_label = "slurm-nodes"
        state = "UPDATING"
        upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242"
        upgrade_step_size = 50
        upgrade_template_id = "boot-template"
        upgrading_label = "upgrading-nodes"
        workload_manager_type = "slurm"
        ```

2.  Find the name of the running CRUS pod.

    ```bash
    ncn-w001# kubectl get pods -n services | grep cray-crus
    cray-crus-549cb9cb5d-jtpqg                                   3/4     Running   528        25h
    ```

3.  Restart the CRUS pod.

    Deleting the pod will restart CRUS and start the discovery process for any data recovered in etcd.

    ```bash
    ncn-w001# kubectl delete pods -n services POD_NAME
    ```


### External DNS

The etcd cluster for external DNS maintains an ephemeral cache for CoreDNS. There is no reason to back it up. If it is having any issues, delete it and recreate it.

1.  Save the external DNS configuration.

2.  Edit the end of each .yaml file to remove the .status, .metadata.uid, .metadata.selfLink, .metadata.resourceVersion, .metadata.generation, and .metadata.creationTimestamp.

    For example:

    ```bash
    apiVersion: etcd.database.coreos.com/v1beta2
    kind: EtcdCluster
    metadata:
      annotations:
        etcd.database.coreos.com/scope: clusterwide
      labels:
        app.kubernetes.io/name: cray-externaldns-etcd
      name: cray-externaldns-etcd
      namespace: services
    spec:
      pod:
        ClusterDomain: ""
        annotations:
          sidecar.istio.io/inject: "false"
        busyboxImage: registry.local/library/busybox:1.28.0-glibc
        persistentVolumeClaimSpec:
          accessModes:
          - ReadWriteOnce
          dataSource: null
          resources:
            requests:
              storage: 1Gi
        resources: {}
      repository: registry.local/coreos/etcd
      size: 3
      version: 3.3.8
    ```

3.  Delete the current cluster.

    ```bash
    ncn-w001# kubectl -n services delete etcd cray-externaldns-etcd
    ```

4.  Recreate the cluster.

    ```bash
    ncn-w001# kubectl apply -f cray-externaldns-etcd.yaml
    ```


<a name="bss"></a>

### BSS

Data is repopulated in BSS when the REDS init job is run.

1.  Get the current REDS job.

    ```bash
    ncn-w001# kubectl get -o json -n services job/cray-reds-init | \
    jq 'del(.spec.template.metadata.labels["controller-uid"], .spec.selector)' > cray-reds-init.json
    ```

2. Delete the reds-client-init job.

    ```bash
    ncn-w001# kubectl delete -n services -f cray-reds-init.json
    ```

3.  Restart the reds-client-init job.

    ```bash
    ncn-w001# kubectl apply -n services -f cray-reds-init.json
    ```

### REDS

1.  Restart REDS.

    ```bash
    ncn-w001# kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-reds'
    ```


### MEDS

1.  Restart MEDS.

    ```bash
    ncn-w001# kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-meds'
    ```

### FAS

1.  Run the `cray-fas-loader` Kubernetes job.

    Refer to the "Use the `cray-fas-loader` Kubernetes Job" section in [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) for more information.

    When the etcd cluster is rebuilt, all historic data for firmware actions and all recorded snapshots will be lost. Image data will need to be reloaded by following the `cray-fas-loader` Kubernetes job procedure. After images are reloaded any running actions at time of failure will need to be recreated.


### HMNFD

1.  Resubscribe the compute nodes and any NCNs that use the ORCA daemon for their State Change Notifications \(SCN\).

    1.  Resubscribe all compute nodes.

        ```bash
        ncn-m001# TMPFILE=$(mktemp)
        ncn-m001# sat status --no-borders --no-headings | grep Ready | grep Compute | awk '{printf("nid%06d-nmn\n",$3);}' > $TMPFILE

        ncn-m001# pdsh -w ^${TMPFILE} "systemctl restart cray-dvs-orca"

        ncn-m001# rm -rf $TMPFILE
        ```

    2.  Resubscribe the NCNs.

        ```bash
        ncn-m001# pdsh -w ncn-w00[0-4]-can.local "systemctl restart cray-dvs-orca"
        ncn-m001# pdsh -w ncn-s00[0-4]-can.local "systemctl restart cray-dvs-orca"
        ```

        Note: on larger systems, [0-4] may have to be a larger range.



