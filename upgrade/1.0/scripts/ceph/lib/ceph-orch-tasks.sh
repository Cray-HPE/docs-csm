function ceph_orch_tasks () {
 for host in $(ceph node ls| jq -r '.osd|keys[]')
  do
   echo "Adding $host to the ceph orchestrator"
   ceph orch host add $host
  done
 ceph orch ps
 ceph orch host ls
}
