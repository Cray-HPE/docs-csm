# Repopulate Data in etcd Clusters When Rebuilding Them

When an etcd cluster is not healthy, it needs to be rebuilt. During that process, the pods that rely on etcd clusters lose data.
That data needs to be repopulated in order for the cluster to go back to a healthy state.

- [Repopulate Data in etcd Clusters When Rebuilding Them](#repopulate-data-in-etcd-clusters-when-rebuilding-them)
  - [Applicable services](#applicable-services)
  - [Prerequisites](#prerequisites)
  - [Procedures](#procedures)
    - [BOS](#bos)
    - [BSS](#bss)
    - [CPS](#cps)
    - [FAS](#fas)
    - [HMNFD](#hmnfd)
    - [MEDS](#meds)
    - [REDS](#reds)

## Applicable services

The following services need their data repopulated in the etcd cluster:

- Boot Orchestration Service \(BOS\)
- Boot Script Service \(BSS\)
- Content Projection Service \(CPS\)
- Firmware Action Service \(FAS\)
- HMS Notification Fanout Daemon \(HMNFD\)
- Mountain Endpoint Discovery Service \(MEDS\)
- River Endpoint Discovery Service \(REDS\)

## Prerequisites

An etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

## Procedures

- [BOS](#bos)
- [BSS](#bss)
- [CPS](#cps)
- [FAS](#fas)
- [HMNFD](#hmnfd)
- [MEDS](#meds)
- [REDS](#reds)

### BOS

Reconstruct boot session templates for impacted product streams to repopulate data.

Boot preparation information for other product streams can be found in the following locations:

- UANs: Refer to the UAN product stream repository and search for the "PREPARE UAN BOOT SESSION TEMPLATES" header in the "Install and Configure UANs" procedure.
- Cray Operating System \(COS\): Refer to the "Create a Boot Session Template" header in the "Boot COS" procedure in the COS product stream documentation.

### BSS

Data is repopulated in BSS when the REDS `init` job is run.

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

Repopulate clusters for CPS.

- If there are no clients using CPS when the etcd cluster is rebuilt, then nothing needs to be done other than to rebuild the cluster and make sure all of the components are up and running.
  See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md) for more information.
- If any clients have already mounted content provided by CPS, that content should be unmounted before rebuilding the etcd cluster, and then re-mounted after the etcd cluster is rebuilt.
  Compute nodes that use CPS to access their root file system must be shut down to unmount, and then booted to perform the re-mount.

### FAS

Reload the firmware images from Nexus.

Refer to the `Load Firmware from Nexus` section in [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-nexus) for more information.

When the etcd cluster is rebuilt, all historic data for firmware actions and all recorded snapshots will be lost.
Image data will be reloaded from Nexus.
Any images that were loaded into FAS outside of Nexus will need to be reloaded using the `Load Firmware from RPM or ZIP file` section in
[FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file).
After images are reloaded, any running actions at time of failure will need to be recreated.

### HMNFD

Resubscribe the compute nodes and any NCNs that use the ORCA daemon for their State Change Notifications \(SCN\).

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

(`ncn-mw#`) Restart MEDS.

```bash
kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-meds'
```

### REDS

(`ncn-mw#`) Restart REDS.

```bash
kubectl -n services delete pods --selector='app.kubernetes.io/name=cray-reds'
```
