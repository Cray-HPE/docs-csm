# Rack Resiliency (RR)

* [Introduction](#introduction)
* [Key Terminology](#key-terminology)
* [Objective of Rack Resiliency](#objective-of-rack-resiliency)
* [Architecture Overview](#architecture-overview)
    * [Management plane placement discovery and placement validation](management_plane_discovery_and_validation.md)
    * [Spreading of NCNs across Kubernetes zones, and spreading storage nodes across Ceph zones](spreading_NCNs_across_k8s_and_ceph_zones.md)
    * [Distribution of critical services across zones](distribution_of_critical_services_across_zones.md)
    * [Monitoring failures and ensuring critical services are available across zones](monitor_and_ensure_critical_service_availability.md)
* [Components of Rack Resiliency](#components-of-rack-resiliency)
    * [Critical Services](README.md#1-critical-services)
    * [Static ConfigMap`](README.md#2-static-configmap)
    * [Dynamic ConfigMap`](README.md#3-dynamic-configmap)
    * [Rack Resiliency Service (RRS)](README.md#4-rack-resiliency-service-rrs)
    * [Kyverno Policy](README.md#5-kyverno-policy)
* [Rack Resiliency Management Tools](#rack-resiliency-management-tools)
* [Rack Resiliency Management Tasks](#rack-resiliency-management-tasks)
    * [Enable and Configure Rack Resiliency](README.md#1-enable-and-configure-rack-resiliency)
    * [Managing Critical Services](README.md#2-managing-critical-services)
    * [Managing `Kyverno` Policy](README.md#3-managing-kyverno-policy)
* [Troubleshooting](#troubleshooting)

# Introduction

HPE Cray EX systems are engineered to ensure services critical to the execution of user jobs, remain resilient, even if management nodes (Master, Worker, and Storage nodes) fail, provided that the minimum quorum of nodes required for high availability (HA) is maintained, user jobs will remain unaffected.

Despite these methods of software resiliency, rack-level failures can cause service disruptions if management nodes running critical services are concentrated within a single rack. The loss of critical management services can occur when multiple nodes located in the same rack fail, resulting in the loss of the quorum necessary for HA. To mitigate this, we need to physically place management nodes across racks, then ensure CSM service replicas are evenly instantiated across those nodes. However, Kubernetes does not inherently recognize the physical distribution of nodes across different racks – it needs to be configured using its zone-awareness features.

To address these issues, the Rack Resiliency feature is introduced in CSM 1.7.0. It provides management rack level resiliency by providing methods and functionality required to maintain the HA of critical management services due to a single rack failure. This feature ensures that CSM can tolerate failures of racks and prevent a system-wide outage, where such outage encompasses the inability for completing current jobs or scheduling new ones. This feature doesn't address planned downtime of racks.

A similar problem emerges for utility storage on management storage nodes. Even though these are not orchestrated by Kubernetes, incorrect physical placement or software configuration, specifically around replication, may cause utility storage service disruptions in the event of rack-level failures.

**NOTE**: The Rack Resiliency feature is disabled by default. Administrators must enable it during the install or upgrade to CSM 1.7, as explained in the [Enabling Rack Resiliency Feature](#1-enable-and-configure-rack-resiliency).

# Key Terminology

* Rack: Hosting multiple management nodes (`NCN-Ms`, `NCN-Ws`, `NCN-Ss`) and Network switches etc.,
* Zone: A zone represents a logical failure domain. It is common for Kubernetes clusters to span multiple zones for increased availability.
* Failure Domain: Failure domains are zones which includes infrastructure that provides availability for CSM services.
* MPFD: Management Plane Failure Domain
* Placement: Arrangement of Management Nodes across racks. Note that zone awareness primitives in Kubernetes refer to this as "topology".
* Kubernetes topology zones: You can use topology spread constraints to control how pods are spread across cluster among failure-domains such as regions, zones, nodes,
  and other user-defined topology domains. This can help to achieve high availability as well as efficient resource utilization.
* Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the
  management services running on Kubernetes, as well as for telemetry data coming from the compute nodes.
* Critical services: Critical services are those services that are critical to execution of user jobs. These services are critical because the user plane / jobs require
  a timely response from these services for continued operations. Therefore, in the context of a rack failure, it is crucial that such services are distributed across racks.
* Platform services: These services host the platform on which CSM runs and provide the infrastructure for running those services which are critical for user jobs.
          
# Objective of Rack Resiliency

To enable CSM to tolerate failure of racks and prevent a system-wide outage, where such outage encompasses the inability for completing current jobs or scheduling new ones.
The RR solution provides the ability to distribute and monitor critical services to tolerate single rack failures.

## Role of CSM services and it's relationship to user jobs

User jobs are computational tasks running on compute node(s) via work load managers(`WLMs`) like SLURM/ PBS. CSM services support 
the execution of user jobs by providing the infrastructure needed. Those services which are critical to the execution of the 
user jobs are called critical services.

In the context of a rack failure, it is crucial that critical services continue to operate and provide the support needed to execute user jobs.

# Architecture Overview

The Rack Resiliency solution is implemented in 4 stages. The 4 stages are:

* [Management plane placement discovery and placement validation](management_plane_discovery_and_validation.md)
* [Spreading of NCNs across Kubernetes zones, and spreading storage nodes across Ceph zones](spreading_NCNs_across_k8s_and_ceph_zones.md)
* [Distribution of critical services across zones](distribution_of_critical_services_across_zones.md)
* [Monitoring failures and ensuring critical services are available across zones](monitor_and_ensure_critical_service_availability.md)

![Rack Resiliency solution overview](../../img/rack-resiliency-1.png)

# Components of Rack Resiliency

## 1. Critical Services

CSM services provide various functionalities which manage the platform infrastructure as well as support the successful execution of user jobs.
These services interact between themselves providing the necessary support to run the user jobs. These services are configured in `Kubernetes` as
Deployments/ StatefulSets/ DaemonSets/ Singleton. 

Rack Resiliency considers those services which provide the backbone to execute user jobs as critical services. This however does not mean that other services 
are less important in the overall management of HPE Cray EX systems. The administrator at given time can add additional services to the critical service list
already created by HPE.

For example, services like BOS, BSS, CFS, Gitea, IMS, iPXE, etc., are NOT critical for running user jobs whereas services like `slurmctld`,
`slurm-operator`, `slurmdbd`, `pbs`, `pbs-comm`, etc., are considered critical due to their direct ability to affect the user jobs. However, 
the critical services still depend on other services complete their work.

For a complete list of critical services identified by HPE, see [HPE Critical Services](hpe-critical-services.md). For listing the critical services which are monitored by Rack Resiliency use the below command:

```bash
kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data.critical-service-config\.json}' | jq
```
Truncated example output (the actual number of services in the ConfigMap will be larger):

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
    "cray-console-data-postgres": {
      "namespace": "services",
      "type": "StatefulSet"
    }
  }
}
```

## 2. Static ConfigMap

The ConfigMap `rrs-mon-static` in the `rack-resiliency` namespace is where Rack Resiliency keeps it's list of critical services which are managed 
by RMS (Resiliency Monitoring Service) for monitoring for their health and equal distribution across zones.

For listing the Static ConfigMap used by Rack Resiliency service use the below command:

```bash
kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq
```
Truncated example output (the actual output of ConfigMap will be larger):

```json
{
  "ceph_monitoring_polling_interval": "60",
  "ceph_monitoring_total_time": "600",
  "ceph_pre_monitoring_delay": "60",
  "critical-service-config.json":
    ....
  "default_message_level": "debug",
  "k8s_monitoring_polling_interval": "60",
  "k8s_monitoring_total_time": "600",
  "k8s_pre_monitoring_delay": "40",
  "last_updated_timestamp": "",
  "log_dir": "/var/log/rr",
  "unit_of_time": "seconds"
}
```

## 3. Dynamic ConfigMap

The ConfigMap `rrs-mon-dynamic` in the `rack-resiliency` namespace consist of configuration information based on which the 
critical services are monitored.

For listing the Dynamic ConfigMap used by Rack Resiliency service use the below command:

```bash
kubectl get cm -n rack-resiliency rrs-mon-dynamic -o jsonpath='{.data}' | jq
```

## 4. Rack Resiliency Service (RRS)

RRS acts as a backend for RR API and also monitors status and distribution of critical services/ management nodes. 
RRS is designed as a singleton pod with two containers- RMS and API along with an init container.

**Resiliency Monitoring Service (RMS)**

The Resiliency Monitoring Service (RMS) provides the functionality to detect rack or node failures and monitor critical services post the failure. 
  
Refer for more info on [RMS](Resiliency_Monitoring_Service.md)

**Rack Resiliency API Service**

The Rack Resiliency Service (RRS) provides APIs to access and manage zones data and critical services information within Kubernetes and Ceph clusters. 
It supports zone discovery, status checks, and critical service registration. RRS is used by the Cray `rrs` CLI to power high-availability, fault-tolerant operations.

Refer [API](../../api/rrs.md) for more info.

## 5. `Kyverno` policy

One of the key ways to ensure that CSM critical services survive the failure of nodes or a single rack is to spread the replicas of these services across multiple zones and racks. 

Refer [`Kyverno` cluster policy](distribution_of_critical_services_across_zones.md#kyverno-cluster-policy) for more info.

# Rack Resiliency Management Tools

* Interactive interface with Cray CLI
    * The CLI for interfacing with rack resiliency service is part of Cray CLI. A new module (RRS) is added to Cray CLI to support rack resiliency specific commands.
    * Refer [Craycli commands for zones](Zones.md#managing-zones) for more information on the commands related to zones.
    * Refer [Craycli commands for critical services](Managed_Critical_Services.md#critical-services-operations) for more information on the commands related to critical services.

* API Interface with  RESTful APIs
    * Refer for more info [RRS](../../api/rrs.md) for APIs
  
# Rack Resiliency Management Tasks

## 1. Enable and configure Rack Resiliency

Rack Resiliency consist of below 4 stages for enabling and configuring:

1. [Enabling Rack Resiliency](Enabling_Rack_resiliency.md#1-enabling-rack-resiliency)
2. [Add zones prefixes (Optional)](Enabling_Rack_resiliency.md#2-to-define-the-kubernetes-and-ceph-zone-prefixes)
3. [Setup/ configure Rack Resiliency](Enabling_Rack_resiliency.md#3-setup-configure-rack-resiliency)
4. [Deployment of RRS (Rack Resiliency Service) Helm chart for monitoring](Enabling_Rack_resiliency.md#4-deployment-of-rrs-helm-chart-for-monitoring)

## 2. Managing critical services

A CSM administrator can decide to add a new service to the list of critical services if it is found to be important for supporting
user jobs. This service may be a customized service not provided by HPE but installed by the customer.

Critical services can be managed using the Cray CLI or the API. Refer [manage critical services](Managed_Critical_Services.md) for 
complete list of supported operations for critical services.

## 3. Managing `kyverno` policy 

See [Manage `kyverno` policy](kyverno.md) in order to view, add, delete and modify critical services.

# Troubleshooting

For verifying the enablement of Rack Resiliency and troubleshooting node failures, rack failure, or status of critical services 
and Ceph, see [Troubleshooting](troubleshooting.md).
