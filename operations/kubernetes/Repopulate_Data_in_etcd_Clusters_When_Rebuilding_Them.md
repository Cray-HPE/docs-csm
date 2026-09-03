# Repopulate Data in etcd Clusters When Rebuilding Them

When an etcd cluster is not healthy, it needs to be rebuilt. During that process, the pods that rely on etcd clusters lose data.
That data needs to be repopulated in order for the cluster to go back to a healthy state.

- [Applicable services](#applicable-services)
- [Prerequisites](#prerequisites)
- [Procedures](#procedures)
    - [BSS](#bss)
    - [CPS](#cps)
    - [CRUS](#crus)
    - [FAS](#fas)
    - [HMNFD](#hmnfd)
    - [MEDS](#meds)
    - [REDS](#reds)

## Applicable services

The following services need their data repopulated in the etcd cluster:

- [Boot Script Service (BSS)][bss]
- [Content Projection Service (CPS)][cps]
- [Compute Rolling Upgrade Service (CRUS)][crus]
- [Firmware Action Service (FAS)][fas]
- [HMS Notification Fanout Daemon (HMNFD)][hmnfd]
- [Mountain Endpoint Discovery Service (MEDS)][meds]
- [River Endpoint Discovery Service (REDS)][reds]

## Prerequisites

An etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

## Procedures

- [BSS](#bss)
- [CPS](#cps)
- [CRUS](#crus)
- [FAS](#fas)
- [HMNFD](#hmnfd)
- [MEDS](#meds)
- [REDS](#reds)

### BSS

Data is repopulated in [BSS][bss] when the [REDS][reds] `init` job is run.

1. (`ncn-mw#`) Get the current REDS job.

    ```bash
    kubectl get -o json -n services job/cray-reds-init |
            jq 'del(.spec.template.metadata.labels["controller-uid"], .spec.selector)' > cray-reds-init.json
    ```

1. (`ncn-mw#`) Delete the `reds-client-init` job.

    ```bash
    kubectl delete -n services -f cray-reds-init.json
    ```

1. (`ncn-mw#`) Restart the `reds-client-init` job.

    ```bash
    kubectl apply -n services -f cray-reds-init.json
    ```

### CPS

Repopulate clusters for [CPS].

- If there are no clients using CPS when the etcd cluster is rebuilt, then nothing needs to be done other than to rebuild the cluster and make sure all of the components are up and running.
  See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md) for more information.
- If any clients have already mounted content provided by CPS, that content should be unmounted before rebuilding the etcd cluster, and then re-mounted after the etcd cluster is rebuilt.
  [Compute nodes][cn] that use CPS to access their root file system must be shut down to unmount, and then booted to perform the re-mount.

### CRUS

> **NOTE** [CRUS][crus] was deprecated in CSM 1.2.0 and it will be removed in CSM 1.5.0.
> See the following links for more information:
>
> - [Rolling Upgrades with BOS V2](../boot_orchestration/Rolling_Upgrades.md)
> - [Deprecated Features](../../introduction/deprecated_features/README.md)

1. (`ncn-mw#`) View the progress of existing CRUS sessions.

    1. List the existing CRUS sessions to find the `upgrade_id` for the desired session.

        ```bash
        cray crus session list --format toml
        ```

        Example output:

        ```toml
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

    1. Describe the CRUS session to see if the session failed or is stuck.

        If the session continued and appears to be in a healthy state, proceed to the [BSS](#bss) section.

        ```bash
        cray crus session describe CRUS_UPGRADE_ID --format toml
        ```

        Example output:

        ```toml
        api_version = "1.0.0"
        completed = false
        failed_label = "failed-nodes"
        kind = "ComputeUpgradeSession"
        messages = [ "Quiesce requested in step 0: moving to QUIESCING", "All nodes quiesced in step 0: moving to QUIESCED", "Began the boot session for step 0: moving to BOOTING",]
        starting_label = "slurm-nodes"
        state = "UPDATING"
        upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242"
        upgrade_step_size = 50
        upgrade_template_id = "boot-template"
        upgrading_label = "upgrading-nodes"
        workload_manager_type = "slurm"
        ```

1. (`ncn-mw#`) Find the name of the running CRUS pod.

    ```bash
    kubectl get pods -n services | grep cray-crus
    ```

    Example output:

    ```text
    cray-crus-549cb9cb5d-jtpqg                                   3/4     Running   528        25h
    ```

1. (`ncn-mw#`) Restart the CRUS pod.

    Deleting the pod will restart CRUS and start the discovery process for any data recovered in etcd.

    ```bash
    kubectl delete pods -n services POD_NAME
    ```

### FAS

Reload the firmware images from Nexus.

Refer to the `Load Firmware from Nexus` section in [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-nexus) for more information.

When the etcd cluster is rebuilt, all historic data for firmware actions and all recorded snapshots will be lost.
Image data will be reloaded from Nexus.
Any images that were loaded into [FAS][fas] outside of Nexus will need to be reloaded using the `Load Firmware from RPM or ZIP file` section in
[FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file).
After images are reloaded, any running actions at time of failure will need to be recreated.

### HMNFD

Resubscribe the [compute nodes][cn] and any [NCNs][ncn] that use the ORCA daemon for their State Change Notifications (SCN).

1. (`ncn-m#`) Resubscribe all compute nodes.

    ```bash
    TMPFILE=$(mktemp)
    sat status --no-borders --no-headings | grep Ready | grep Compute | awk '{printf("nid%06d-nmn\n",$4);}' > "${TMPFILE}"
    pdsh -w ^"${TMPFILE}" "systemctl restart cray-orca"
    rm -rf "${TMPFILE}"
    ```

1. (`ncn-m#`) Resubscribe all worker nodes.

    **NOTE:** Modify the `-w` arguments in the following commands to reflect the number of worker nodes in the system.

    ```bash
    pdsh -w ncn-w00[1-4]-can.local "systemctl restart cray-orca"
    ```

### MEDS

(`ncn-mw#`) Restart [MEDS][meds].

```bash
kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-meds'
```

### REDS

(`ncn-mw#`) Restart [REDS][reds].

```bash
kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-reds'
```

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../configure_cray_cli.md
[check-latest-docs]: ../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../glossary.md#ansible-execution-environment-aee
[an]: ../../glossary.md#application-node-an
[ara]: ../../glossary.md#ara-records-ansible-ara
[bmc]: ../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../glossary.md#boot-orchestration-service-bos
[bss]: ../../glossary.md#boot-script-service-bss
[can]: ../../glossary.md#customer-access-network-can
[canu]: ../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../glossary.md#configuration-framework-service-cfs
[chn]: ../../glossary.md#customer-high-speed-network-chn
[cli]: ../../glossary.md#cray-cli-cray
[cmn]: ../../glossary.md#customer-management-network-cmn
[cn]: ../../glossary.md#compute-node-cn
[cps]: ../../glossary.md#content-projection-service-cps
[crus]: ../../glossary.md#compute-rolling-upgrade-service-crus
[csi]: ../../glossary.md#cray-site-init-csi
[fas]: ../../glossary.md#firmware-action-service-fas
[hbtd]: ../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../glossary.md#high-speed-network-hsn
[ims]: ../../glossary.md#image-management-service-ims
[iuf]: ../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../glossary.md#management-nodes
[mountain]: ../../glossary.md#mountain-cabinet
[nc]: ../../glossary.md#node-controller-nc
[ncn]: ../../glossary.md#non-compute-node-ncn
[nid]: ../../glossary.md#node-id-nid
[nmd]: ../../glossary.md#node-memory-dump-nmd
[nmn]: ../../glossary.md#node-management-network-nmn
[pcs]: ../../glossary.md#power-control-service-pcs
[pdu]: ../../glossary.md#power-distribution-unit-pdu
[pit]: ../../glossary.md#pre-install-toolkit-pit
[reds]: ../../glossary.md#river-endpoint-discovery-service-reds
[river]: ../../glossary.md#river-cabinet
[rts]: ../../glossary.md#redfish-translation-service-rts
[s3]: ../../glossary.md#simple-storage-service-s3
[sat]: ../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../glossary.md#system-configuration-service-scsd
[sdu]: ../../glossary.md#system-diagnostic-utility-sdu
[shcd]: ../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../glossary.md#slingshot
[sls]: ../../glossary.md#system-layout-service-sls
[sma]: ../../glossary.md#system-monitoring-application-sma
[smd]: ../../glossary.md#hardware-state-manager-smd
[sops]: ../../glossary.md#secrets-operations-sops
[tapms]: ../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../glossary.md#user-access-node-uan
[uss]: ../../glossary.md#user-services-software-uss
[vcs]: ../../glossary.md#version-control-service-vcs
[vnid]: ../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../glossary.md#xname

<!-- markdownlint-restore -->
