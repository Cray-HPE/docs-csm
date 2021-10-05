function enable_ceph_systemd () {
  echo "Enabling all Ceph services to start on boot"
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    echo "Enabling services on host: $host"
    ssh "$host" 'for service in $(cephadm ls |jq -r .[].systemd_unit|grep $(ceph status -f json-pretty |jq -r .fsid));do echo "Enabling service $service on $(hostname)"; systemctl enable $service; done'
    echo "Verifying services on host: $host"
    output=$(ssh "$host" 'for service in $(cephadm ls |jq -r .[].systemd_unit|grep $(ceph status -f json-pretty |jq -r .fsid));do echo $service; systemctl is-enabled $service; done')
    cnt=0
    client_array=( $output )
    array_length=${#client_array[@]}
    while [[ "$cnt" -lt "$array_length" ]]; do
      service="${client_array[$cnt]}"
      cnt=$((cnt+1))
      status="${client_array[$cnt]}"
      cnt=$((cnt+1))
      echo "${service}: $status"
      if [ "$status" == "disabled" ]; then
        retry_enable_service $host $service
      fi
    done
  done
}

enable_ceph_systemd
