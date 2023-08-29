# Operational Procedure for Rack Resiliency 

## Graceful shutdown of rack
It's not uncommon for customers to have a need to power off a rack of equipment at a time - either for a maintenance window or because they are moving equipment around. We'll need to do a full analysis of hardware, software, networking to determine where we need to put config/ controls in place to ensure that there are no critical failures when taking a rack down.

For CSM/ K8S setup there is no "zone aware" setup of the workloads. For example, if Etcd cluster or a Postgres DB is spread across 3 nodes and in cse the 3 nodes are on the same rack the situation will be critical. We should be able to recover from this event gracefully. 

This document provides an operational procedure to be followed for performing graceful shutdown of the rack on the CSM clusters when there is a need for maintenance of the rack or movement of the rack. This procedure ensures that all the services will perform well in real-life or chaotic conditions when one of the rack is down. 


## Table of Contents
[**I. Rack Resiliency Overview**](#i-rack-resiliency-overview)

[**II. CSM Health Checks**](#ii-csm-health-checks)

[**III. Graceful Shutdown Procedure**](#iii-graceful-shutdown-procedure)

[**IV. Power On Procedure**](#iv-power-on-procedure)
* [Powering on the rack which has been shutdown](#powering-on-the-rack-which-has-been-shutdown)
* [Replacing the rack which has been shutdown](#replacing-the-rack-which-has-been-shutdown)
  
[**V. Known Issues**](#v-known-issues)

## I. Rack Resiliency Overview

CSM clusters includes  NCN nodes (combination of master, worker and storage nodes). These NCN nodes will be placed on different physical racks in the data centers and we need to make sure that CSM cluster is resilient at rack level, meaning, failure of one rack do not result in losing the access to the entire cluster or results in any performance degradation. 

Since CSM/ K8s cluster is not "zone aware" (zone represents a logical failure domain) here we use k8s topology zoning labels applied at rack lavel in order for CSM cluster to be "zone aware" and take an advantage of distribution of the pods/ servies across the zones according to the configuration in order to minimize the risk due any rack failure.

This procedure of rack resiliency is intended to make the CSM clusters resilient or HA on the course of a rack shutdown. 

## II. CSM Health Checks
Capture and verify CSM platform health: "/opt/cray/platform-utils/ncnHealthChecks.sh -h"
Capture and verify CSM postgress health: "/opt/cray/platform-utils/ncnPostgresHealthChecks.sh -h"
Capture snapshot of all k8s info “kubectl get all -A -o wide” for readiness
Capture snapshot of all k8s pod info “kubectl get pods -A -o wide” for readiness

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
- [Stage 9 - Remove etcd member of the master node](#Stage-9---remove-etcd-member-of-the-master-node)
- [Stage 10 - Graceful shutdown of the identified rack](#Stage-10---graceful-shutdown-of-the-identified-rack)
- [Stage 11 - Run CSM health checks](#Stage-11---run-csm-health-checks)

### Stage 0 - Prerequisites

Capture physical rack config and validate CSM health checks as a prerequisite step

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

Run “cordon_nodes.sh <rack name>” script: Which cordons all the master and worker nodes under the identified rack with cmd "kubectl cordon <node name>"

### Stage 4 - Reschedule unbalanced critical pods

Reschedule unbalanced etcd/ postgres pods by running “redistribute_pods.sh” script. Here it will redistribute etcd/ postgress pods under all the names spaces across the zones (one pod instance per rack only).

**Note:** Wait for some time for reschedule of the pods/ re-deployments etc.,

### Stage 5 - Run CSM health checks

Run CSM platform health checks and capture critical events/ info, if any, as mentioned in “Stage-0” for the readiness before draining of the nodes.

### Stage 6 - Drain of all the nodes under the identified rack

Run “drain_nodes.sh” script: Which drains (cordon + eviction of pods) of all the worker nodes one by one under the identified rack with cmds “kubectl drain <worker node-N> --ignore-daemonsets --force --delete-local-data” 

**Note:** Wait for delta time for drain to complete before proceeding to next step in the procedure.

### Stage 7 - Run pre rack resiliency checks for the correctness of the drain

After drain has been completed, check to see if all the pods have been evicted (no more pods running) on the identified rack by running "pre_rack_resiliency_checks.sh -r <rack name> -s check_drain_res"

### Stage 8 - Run CSM health checks

Run CSM platform health checks and capture critical events/ info, if any, as mentioned in “Stage-0” for the readiness of shutting down a identified rack after draining of the worker nodes.

### Stage 9 - Remove etcd member of the master node

#### Steps
1. Info cmd: Just to list and check current etcd members:
   
Ex:

        ncn-m001:~ # etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert                  /etc/kubernetes/pki/etcd/ca.crt member list
        46e7b792f3473890, started, ncn-m003, https://10.252.1.18:2380, https://10.252.1.18:2379,https://127.0.0.1:2379, false
        80f975cd8e92aad9, started, ncn-m002, https://10.252.1.17:2380, https://10.252.1.17:2379,https://127.0.0.1:2379, false
        a40df5e325796614, started, ncn-m001, https://10.252.1.16:2380, https://10.252.1.16:2379,https://127.0.0.1:2379, false
         ncn-m001:~ #

1. Stop etcd cluster:
   
Ex:

        systemctl stop etcd

4. remove the etcd member of the master node belong to the rack which is being shutdown:
   
Ex:

        etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert         /etc/kubernetes/pki/etcd/ca.crt member remove 46e7b792f3473890

6. check to see if the etcd member has been removed:
   
Ex:

        ncn-m001:~ # etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert         /etc/kubernetes/pki/etcd/ca.crt member list
        80f975cd8e92aad9, started, ncn-m002, https://10.252.1.17:2380, https://10.252.1.17:2379,https://127.0.0.1:2379, false
        a40df5e325796614, started, ncn-m001, https://10.252.1.16:2380, https://10.252.1.16:2379,https://127.0.0.1:2379, false
        ncn-m001:~ #

### Stage 10 - Graceful shutdown of the identified rack

If all “OK” from the “Step-5” and “Step-6” “ above, go ahead with graceful shutdown of all the nodes under identified rack.
From any health node run "power_off_on.sh -r <rack_label_name> -s power_off" to power off all the ncn master/ worker nodes.
                         OR
Login (ssh to master/ worker node from PIT node) and initiate “init 0” on all the ncn master and worker nodes.

### Stage 11 - Run CSM health checks

Refer section [CSM Health Checks](#ii-csm-health-checks) and run health checks just to make sure
that the cluster is accessible and functional after identified rakc has been shutdown.

## IV. Power On Procedure
### Powering on the rack which has been shutdown
### Stage 1 - Power-on ncn master/ worker nodes
From any healthy node run "power_off_on.sh -r <rack_label_name> -s power_on" to power on all the ncn master/ worker nodes
of a rack which has been shutdown.
                            OR
Directly from BMC power on all the ncn master/ worker nodes of a rack which has been shutdown.
             
### Stage 2 - Collect and validate CSM health checks 
Refer section [CSM Health Checks](#ii-csm-health-checks)

### Stage 3 - add master node etcd member back to the cluster
Please note that this step is applicable only if the rack has a master node, otherwise, skip it.

If the health of the cluster is OK then add the etcd member back to the cluster.
   
Add the etcd memeber back to the the cluster

        ncn-m001:~ # etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert         /etc/kubernetes/pki/etcd/ca.crt member add ncn-m003 --peer-urls=https://10.252.1.18:2380
        Member 6a1f6b43348d0c05 added to cluster   b0d7e85bf7e326

        ETCD_NAME="ncn-m003"
        ETCD_INITIAL_CLUSTER="ncn-m003=https://10.252.1.18:2380,ncn-m002=https://10.252.1.17:2380,ncn-m001=https://10.252.1.16:2380"
        ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.252.1.18:2380"
        ETCD_INITIAL_CLUSTER_STATE="existing"

Check that etcd member is added back with  "unstarted" state.

        ncn-m001:~ #  etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert         /etc/kubernetes/pki/etcd/ca.crt member list
        6a1f6b43348d0c05, unstarted, , https://10.252.1.18:2380, , false
        80f975cd8e92aad9, started, ncn-m002, https://10.252.1.17:2380, https://10.252.1.17:2379,https://127.0.0.1:2379, false
        a40df5e325796614, started, ncn-m001, https://10.252.1.16:2380, https://10.252.1.16:2379,https://127.0.0.1:2379, false
        ncn-m001:~ #

Remove etcd member data on master node

        ncn-m003:~ # rm -rf /var/lib/etcd/member

Set the etcd service to start as existing (ncn-m001):

        ncn-m003:~ # sed -i 's/new/existing/' /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service
        ncn-m003:~ # systemctl daemon-reload

start etcd on the unhealthy NCN (ncn-m001):
        ncn-m003:~ # systemctl start etcd

Ex:

        ncn-m001:~ # etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert         /etc/kubernetes/pki/etcd/ca.crt member list
        80f975cd8e92aad9, started, ncn-m002, https://10.252.1.17:2380, https://10.252.1.17:2379,https://127.0.0.1:2379, false
        a40df5e325796614, started, ncn-m001, https://10.252.1.16:2380, https://10.252.1.16:2379,https://127.0.0.1:2379, false
        ncn-m001:~ #

### Stage 4 - Reschedule unbalanced critical pods

Reschedule unbalanced etcd/ postgres pods by running “redistribute_pods.sh” script. Here it will redistribute etcd/ postgress pods under 
all the names spaces across the zones (one pod instance per rack only).

### Replacing the rack which has been shutdown
#### <TODO>

## V. Known Issues
