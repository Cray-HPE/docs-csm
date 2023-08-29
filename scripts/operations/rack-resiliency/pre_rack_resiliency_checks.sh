#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

# The pre_rack_resiliency_checks.sh is used to perform below checks:
#     Check the count of master nodes in the rack to be shutdown
#     Check the resource(CPU,Memory) availability on the other rack nodes
#     Check the postgres pods distribution across the racks
#     Check the etcd pods distribution across the racks
#     Check the singleton pods scheduled on the rack nodes to be shutdown
#     Check the pods running on the drained nodes
#
# The pre_rack_resiliency_checks.sh script can be run on any worker or
# master NCN node from any directory. This script requires the rack name
# to be shutdowned as an input parameter. Logs will be by default collected
# in the location - "/var/log/rackresiliency/"
#
# Usage: ./pre_rack_resiliency_checks.sh -r <rack-n> -s <check_name>

YELLOW='\E[1;33m'
RED='\E[1;31m'
WHITE='\E[0;37m'
GREEN='\E[1;32m'

rack=$1
count=0

DATE=`date "+%d-%b-%Y-%a-%H-%M-%S%p"`
HOST=`hostname`
PRE_RACK_RESILIENCY_CHECK_LOG="/var/log/rackresiliency/$HOST-prerackres-$DATE.log"
mkdir -p /var/log/rackresiliency

echolog(){
        echo -e "$@"
        echo -e "$@" >>$PRE_RACK_RESILIENCY_CHECK_LOG
}

# To check the count of master nodes in the rack to be shutdown
check_master_node_count()
{
    echolog "***********************"
    echolog "Check Master node Count"
    echolog "***********************"
    echolog
    nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | awk '{print $1}'))
    for node in "${nodes[@]}"
    do
        if [[ "$node" == ncn-m00* ]]; then
            count=$((count + 1))
        fi
    done
    if [[ "$count" == 0 ]]; then
        echolog "${RED}None of the master nodes are scheduled on the rack $rack.${WHITE}"
    elif [[ "$count" == 1 ]]; then
        echolog "${GREEN}Exactly one master node is scheduled on the rack $rack.${WHITE}"
    else
        echolog "${RED}More than one master nodes are scheduled on the rack $rack.${WHITE}"
        echolog "${RED}It is advisable to have not more than one master nodes in any particular rack. Exiting..${WHITE}"
        exit 1 
    fi
    echolog
}

# To check the resource(CPU,Memory) on the other rack nodes
check_resource_usage()
{
    echolog "***************************"
    echolog "Check Resource Availability"
    echolog "***************************"
    echolog
    all_nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
    shutdown_nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | awk '{print $1}'))
    remaining_nodes=($(echo $(echo ${all_nodes} ${shutdown_nodes} | tr ' ' '\n' | sort | uniq -u)))
    for node in "${remaining_nodes[@]}"
    do
        cpu_requests=$(kubectl describe node ${node}  | grep -A 10 Allocated | grep cpu | awk '{print $3}' | grep -o '[0-9]\+')
        memory_requests=$(kubectl describe node ${node}  | grep -A 10 Allocated | grep memory | awk '{print $3}' | grep -o '[0-9]\+')
        #echo "Node:$node: Cpu: $cpu_requests Memory: $memory_requests"
        if [[ "$cpu_requests" -ge 85 || "$memory_requests" -ge 85 ]]; then
            echolog "${RED}Node $node of the rack $rack is not having enough resources to accomodate more pods into it. Exiting..${WHITE}"
            exit 1
        else
            echolog "${GREEN}Node $node of the rack $rack is having enough resources to schedule new pods${WHITE}"
        fi
    done
    echolog
}

# To check the postgres pods distribution across the racks 
check_postgres_pods_distribution()
{
    echolog "********************************"
    echolog "Check Postgres pods distribution"
    echolog "********************************"
    echolog
    zones=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone}{"\n"}' | sort -u)
    zones_count=$(echo ${zones} | wc -w)
    zonesbyname=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone} {.metadata.name} {"\n"}')
    for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
        for pg in $(kubectl get postgresql --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
            members=$(kubectl get pod --namespace "${ns}" -l "cluster-name=${pg},application=spilo" -o custom-columns=NAME:.metadata.name --no-headers)
            count=$(echo ${members} | wc -w)
            echo "${zonesbyname}" | sort -k2 > zones
            if [ ${count} -gt 1 ]; then
                 pgsbyname=$(kubectl get pod --namespace "${ns}" -l "cluster-name=${pg},application=spilo" --no-headers -o custom-columns="NAME:metadata.name,NODE:spec.nodeName")
                 echo "${pgsbyname}" | sort -k2 > pods
                 join -j2 -o 1.1,1.2,2.1 pods zones > joined
                 echo ""
                 echo "Checking for $pg:"
                 echo "$pgsbyname"
                 if [ "$(awk '{print $3}' joined | sort -u | wc -l)" -eq "${zones_count}" ]; then
                     echolog "${GREEN}posgtres pods ${pg} are equally distributed across all the three racks${WHITE}"
                 else
                     echolog "${YELLOW}postgres pods ${pg} are not equally distributed across three racks${WHITE}"
                     echolog "${YELLOW}Need to redistribute them acrorss all the three racks${WHITE}"
                 fi
            else
                 echolog "${GREEN}This is a singleton pod, skipping${WHITE}"
            fi
        done
    done
    echolog
}

