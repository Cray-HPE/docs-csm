# Operational Procedure for Rack Resiliency 

## Graceful shutdown of a rack
It's not uncommon for customers to have a need to power off a rack of equipment at a time - either for a maintenance window or because they are moving equipment around. We'll need to do a full analysis of hardware, software, networking to determine where we need to put config/ controls in place to ensure that there are no critical failures when taking a rack down.

For CSM/ K8S setup there is no "zone aware" setup of the workloads. For example, if ETCD cluster or a Postgres DB is spread across 3 nodes and in case the 3 nodes are on the same rack then the situation will be critical. We should be able to recover from this event gracefully.

This document provides an operational procedure to be followed for performing graceful shutdown of the rack on the CSM clusters when there is a need for maintenance of the rack or movement of the rack. This procedure ensures that all the services will perform well in real-life or chaotic conditions when one of the rack is down. 

## Non-graceful shutdown of a rack
Unlike graceful shutdown of a rack which is planned due to maintenance or movement of equipment, non-graceful shutdown is abrupt in nature where rack can go down any time due to power failure of rack or any hardware failure. This document provides operational procedure (simulated only for internal verification to test abrupt shutdown situations) to be followed for performing non-graceful shutdown of the rack and power-on the CSM clusters.

We need to do a full analysis of hardware, software, networking to determine where we need to put config/ controls in place to ensure that there are no critical failures when rack is down abruptly. Document/ list down the issues here in this doc with possible work arounds/ remediations, if any.

