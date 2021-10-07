#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

all_workers=$(kubectl get nodes | grep ncn-w | awk '{print $1}')
kea_node=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-dhcp-kea' -o wide | grep -v NAME | awk '{print $7}')
kea_pod=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-dhcp-kea' -o wide | grep -v NAME | awk '{print $1}')
nexus_node=$(kubectl get po -n nexus -l 'app=nexus' -o wide | grep -v NAME | awk '{print $7}')
nexus_pod=$(kubectl get po -n nexus -l 'app=nexus' -o wide | grep -v NAME | awk '{print $1}')
conman_node=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-conman' -o wide | grep -v NAME | awk '{print $7}')
conman_pod=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-conman' -o wide | grep -v NAME | awk '{print $1}')

echo ""
echo "Boot related pod locations:"
echo ""
echo "  kea pod is running on:    $kea_node ($kea_pod)"
echo "  nexus pod is running on:  $nexus_node ($nexus_pod)"
echo "  conman pod is running on: $conman_node ($conman_pod)"
echo ""

other_worker=""
emptiest_worker=""
lowest_count=""
lowest_podlist=""
for worker in $all_workers; do
    count=0
    podlist=""
    [ "$worker" == "$kea_node" ] && let count+=1 && podlist="$podlist $kea_pod"
    [ "$worker" == "$nexus_node" ] && let count+=1 && podlist="$podlist $nexus_pod"
    [ "$worker" == "$conman_node" ] && let count+=1 && podlist="$podlist $conman_pod"
    if [ -z "$lowest_count" ] || [ $count -lt $lowest_count ]; then
        if [ -n "$emptiest_worker" ] && [ -z "$other_worker" ]; then
            other_worker="$emptiest_worker"
        fi
        emptiest_worker="$worker"
        lowest_count=$count
        lowest_podlist="$podlist"
        [ $count -eq 0 ] && break
    elif [ -z "$other_worker" ]; then
        other_worker="$worker"
    fi
done

echo "This is the recommended procedure to upgrade your worker nodes:"

if [ $lowest_count -eq 0 ]; then
    echo "      1. Upgrade ${emptiest_worker}."
    echo "      2. Once its upgrade is completed, run the following commands to move all of the"
    echo "         critical pods to it:"
    for pod in $kea_pod $nexus_pod $conman_pod ; do
        echo "         # /usr/share/doc/csm/upgrade/1.2/scripts/k8s/move-pod.sh $pod ${emptiest_worker}"
    done
    echo "      3. Upgrade the remaining worker nodes in any order."
else
    echo "      1. Run the following commands to move all critical pods from ${emptiest_worker} to ${other_worker}:"
    for pod in $lowest_podlist; do
        echo "         # /usr/share/doc/csm/upgrade/1.2/scripts/k8s/move-pod.sh $pod ${other_worker}"
    done
    echo "      2. Upgrade ${emptiest_worker}."
    echo "      3. Once its upgrade is completed, run the following commands to move all of the"
    echo "         critical pods to it:"
    for pod in $kea_pod $nexus_pod $conman_pod ; do
        echo "         # /usr/share/doc/csm/upgrade/1.2/scripts/k8s/move-pod.sh $pod ${emptiest_worker}"
    done
    echo "      4. Upgrade the remaining worker nodes in any order."
fi
