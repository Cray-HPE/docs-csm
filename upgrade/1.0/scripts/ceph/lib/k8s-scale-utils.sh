#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Scale down cephfs clients to prevent mds corruption issues

cephfs_replica_counts_file="/etc/cray/ceph/cephfs_replica_counts"

function scale_down_cephfs_clients () {
  now=$(date +"%H:%M:%S_%m-%d-%Y")
  backup_name="$now-snapshot"

  echo "Taking a snapshot of nexus pvc ($backup_name)"
  output=$(kubectl -n nexus exec -it $(kubectl get po -n nexus -l 'app=nexus' -o json | jq -r '.items[].metadata.name') -c nexus -- /bin/sh -c "mkdir /nexus-data/.snap/$backup_name" 2>&1)
  if [[ "$?" -ne 0 ]]; then
    echo "Did not find nexus pod to take snapshot from -- continuing..."
  fi


  rm -f $cephfs_replica_counts_file
  cnt=0
  client_list=$(kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName=="ceph-cephfs-external") | .metadata.namespace, .metadata.name')
  client_array=( $client_list )
  array_length=${#client_array[@]}
  while [[ "$cnt" -lt "$array_length" ]]; do
    ns="${client_array[$cnt]}"
    cnt=$((cnt+1))
    pvc_name="${client_array[$cnt]}"
    cnt=$((cnt+1))
    for deployment in $(kubectl get deployment -n $ns -o json | jq -r '.items[].metadata.name'); do
      kubectl get deployment -n $ns $deployment -o yaml | grep -q "claimName: $pvc_name"
      if [[ "$?" -eq 0 ]]; then
        num_replicas=$(kubectl -n $ns get deployment $deployment -o json | jq -r '.spec.replicas')
        if [[ "$num_replicas" -eq 0 ]]; then
          #
          # We may have already scaled this deployment down or are re-running
          # the upgrade script. Be careful not to write zeros in the 
          # replica count file.
          #
          if [ "$deployment" == "cray-tftp" ]; then
            num_replicas=3
          else
            num_replicas=1
          fi
        fi
        echo "${ns}_${deployment} $num_replicas" >> $cephfs_replica_counts_file
        echo "Ensuring $deployment deployment in namespace $ns is scaled from $num_replicas to zero"
        kubectl scale deployment -n "$ns" "$deployment" --replicas=0
      fi
    done
  done
}

function scale_up_cephfs_clients () {
  cnt=0
  client_list=$(kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName=="ceph-cephfs-external") | .metadata.namespace, .metadata.name')
  client_array=( $client_list )
  array_length=${#client_array[@]}
  while [[ "$cnt" -lt "$array_length" ]]; do
    ns="${client_array[$cnt]}"
    cnt=$((cnt+1))
    pvc_name="${client_array[$cnt]}"
    cnt=$((cnt+1))
    for deployment in $(kubectl get deployment -n $ns -o json | jq -r '.items[].metadata.name'); do
      kubectl get deployment -n $ns $deployment -o yaml | grep -q "claimName: $pvc_name"
      if [[ "$?" -eq 0 ]]; then
        num_replicas=$(grep ${ns}_${deployment} $cephfs_replica_counts_file | awk '{print $NF}')
        echo "Scaling $deployment deployment in namespace $ns back up to $num_replicas"
        kubectl scale deployment -n $ns $deployment --replicas=$num_replicas
      fi
    done
  done
}
