# Rack Resiliency ConfigMaps

The Rack Resiliency Service uses two Kubernetes ConfigMaps in the `rack-resiliency` namespace for
monitoring and tracking the status of critical services.

The two ConfigMaps are named `rrs-mon-static` (also referred to as the static ConfigMap) and
`rrs-mon-dynamic` (also referred to as the dynamic ConfigMap).

## Function of the ConfigMaps

### Static ConfigMap

- Stores the name and type of all the critical services to be monitored along with their namespaces.
- Stores the monitoring intervals for critical services. This is stored both for Ceph services and
  Kubernetes services.

### Dynamic ConfigMap

This ConfigMap contains information such as the status of critical services, zones, and nodes.
It is populated and used by RRS internally.

During every monitoring interval, the following things are done:

- For each critical service, the following fields are updated:
    - `status`
        - `Configured`: All pods of the service are running.
        - `PartiallyConfigured`: At least one pod of the service is running, but not all.
        - `Unconfigured`: No pods of the service are running.
    - `balanced`
        - `true`: The service is spread across zones.
        - `false`: The service is not spread across zones (i.e. multiple replicas are in the same zone).
- Zone information is updated for:
    - Kubernetes: name and status of nodes.
    - Ceph: name and status of nodes and OSDs.

## Viewing ConfigMap

### 1. Static ConfigMap

(`ncn-mw#`) View the data of the static ConfigMap used by the Rack Resiliency service.

Because the `critical-service-config.json` data field contains a large JSON string,
the data is most easily displayed in two parts.

- Show every data field except `critical-service-config.json`.

    ```bash
    kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq 'del(."critical-service-config.json")'
    ```

    Example output:

    ```json
    {
      "ceph_monitoring_polling_interval": "60",
      "ceph_monitoring_total_time": "600",
      "ceph_pre_monitoring_delay": "60",
      "default_message_level": "debug",
      "k8s_monitoring_polling_interval": "60",
      "k8s_monitoring_total_time": "600",
      "k8s_pre_monitoring_delay": "40",
      "last_updated_timestamp": "",
      "log_dir": "/var/log/rr",
      "unit_of_time": "seconds"
    }
    ```

- Show the `critical-service-config.json` field.

    ```bash
    kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data.critical-service-config\.json}' | jq
    ```

    Truncated example output (the actual output will be larger):

    ```json
    {
      "critical_services": {
        "cilium-operator": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "...<output truncated>...",
        "cray-capmc": {
          "namespace": "services",
          "type": "Deployment"
        },
        "kube-proxy": {
          "namespace": "kube-system",
          "type": "StatefulSet"
        }
      }
    }
    ```

### 2. Dynamic ConfigMap

(`ncn-mw#`) View the data of the dynamic ConfigMap used by the Rack Resiliency service.

The dynamic ConfigMap contains two fields, both of which contain large strings;
`critical-service-config.json` contains a large JSON string
and `dynamic-data.yaml` contains a large YAML string.

- Show the `critical-service-config.json` field.

    ```bash
    kubectl get cm -n rack-resiliency rrs-mon-dynamic -o jsonpath='{.data.critical-service-config\.json}' | jq
    ```

    Truncated example output (the actual output will be larger):

    ```json
    {
      "critical_services": {
        "cilium-operator": {
          "namespace": "kube-system",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        "...<output truncated>...",
        "cray-activemq-artemis-operator-controller-manager": {
          "namespace": "dvs",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        "kube-proxy": {
          "namespace": "kube-system",
          "type": "StatefulSet",
          "status": "Unconfigured",
          "balanced": "NA"
        }
      }
    }
    ```

- Show the `dynamic-data.yaml` field.

    ```bash
    kubectl get cm -n rack-resiliency rrs-mon-dynamic -o jsonpath='{.data.dynamic-data\.yaml}'
    ```

    Truncated example output (the actual output will be larger):

    ```yaml
    cray_rrs_pod:
      node: ncn-w004
      rack: x3000c0s31b0n0
      zone: x3000
    state:
      ceph_monitoring: ''
      k8s_monitoring: ''
      rms_state: Waiting
    timestamps:
      end_timestamp_ceph_monitoring: ''
      end_timestamp_k8s_monitoring: ''
      init_timestamp: '2025-08-04T04:17:17Z'
      last_update_timestamp: '2025-08-07T02:56:28Z'
      start_timestamp_api: ''
      start_timestamp_ceph_monitoring: ''
      start_timestamp_k8s_monitoring: ''
      start_timestamp_rms: '2025-08-04T04:17:25Z'
    zone:
      ceph_zones:
        x3000:
        - name: ncn-s001
          osds:
          - name: osd.1
            status: up
          - name: osd.4
            status: up
          - name: osd.7
            status: up
          - name: osd.10
            status: up
        #...output truncated...
      k8s_zones:
        x3000:
        - name: ncn-m001
          status: Ready
        - name: ncn-w001
          status: Ready
        - name: ncn-w004
          status: Ready
        #...output truncated...
    ```

HPE provides a standard set of critical services which are needed for the successful execution of user jobs.
However, it possible to add additional critical services to the list. For more information on managing the
critical services, see [Manage Critical Service](Manage_Critical_Services.md).
