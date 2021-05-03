# Scale down cephfs clients to prevent mds corruption issues

cephfs_replica_counts_file="/etc/cray/ceph/cephfs_replica_counts"

function scale_down_cephfs_clients () {
  now=$(date +"%H:%M:%S_%m-%d-%Y")
  backup_name="$now-snapshot"

  echo "Taking a snapshot of nexus pvc ($backup_name)"
  kubectl -n nexus exec -it $(kubectl get po -n nexus -l 'app=nexus' -o json | jq -r '.items[].metadata.name') -c nexus -- /bin/sh -c "mkdir /nexus-data/.snap/$backup_name"

  echo "Sleeping 10 seconds after taking nexus pvc snapshot"
  sleep 10

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
        echo "${ns}_${deployment} $num_replicas" >> $cephfs_replica_counts_file
        echo "Scaling $deployment deployment in namespace $ns from $num_replicas to zero"
        kubectl scale deployment -n $ns $deployment --replicas=0
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
