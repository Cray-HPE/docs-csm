#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Begin OSD conversion. Run on each node that has OSDs
FSID=$(ceph status -f json-pretty |jq -r .fsid)
function upgrade_osds () {
for host in $(ceph node ls| jq -r '.osd|keys[]')
 do
  for osd in $(ceph node ls| jq --arg host_key "$host" -r '.osd[$host_key]|values|tostring|ltrimstr("[")|rtrimstr("]")'| sed "s/,/ /g")
   do
    if [[ ! "$(ceph tell osd.$osd version|jq -r '.version')" =~ "15.2.8" ]]
     then
        timeout 300 ssh "$host" "cephadm --image $registry/ceph/ceph:v15.2.8 adopt --style legacy --name osd.$osd" --skip-pull
        if [ $? -ne 0 ]
        then
          ceph mgr fail $(ceph mgr dump | jq -r .active_name)
        fi
        sleep 10
        while [[ ! "$(ceph tell osd.$osd version|jq -r '.version')" =~ "15.2.8" ]]
          do
             sleep 10
          done
      else
         echo "$osd has already been upgraded"
      fi
      echo "Waiting for osd.$osd status to update from booting -> active.  This will take minutes, be patient.."
      (( counter=0 ))
      until ssh "$host" journalctl -u ceph-$FSID@osd.$osd --no-pager |grep "booting -> active"
       do
	   (( counter++ ))
           sleep 30
	   if [[ $counter > 10 ]]
	   then
	     echo "OSD status should have been active by now, failing the mgr process and restarting the osd"
             ceph mgr fail $(ceph mgr dump | jq -r .active_name)
	     echo "Sleep 30 seconds to allow the new mgr process to start"
             echo "Restarting OSD $osd"
	     ceph orch daemon restart osd.$osd
	   fi
       done
    done

  echo "Sleeping 2 minutes to let the OSDs settle down.."
  sleep 120

 done

 ceph osd require-osd-release octopus
 for host in $(ceph node ls| jq -r '.osd|keys[]')
 do
    for id in $(ceph osd ls-tree $host)
      do
        echo "Waiting for osd.$id require_osd_release update nautilus -> octopus.  This will take minutes, be patient.."
        until ssh "$host" journalctl -u ceph-$FSID@osd.$id --no-pager |grep "nautilus -> octopus"
        do
           sleep 30
        done
    done
  done
}

# End OSD conversion. Run on each node that has OSDs