## Table of Contents
[**I. Rack Resiliency Overview**](#i-rack-resiliency-overview)

[**II. CSM Health Checks**](#ii-csm-health-checks)

[**III. Graceful Shutdown Procedure**](#iii-graceful-shutdown-procedure)

[**IV. Power On Procedure**](#iv-power-on-procedure)
* [Powering on the rack which has been shutdown](#powering-on-the-rack-which-has-been-shutdown)
* [Replacing the rack which has been shutdown](#replacing-the-rack-which-has-been-shutdown)
  
[**V. Known Issues**](#v-known-issues)

[**VI. Non-graceful Shutdown Procedure**](#vi-non-graceful-shutdown-procedure)

[**VII. Power On Procedure**](#vii-power-on-procedure)
* [Powering on the rack which has been shutdown](#powering-on-the-rack-which-has-been-shutdown)
  
[**VIII. Known Issues**](#viii-known-issues)

## I. Rack Resiliency Overview

CSM clusters includes NCN nodes (combination of master, worker and storage nodes). These NCN nodes will be placed on different physical racks in the data centers and we need to make sure that CSM cluster is resilient at rack level, meaning, failure of one rack do not result in losing the access to the entire cluster or results in any performance degradation. 

Since CSM/ K8s cluster is not "zone aware" (zone represents a logical failure domain) here we use k8s topology zoning labels applied at rack lavel in order for CSM cluster to be "zone aware" and take an advantage of distribution of the pods/ servies across the zones according to the configuration in order to minimize the risk due to any rack failure.

This procedure of rack resiliency is intended to make the CSM clusters resilient or HA on the course of a rack shutdown. 

## II. CSM Health Checks
1. Capture and verify CSM platform health:
   
        "/opt/cray/platform-utils/ncnHealthChecks.sh -h"
3. Capture and verify CSM postgress health:

       "/opt/cray/platform-utils/ncnPostgresHealthChecks.sh -h"
5. Capture snapshot of all k8s info “kubectl get all -A -o wide” for readiness
6. Capture snapshot of all k8s pod info “kubectl get pods -A -o wide” for readiness
7. Capture and verify etcd cluster health
   
        "etcdctl --endpoints ncn-m001:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert 	/etc/kubernetes/pki/etcd/ca.crt member list"
        "etcdctl --endpoints ncn-m001:2379,ncn-m002:2379,ncn-m003:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint health"
  - Run combined k8s health check for k8s etcd cluster health
    
        ncn-m001:~ # export SW_ADMIN_PASSWORD='<admin password of the node>'
        ncn-m001:~ # /opt/cray/tests/install/ncn/automated/ncn-k8s-combined-healthcheck

## III. Graceful Shutdown Procedure
- [Stage 0 - Prerequisites](#Stage-0---Prerequisites)
- [Stage 1 - Create k8s zone config on racks](#Stage-1---create-k8s-zone-config-on-racks)
- [Stage 2 - Run pre rack resiliency checks](#Stage-2---run-pre-rack-resiliency-checks)
- [Stage 3 - Cordon of all the nodes under identified rack](#Stage-3---cordon-of-all-the-nodes-under-identified-rack)
- [Stage 4 - Reschedule unbalanced critical pods](#Stage-4---reschedule-unbalanced-critical-pods)
- [Stage 5 - Run CSM health checks](#Stage-5---run-csm-health-checks)
- [Stage 6 - Drain of all the nodes under the identified rack](#Stage-6---drain-of-all-the-nodes-under-the-identified-rack)
- [Stage 7 - Run pre rack resiliency checks for the correctness of the drain](#Stage-7---run-pre-rack-resiliency-checks-for-the-correctness-of-the-drain)
- [Stage 8 - Run CSM health checks](#Stage-8---run-csm-health-checks)
- [Stage 9 - Graceful shutdown of the identified rack](#Stage-9---graceful-shutdown-of-the-identified-rack)
- [Stage 10 - Run CSM health checks](#Stage-10---run-csm-health-checks)

### Stage 0 - Prerequisites

Capture physical rack config and validate CSM health checks as a prerequisite step.

#### Steps

1. Get the current physical rack configuration mapping to that of master and worker nodes to be used in the next step for configuring k8s zoning.
2. Capture and verify CSM platform health checks and snapshot of all k8s info “kubectl get all -A” for readiness.
3. Monitor and pre capture critical events/ info, if any from kiali, Prometheus/ Grafana, BOS and “cray cli” kiali (to monitor istio ingress gateway communication) CSM Prometheus/ Grafana – monitor for critical events BOS - for work loads “cray cli” – info/ critical events

### Stage 1 - Create k8s zone config on racks

Apply k8s topology zone labels to physical racks with master and worker nodes included.

#### Steps

1. Run “create_zones.sh” script: creates rack level zoning with commands “kubectl label nodes <master node> <worker nodes…>  kubernetes.io/zone=rack-N –overwrite”
2. Run "show_zones.sh" script: to check the correctness of the zone config created.
    - shows zone config with commands “kubectl get nodes -l topology.kubernetes.io/zone=rack-N”

**Note:** Here “N” is the rack number which is identified to be gracefully shutdown. These steps can be executed on any of the cluster nodes. Only worker/ master nodes within rack to be considered.

### Stage 2 - Run pre rack resiliency checks

Run and validate below pre rack resiliency checks (“pre_rack_resiliency_checks.sh” script) before graceful shutdown of the nodes under identified rack. 

#### Checks

1. Check to see if there is exactly one master configured per rack. Fail the check on not meeting the requirement.
2. Check to see if the available cpu and memory resources within threshold limit (90%) to give room for new pods/ services to get scheduled. Fail the check on not meeting the requirement.
3. Check and list all the critical pods (etcd/ potgress) which are not equally distributed across the racks.
4. Check and list all the critical singleton pods which are going to be affected due to rack being shutdown.

### Stage 3 - Cordon of all the nodes under identified rack

Run “cordon_nodes.sh <rack name>” script: Which cordons all the master and worker nodes under the identified rack with cmd "kubectl cordon \<node name>"

### Stage 4 - Reschedule unbalanced critical pods

Reschedule unbalanced etcd/ postgres pods by running “redistribute_pods.sh” script. Here it will redistribute etcd/ postgress pods under all the names spaces across the zones (one pod instance per rack only).

**Note:** Wait for some time for reschedule of the pods/ re-deployments etc.,

### Stage 5 - Run CSM health checks

Run CSM platform health checks and capture critical events/ info, if any, as mentioned in “Stage-0” for the readiness before draining of the nodes.

### Stage 6 - Drain of all the nodes under the identified rack

Run “drain_nodes.sh” script: Which drains (cordon + eviction of pods) of all the worker nodes one by one under the identified rack with cmds “kubectl drain \<worker-node-N> --ignore-daemonsets --force --delete-local-data” 

**Note:** Wait for delta time for drain to complete before proceeding to next step in the procedure.

### Stage 7 - Run pre rack resiliency checks for the correctness of the drain

After drain has been completed, check to see if all the pods have been evicted (no more pods running) on the identified rack by running 

    "pre_rack_resiliency_checks.sh -r \<rack-name> -s check_drain_res"

### Stage 8 - Run CSM health checks

Run CSM platform health checks and capture critical events/ info, if any, as mentioned in “Stage-0” for the readiness of shutting down a identified rack after draining of the worker nodes.

### Stage 9 - Graceful shutdown of the identified rack

If all “OK” from the “Step-5” and “Step-6” “ above, go ahead with graceful shutdown of all the nodes under identified rack.
From any healthy node run the below script to power off all the ncn master/ worker nodes:

    "power_off_on.sh -c <cluster_name> -r <rack_label_name> -s power_off" 

Here the "cluster_name" is the System Name (Check on any master node "cat /etc/cray/system_name") and "rack_label_name" is the rack name identified to be shutdown
which is configured in the "Stage 1" above and can be displayed by "show_zones.sh" (OR) Login (ssh to master/ worker node from PIT node) and initiate “init 0” on all the ncn master and worker nodes of the identified rack.

### Stage 10 - Run CSM health checks

Refer section [CSM Health Checks](#ii-csm-health-checks) and run health checks just to make sure
that the cluster is accessible and functional after identified rakc has been shutdown.

## IV. Power On Procedure
### Powering on the rack which has been shutdown
### Stage 1 - Power-on ncn master/ worker nodes
From any healthy node run the below script to power on all the ncn master/ worker nodes of a rack which has been shutdown.

    "power_off_on.sh -c <cluster_name> -r <rack_label_name> -s power_on" 

Here the "cluster_name" is the System Name (Check on any master node "cat /etc/cray/system_name") and "rack_label_name" is the rack name identified to be powered-on
which is configured in the "Stage 1" above and can be displayed by "show_zones.sh" (OR) directly from BMC power on all the ncn master/ worker nodes of a rack which has been shutdown.
             
### Stage 2 - Collect and validate CSM health checks 
Refer section [CSM Health Checks](#ii-csm-health-checks)

### Stage 3 - Uncordon the master/ worker nodes
From any healthy node run "uncordon_nodes.sh -r <rack_label_name>" to uncordon the ncn master/ worker nodes
which were cordoned before shutdown.

Run "kubectl get nodes" and check to see if the nodes are in "Ready" state without "SchedulingDisabled" lable set.

### Stage 4 - Reschedule unbalanced critical pods

Reschedule unbalanced etcd/ postgres pods by running “redistribute_pods.sh” script. Here it will redistribute etcd/ postgress pods under 
all the names spaces across the zones (one pod instance per rack only).

### Replacing the rack which has been shutdown
<TODO>

## V. Known Issues
Refer EPIC: https://jira-pro.it.hpe.com:8443/browse/CASM-2405

## VI. Non-graceful Shutdown Procedure
- [Stage 0 - Prerequisites](#Stage-0---Prerequisites)
- [Stage 1 - Create k8s zone config on racks](#Stage-1---create-k8s-zone-config-on-racks)
- [Stage 2 - Run CSM health checks](#Stage-2---run-csm-health-checks)
- [Stage 3 - non-graceful shutdown of the identified rack](#Stage-3---non-graceful-shutdown-of-the-identified-rack)
- [Stage 4 - Run CSM health checks](#Stage-4---run-csm-health-checks)

### Stage 0 - Prerequisites

Capture physical rack config and validate CSM health checks as a prerequisite step.

### Stage 1 - Create k8s zone config on racks

Apply k8s topology zone labels to physical racks with master and worker nodes included.

#### Steps

1. Run “create_zones.sh” script: creates rack level zoning with commands “kubectl label nodes <master node> <worker nodes…>  kubernetes.io/zone=rack-N –overwrite”
2. Run "show_zones.sh" script: to check the correctness of the zone config created.
    - shows zone config with commands “kubectl get nodes -l topology.kubernetes.io/zone=rack-N”

**Note:** Here “N” is the rack number which is identified to be gracefully shutdown. These steps can be executed on any of the cluster nodes. Only worker/ master nodes within rack to be considered.

### Stage 2 - Run CSM health checks

Refer section [CSM Health Checks](#ii-csm-health-checks)

### Stage 3 - Non-graceful shutdown of the identified rack

If all “OK” from the “Step-2” above, go ahead with non-graceful shutdown of all the nodes under identified rack.
From any health node run the below command to power off all the ncn master/ worker nodes:

        "power_off_on.sh -c <cluster_name> -r <rack_label_name> -s power_off"

Here the "cluster_name" is the System Name (Check on any master node "cat /etc/cray/system_name") and "rack_label_name" is the rack name identified to be shutdown
which is configured in the "Stage 1" above and can be displayed by "show_zones.sh" (OR) login (ssh to master/ worker node from PIT node) and initiate “init 0” on all the ncn master and worker nodes of the identified rack.

### Stage 4 - Run CSM health checks

Refer section [CSM Health Checks](#ii-csm-health-checks)

## VII. Power On Procedure

### Powering on the rack which has been shutdown non-gracefully 
### Stage 1 - Power-on ncn master/ worker nodes
From any healthy node run the below command to power on all the ncn master/ worker nodes which has been powered off:

      "power_off_on.sh -c <cluster_name> -r <rack_label_name> -s <power_on>"

Here the "cluster_name" is the System Name (Check on any master node "cat /etc/cray/system_name") and "rack_label_name" is the rack name identified to be powerd-on
which is configured in the "Stage 1" above and can be displayed by "show_zones.sh" (OR) directly from BMC power on all the ncn master/ worker nodes of a rack which has been shutdown.
             
### Stage 2 - Collect and validate CSM health checks 
Refer section [CSM Health Checks](#ii-csm-health-checks)

**Note** Though k8s master/ worker nodes are shown as healthy ("Ready" state) after rack has been powered-on, please make sure that even all the etcd master node members
are in healthy/ "started" state from the above checks w.r.t etcd before proceeding further to shutdown another rack part of the rack resiliency verification.

## VIII. Known Issues
Refer EPIC: https://jira-pro.it.hpe.com:8443/browse/CASMPET-6830
