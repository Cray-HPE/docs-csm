# VictoriaMetrics

VictoriaMetrics is a fast, cost-effective, and scalable time series database. It can be used as a long-term remote storage for Prometheus.

It is recommended to use the single-node version instead of the cluster version for ingestion rates lower than a million data points per second. The single-node version scales perfectly with the number of CPU cores, RAM, and available storage space.

## Prominent features

- Supports all the features of the single-node version.
- Performance and capacity scale horizontally.
- Supports multiple independent namespaces for time series data (aka multi-tenancy).
- Supports replication.

## Architecture overview

![Prometheus architecture with Thanos](../../img/operations/VictoriaMetrics_Arcitecture.jpg "VictoriaMetrics Architecture")

VictoriaMetrics cluster consists of the following services:

**Vmstorage:** It stores the raw data and returns the queried data on the given time range for the given label filters. This is the only stateful component in the cluster.

**Vminsert:** It accepts the ingested data and spreads it among `vmstorage` nodes according to consistent hashing over metric name and all its labels.

**Vmselect:** It performs incoming queries by fetching the needed data from all the configured `vmstoragenodes`.
To access `vmselect` GUI, use `ssh` port-forwarding.

1. Use `kubectl` command to get the `SERVICE-IP` of `vmselect-vms` service.

    ```yaml
    kubectl get service -n sysmgmt-health vmselect-vms
    ```
  
   Expected output looks similar to the following:

    ```text
    NAME                               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)              AGE
    vmselect-vms                       ClusterIP       None      <none>        8481/TCP             122d
    ```

2. Use `vmselect-vms` service name and `8481` port number to port forward.

   ```text
   kubectl port-forward -n sysmgmt-health service/vmselect-vms  8481:8481
   ```

3. Use a local laptop or desktop command line to access the cluster.

    Use `ssh` port-forwarding using the service IP.

    ```text
    ssh -L 8481:localhost:8481 root@SYSTEM-IP
    ```

4. Open `http://localhost:8481/select/0/prometheus/vmui/` in the browser to access the GUI.

NOTE: `10.11.12.13` and `SYSTEM-IP` is the IP Address of the host system.

**Vmagent:** It is a tiny but mighty agent which helps you collect metrics from various sources and store them in VictoriaMetrics or any other Prometheus-compatible storage systems that support the `remote_write` protocol.

To access `vmagent` GUI, use `ssh` port-forwarding.

1. Use `kubectl` command to get the `SERVICE-IP` of `cray-sysmgmt-health-thanos-query` service.

    ```yaml
    kubectl get svc -n sysmgmt-health  vmagent-vms
    ```
  
   Expected output looks similar to the following:

    ```text
    NAME                               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)              AGE
    vmagent-vms                        ClusterIP   10.17.40.41   <none>        8429/TCP             6d5h
    ```

2. Use `ssh` port-forwarding using the service IP.

    ```text
    ssh root@SYSTEM-IP -L 9090:SERVICE-IP:9090
    ```

3. Open `localhost:8429` in the browser to access the GUI.

NOTE: In this case `SERVICE-IP` is `10.11.12.13` and `SYSTEM-IP` is the IP Address of the host system.

**Vmalert:** It executes a list of the given alerting or recording rules against configured data sources. Sending alerting notifications `vmalert` relies on configured Alertmanager.
Recording rules results are persisted via remote write protocol. `vmalert` is heavily inspired by Prometheus implementation and aims to be compatible with its syntax.

Each service may scale independently and may run on the most suitable hardware. `vmstorage` nodes do not know about each other, do not communicate with each other and don’t share any data.
This is a shared nothing architecture. It increases cluster availability, and simplifies cluster maintenance as well as cluster scaling.

## Cluster resizing and scalability

Cluster performance and capacity can be scaled up in two ways:

- Vertical scalability:  Adding more resources (CPU, RAM, disk IO, disk space, and so on).
- Horizontal scalability: Adding more of each component to the cluster.
