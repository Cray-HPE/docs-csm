# Begin OSD conversion.  Run on each node that has OSDS

. ./lib/ceph-health.sh

function repair_cephfs () {
  echo "Beginning repair process for cephfs"

  echo "Running cephfs-journal-tool event recover_dentries summary"
  cephfs-journal-tool --rank=cephfs:0 event recover_dentries summary

  echo "Running cephfs-journal-tool journal reset"
  cephfs-journal-tool --rank=cephfs:0 journal reset

  echo "ceph mds repaired cephfs:0"
  ceph mds repaired cephfs:0
}

function upgrade_mds () {

  ceph fs ls
  ceph orch ps --daemon-type mds
  ceph fs status

  date=$(date +%m%e.%H%M)
  echo "Backing up the Ceph MDS Journal"
  cephfs-journal-tool --rank cephfs:all  journal export /root/backup.$date.bin

  export standby_mdss=$(ceph fs dump -f json-pretty|jq -r '.standbys|map(.name)|join(" ")')
  export active_mds=$(ceph fs status -f json-pretty|jq -r '.mdsmap[]|select(.state=="active")|.name')
  export mds_cluster="$active_mds $standby_mdss"

  ceph fs set cephfs max_mds 1
  ceph fs set cephfs allow_standby_replay false
  ceph fs set cephfs standby_count_wanted 0

  echo "Active MDS is: $active_mds"
  echo "Standby MDS(s) are: $standby_mdss"

  ceph orch apply mds cephfs --placement="3 $(ceph node ls |jq -r '.mon|map(.[])|join(" ")')"

  wait_for_running_daemons mds 3

  for host in $mds_cluster
  do
   echo "Stopping mds service on $host"
   ssh $host "systemctl stop ceph-mds.target"
   echo "Cleaning up /var/lib/ceph/mds/ceph-* on $host"
   ssh $host "rm -rf /var/lib/ceph/mds/ceph-*"
  done

  ceph fs set cephfs standby_count_wanted 2
  ceph fs set cephfs allow_standby_replay true
  wait_for_health_ok

  output=$(ceph -s 2>&1 | grep 'mds daemon damaged')
  rc=$?
  echo "Checking to see if mds filesystem is healthy"
  if [ "$rc" -eq 0 ]; then
    repair_cephfs
  fi

  ceph orch ps --daemon-type mds
}
