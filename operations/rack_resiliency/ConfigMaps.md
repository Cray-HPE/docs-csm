# Rack Resiliency ConfigMaps

The Rack Resiliency Service uses two Kubernetes ConfigMaps in the `rack-resiliency` namespace for monitoring and tracking the status of critical services.

The two ConfigMaps are named `rrs-mon-static` (also referred to as the static ConfigMap) and
`rrs-mon-dynamic` (also referred to as the dynamic ConfigMap).

## Function of the ConfigMaps

### Static ConfigMap

- Stores the name and type of all the critical services to be monitored along with their namespaces.
- Stores the monitoring intervals for critical services. This is stored both for ceph services and Kubernetes services.

### Dynamic ConfigMap

This ConfigMap contains information such as the status of critical services, zones, and nodes.
It is populated and used by RRS internally.

During every monitoring interval, the following things are done:

- For each critical service, the following fields are updated:
    - `status`: Configured/ Unconfigured/ Partiallyconfigured
      **Note:**
        - Configured: All pods are running.
        - Unconfigured: No pods running.
        - Partiallyconfigured: Few pods running.
    - `balanced`: true/ false
      **Note:**
          - true: service is spread across zones.
          - false: service is not spread across zones (multiple replicas are in same zone).
    - Zone information is updated for:
        - Kubernetes: name and status of nodes.
        - Ceph: name and status of nodes and OSDs.

## Viewing ConfigMap

### 1. Static ConfigMap

(`ncn-mw#`) View the data of the Static ConfigMap used by the Rack Resiliency service.

```bash
kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq
```

Truncated example output (the actual output of ConfigMap will be larger):

```json
{
    "ceph_monitoring_polling_interval": "60",
    "ceph_monitoring_total_time": "600",
    "ceph_pre_monitoring_delay": "60",
    "critical-service-config.json": "<...omitted from example output...>",
    "default_message_level": "debug",
    "k8s_monitoring_polling_interval": "60",
    "k8s_monitoring_total_time": "600",
    "k8s_pre_monitoring_delay": "40",
    "last_updated_timestamp": "",
    "log_dir": "/var/log/rr",
    "unit_of_time": "seconds"
}
```

### 2. Dynamic ConfigMap

For viewing the data of the Dynamic ConfigMap used by Rack Resiliency service use the below command:

```bash
kubectl get cm -n rack-resiliency rrs-mon-dynamic -o jsonpath='{.data}' | jq
```

Truncated example output (the actual output of ConfigMap will be larger):

```text
{
  "critical-service-config.json": {
    "critical_services": {
      "cilium-operator": {
        "namespace": "kube-system",
        "type": "Deployment",
        "status": "Configured",
        "balanced": "true"
      },
      "cray-capmc": {
        "namespace": "services",
        "type": "Deployment",
        "status": "Configured",
        "balanced": "true"
      },
      "cray-ceph-csi-cephfs-provisioner": {
        "namespace": "ceph-cephfs",
        "type": "Deployment",
        "status": "Configured",
        "balanced": "true"
      },
      "cray-ceph-csi-rbd-provisioner": {
        "namespace": "ceph-rbd",
        "type": "Deployment",
        "status": "Configured",
        "balanced": "false"
      },
    ...
    dynamic-data.yaml: |
    cray_rrs_pod:
      node: ncn-w005
      rack: x3000c0s8b0n0
      zone: x3001
    state:
      ceph_monitoring: ''
      k8s_monitoring: ''
      rms_state: Waiting
    timestamps:
      end_timestamp_ceph_monitoring: ''
      end_timestamp_k8s_monitoring: ''
      init_timestamp: '2025-08-04T17:19:33Z'
      last_update_timestamp: '2025-08-05T12:37:04Z'
      start_timestamp_api: ''
      start_timestamp_ceph_monitoring: ''
      start_timestamp_k8s_monitoring: ''
      start_timestamp_rms: '2025-08-04T17:19:58Z'
    zone:
      ceph_zones:
        x3000: []
        x3001: []
        x3002: []
      k8s_zones:
        x3000:
        - name: ncn-m001
          status: Ready
        - name: ncn-w001
          status: Ready
        - name: ncn-w004
          status: Ready
    }
  }
}
```

HPE provides a standard set of critical services which are needed for the successful execution of user jobs. However, it possible to add additional critical services to the list. For further information on managing the critical services,
refer to [Manage Critical Service](Manage_Critical_Services.md)
