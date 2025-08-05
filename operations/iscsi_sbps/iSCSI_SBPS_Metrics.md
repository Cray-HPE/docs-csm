# iSCSI SBPS Metrics

The information on this page assumes that
[Node personalization](iSCSI_SBPS_Verification.md#node-personalization) has completed successfully
and that the [SBPS Marshal Agent](iSCSI_SBPS_Verification.md#sbps-marshal-agent) is running without
errors on all [iSCSI-enabled workers](iSCSI_SBPS_Verification.md#iscsi-enabled-workers).
See [iSCSI SBPS Verification](iSCSI_SBPS_Verification.md) for more details.

* [Overview](#overview)
* [Metric sources](#metric-sources)
    * [`sysfs`](#sysfs)
        * [`sysfs` megabytes read](#sysfs-megabytes-read)
        * [`sysfs` read IOPS](#sysfs-read-iops)
    * [`saveconfig.json`](#saveconfigjson)
* [Retrieve iSCSI metrics](#retrieve-iscsi-metrics)
    * [Command line](#command-line)
    * [VictoriaMetrics web UI](#victoriametrics-web-ui)
    * [Grafana web UI](#grafana-web-ui)

## Overview

iSCSI-based boot content projection is a read-only projection. Metrics related to projection are exported to the node exporter / Prometheus.

* Megabytes read
* Read I/O per second (IOPs)
* Number of projected `rootfs` LUNs
* Number of projected PE LUNs
* Throughput statistics on LIO portal network endpoints

## Metric sources

### `sysfs`

Megabytes read and read IOPS are retrieved from `sysfs` on each worker node.

#### `sysfs` megabytes read

(`ncn-w#`) Megabytes read are found in the `read_mbytes` files.

```bash
cat /sys/kernel/config/target/iscsi/iqn.2023-06.csm.iscsi:ncn-w002/tpgt_1/lun/lun_0/statistics/scsi_tgt_port/read_mbytes
```

Example output:

```text
137
```

#### `sysfs` read IOPS

(`ncn-w#`) Read IOPS are found in the `in_cmds` files.

```bash
cat /sys/kernel/config/target/iscsi/iqn.2023-06.csm.iscsi:ncn-w002/tpgt_1/lun/lun_0/statistics/scsi_tgt_port/in_cmds
```

Example output:

```text
2938
```

### `saveconfig.json`

The number of projected `rootfs` and PE `LUNs` are determined based on the data in `/etc/target/saveconfig.json` on the worker NCNs.

## Retrieve iSCSI metrics

iSCSI metrics can be retrieved on an individual worker node on the command line, or through a web interface.

### Command line

The command line can be used to retrieve any of the metrics listed in the [Overview](#overview) except the throughput statistics.
The same basic command is used to retrieve each of these metrics, with only the query value changing based on which
metric is desired.

| *Metric*                   | *Query*                |
| -------------------------- | ---------------------- |
| MB read                    | `iscsi_read_mbytes`    |
| Read IOPS                  | `iscsi_read_rate`      |
| \# projected `rootfs` LUNs | `iscsi_rootfs_lun_cnt` |
| \# projected PE LUNs       | `iscsi_pe_lun_cnt`     |

(`ncn-mw#`) For example, show the number of megabytes read.

```bash
kubectl exec -n services cray-shared-kafka-kafka-0 -it -- curl -G \
    'http://vmselect-vms.sysmgmt-health.svc.cluster.local:8481/select/0/prometheus/api/v1/query?query=iscsi_read_mbytes' | jq
```

### VictoriaMetrics web UI

The VictoriaMetrics web UI can be used to retrieve any of the metrics listed in the [Overview](#overview) except the throughput statistics.

In the VictoriaMetrics UI, query for `iscsi` metrics. For details on how to access the UI, see
[VictoriaMetrics](../system_management_health/Access_System_Management_Health_Services.md#victoriametrics).

### Grafana web UI

Throughput statistics on LIO portal network endpoints can be viewed on Grafana `prometheus` dashboards.
For details on accessing the Grafana web UI, see
[Grafana](../system_management_health/Access_System_Management_Health_Services.md#grafana).

In the Grafana web UI, the metrics can be found under General metrics, Node Exporter Full.
For Job, select `node-exporter`.
For Host, select any worker NCN (for example, `ncn-w001`).
Under this, the following metrics may be monitored: `recv hsn0`, `trans hsn0`, `recv nmn0`, and `trans nmn0`.

These metrics can be monitored during iSCSI LUN projection from iSCSI targets to iSCSI initiators during managed node boot time.
