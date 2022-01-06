#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Scale down cephfs clients to prevent mds corruption issues

cephfs_deployments_replica_counts_file="/etc/cray/ceph/cephfs_deployments_replica_counts"
cephfs_statefulsets_replica_counts_file="/etc/cray/ceph/cephfs_statefulsets_replica_counts"

function scale_down_cephfs_clients () {
  now=$(date +"%H:%M:%S_%m-%d-%Y")
  backup_name="$now-snapshot"

  echo "Taking a snapshot of nexus pvc ($backup_name)"
  output=$(kubectl -n nexus exec -it $(kubectl get po -n nexus -l 'app=nexus' -o json | jq -r '.items[].metadata.name') -c nexus -- /bin/sh -c "mkdir /nexus-data/.snap/$backup_name" 2>&1)
  if [[ "$?" -ne 0 ]]; then
    echo "Did not find nexus pod to take snapshot from -- continuing..."
  fi

  touch $cephfs_deployments_replica_counts_file
  touch $cephfs_statefulsets_replica_counts_file

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
        if [[ "$num_replicas" -ne 0 ]]; then
          if ! grep -q ${ns}_${deployment} $cephfs_deployments_replica_counts_file; then
            #
            # Only add number of replicas to the counts file if it's not there,
            # allowing for the script to be re-run as the deployment is being scaled down.
            #
            echo "${ns}_${deployment} $num_replicas" >> $cephfs_deployments_replica_counts_file
          fi
          echo "Ensuring $deployment deployment in namespace $ns is scaled from $num_replicas to zero"
          kubectl scale deployment -n "$ns" "$deployment" --replicas=0
        fi
      fi
    done
    for statefulset in $(kubectl get statefulset -n $ns -o json | jq -r '.items[].metadata.name'); do
      kubectl get statefulset -n $ns $statefulset -o yaml | grep -q "claimName: $pvc_name"
      if [[ "$?" -eq 0 ]]; then
        num_replicas=$(kubectl -n $ns get statefulset $statefulset -o json | jq -r '.spec.replicas')
        if [[ "$num_replicas" -ne 0 ]]; then
          if ! grep -q ${ns}_${statefulset} $cephfs_statefulsets_replica_counts_file; then
            #
            # Only add number of replicas to the counts file if it's not there,
            # allowing for the script to be re-run as the statefulset is being scaled down.
            #
            echo "${ns}_${statefulset} $num_replicas" >> $cephfs_statefulsets_replica_counts_file
          fi
          echo "Ensuring $statefulset statefulset in namespace $ns is scaled from $num_replicas to zero"
          kubectl scale statefulset -n "$ns" "$statefulset" --replicas=0
        fi
      fi
    done
  done

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
        num_ready=1
        until [[ "${num_ready}" -eq 0 ]]; do
          num_ready=$(kubectl -n $ns get deployment $deployment -o json | jq -r '.status.readyReplicas')
          if [[ "${num_ready}" -eq 0 ]]; then
            break
          fi
          echo "Waiting for $deployment deployment in $ns namespace to scale down (${num_ready} pod(s) running)..."
          sleep 5
        done
        echo "Deployment $deployment in namespace $ns has been scaled down."
      fi
    done
    for statefulset in $(kubectl get statefulset -n $ns -o json | jq -r '.items[].metadata.name'); do
      kubectl get statefulset -n $ns $statefulset -o yaml | grep -q "claimName: $pvc_name"
      if [[ "$?" -eq 0 ]]; then
        num_ready=1
        until [[ "${num_ready}" -eq 0 ]]; do
          num_ready=$(kubectl -n $ns get statefulset $statefulset -o json | jq -r '.status.readyReplicas')
          if [[ "${num_ready}" -eq 0 ]]; then
            break
          fi
          echo "Waiting for $statefulset statefulset in $ns namespace to scale down (${num_ready} pod(s) running)..."
          sleep 5
        done
        echo "Statefulset $statefulset in namespace $ns has been scaled down."
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
        num_replicas=$(grep ${ns}_${deployment} $cephfs_deployments_replica_counts_file | awk '{print $NF}')
        echo "Scaling $deployment deployment in namespace $ns back up to $num_replicas"
        kubectl scale deployment -n $ns $deployment --replicas=$num_replicas
      fi
    done
    for statefulset in $(kubectl get statefulset -n $ns -o json | jq -r '.items[].metadata.name'); do
      kubectl get statefulset -n $ns $statefulset -o yaml | grep -q "claimName: $pvc_name"
      if [[ "$?" -eq 0 ]]; then
        num_replicas=$(grep ${ns}_${statefulset} $cephfs_statefulsets_replica_counts_file | head -1l | awk '{print $NF}')
        echo "Scaling $statefulset statefulset in namespace $ns back up to $num_replicas"
        kubectl scale statefulset -n $ns $statefulset --replicas=$num_replicas
      fi
    done
  done
}