# To check the etcd pods distribution across the racks
check_etcd_pods_distribution()
{
    echolog "****************************"
    echolog "Check Etcd pods distribution"
    echolog "****************************"
    echolog
    zones=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone}{"\n"}' |sort -u)
    zones_count=$(echo ${zones} | wc -w)
    zonesbyname=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone} {.metadata.name} {"\n"}')
    for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
        for etcd in $(kubectl get etcdclusters --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
            members=$(kubectl get pod --namespace "${ns}" -l "etcd_cluster=${etcd}" -o custom-columns=NAME:.metadata.name --no-headers)
            count=$(echo ${members} | wc -w)
            echo "${zonesbyname}" | sort -k2 > zones
            if [ ${count} -gt 1 ]; then
                 etcdbyname=$(kubectl get pod --namespace "${ns}" -l "etcd_cluster=${etcd}" --no-headers -o custom-columns="NAME:metadata.name,NODE:spec.nodeName")
                 echo "${etcdbyname}" | sort -k2 > pods
                 join -j2 -o 1.1,1.2,2.1 pods zones > joined
                 echo ""
                 echo "Checking for $etcd:"
                 echo "$etcdbyname"
                 if [ "$(awk '{print $3}' joined | sort -u | wc -l)" -eq "${zones_count}" ]; then
                     echolog "${GREEN}etcd pods ${etcd} are equally distributed across all the three racks${WHITE}"
                 else
                     echolog "${YELLOW}etcd pods ${etcd} are not equally distributed across three racks${WHITE}"
                     echolog "${YELLOW}need to redistribute them acrorss all the three racks${WHITE}"
                 fi
            else
                 echolog "${GREEN}This is a singleton pod, skipping${WHITE}"
            fi
        done
    done
    echolog
}

# To check the singleton pods scheduled on the rack nodes to be shutdown
check_singleton_pods()
{
    echolog "********************"
    echolog "Check Singleton pods"
    echolog "********************"
    echolog
    deploy_list=$(kubectl get deploy -A --no-headers | awk '{print $1"/"$2}')
    for deploy in ${deploy_list}
    do
        deploy_ns=${deploy%/*}
        deploy_name=${deploy#*/}
        replicas_count=$(kubectl get deploy ${deploy_name} -n ${deploy_ns} -o jsonpath='{.spec.replicas}')
        if [[ "${replicas_count}" == 1 ]]; then
            rs_name=$(kubectl get deploy -n ${deploy_ns} ${deploy_name} -o yaml | grep " ReplicaSet " | cut -d'"' -f 2)
            pod_name=$(kubectl get po -n ${deploy_ns} | grep -i ${rs_name} | awk '{print $1}')
            node_name=$(kubectl get po ${pod_name} -n ${deploy_ns} -o jsonpath='{.spec.nodeName}')
            nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | awk '{print $1}'))
            for node in "${nodes[@]}"
            do
                if [[ "$node" == ${node_name} ]]; then
                    echolog "${YELLOW}${pod_name} is scheduled on the node ${node_name}${WHITE}"
                fi
            done
        fi
    done
}

# To check the pods running on the drained nodes
check_pods_list() {
    count=0
    nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | grep ncn-w0* | awk '{print $1}'))
    for node in "${nodes[@]}"
    do
        pods_list=$(kubectl get po -A -o wide | grep $node | awk '{print $1"/"$2}')
        for pod in ${pods_list}
        do
            pod_name=${pod#*/}
            pod_ns=${pod%/*}
            pod_type=$(kubectl get pod ${pod_name} -n ${pod_ns} -o jsonpath='{.metadata.ownerReferences[0].kind}')
            if [[ "$pod_type" == DaemonSet ]]; then
                    continue
            else
                count=$((count + 1))
                echolog "${RED}Pod ${pod_name} which is not a daemonset is still scheduled on the node ${node} which will be brought down as a part of rack shutdown${WHITE}"
            fi
        done
    done
    if [[ "$count" == 0 ]]; then
        echolog "${GREEN}None of the pods other than some daemonsets are scheduled on the rack $rack.${WHITE}"
    fi
}

# To run the complete pre rack resiliency checks
run_complete_pre_rack_resiliency_checks() {
    check_master_node_count
    check_resource_usage
    check_etcd_pods_distribution
    check_postgres_pods_distribution
    check_singleton_pods
}

main() {
    if [[ ! -z $single_test ]]; then
        $single_test
        if [[ $? -ne 0 ]]; then
            echo "(-s options are check_master_node_count, check_resource_usage, check_etcd_pods_distribution, \
                         check_postgres_pods_distribution, check_singleton_pods, check_pods_list)"
            exit 2;
        fi
    else
       run_complete_pre_rack_resiliency_checks
    fi
}

# get opts
    while getopts r:s:h stack
    do
        case "${stack}" in
            r) rack=${OPTARG}
               ;;
            s) single_test=$OPTARG
                main ;;
            h | \?) echo "Usage:"
                echo " pre_rack_resiliency_checks -r <rack_label_name>  # run all pre-rack resiliency checks"
                echo " pre_rack_resiliency_checks -r <rack_label_name> -s <prerack_resiliency_check_1> # run a specific pre-rack resiliency check"
                echo " pre_rack_resiliency_checks -r <rack_label_name> -s <prerack_resiliency_check_1> .. -s <prerack_resiliency_check_n> # run set of pre-rack resiliency checks"
                echo " "
                echo "Supported pre-rack resiliency checks are :"
                echo " check_master_node_count, check_resource_usage, check_etcd_pods_distribution,"
                echo " check_postgres_pods_distribution, check_singleton_pods, check_pods_list"
                exit 1;;
        esac
    done

# no options mentioned. execute all.
if [[  -z $single_test ]]; then
      run_complete_pre_rack_resiliency_checks
fi
