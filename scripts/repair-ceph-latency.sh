#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

osd_memory_target_gb="${1:-6}"
osd_memory_target_bytes=$((osd_memory_target_gb * 1024 * 1024 * 1024))

function wait_for_health_ok() {
  local num_attempts=$1
  cnt=0
  while true; do
    if [[ "$cnt" -eq "$num_attempts" ]]; then
      echo "ERROR: Ceph did not become healthy in the expected time, manual troubleshooting required."
      break
    fi
    ceph -s | grep -q HEALTH_OK
    if [[ "$?" -eq 0 ]]; then
      echo "Ceph is healthy -- continuing..."
      break
    fi
    sleep 5
    echo "Sleeping for five seconds waiting ceph to be healthy..."
    cnt=$((cnt+1))
  done
}

function wait_for_stopped_daemons() {
  local host=$1
  while true; do
    echo "Sleeping for ten seconds waiting for daemons to stop..."
    sleep 10
    num_running=$(ceph orch ps ${host} --format json-pretty| jq -r '.[]|select(.status_desc!="stopped")|.daemon_name+"  status: "+.status_desc' | wc -l)
    if [[ "$num_running" -eq 0 ]]; then
      echo "All daemons stopped, continuing..."
      break
    fi
  done
}

function wait_for_osds_up() {
  local num_attempts=$1
  cnt=0
  while true; do
    if [[ "$cnt" -eq "$num_attempts" ]]; then
      echo "ERROR: osds did not come up in expected time, manual troubleshooting required."
      break
    fi
    ceph -s | grep -q 'osds down'
    if [[ "$?" -ne 0 ]]; then
      echo "All osds up, continuing..."
      break
    fi
    echo "Sleeping for thirty seconds waiting for osds to be up (be patient)..."
    sleep 30
    cnt=$((cnt+1))
  done
}

function fail_active_mgr_if_needed() {
  local host=$1
  is_active=$(ceph orch ps ${host} --format json-pretty | jq -r '.[]|select(.daemon_type=="mgr")| .is_active')
  if [ "$is_active" == "true" ]; then
    echo "INFO: failing active manager to another node (from ${host})."
    ceph mgr fail
    echo "Sleeping for 30 seconds waiting for mgr to fail over..."
    sleep 30
  else
    echo "INFO: active manager is not running on ${host}, no need to fail over to another node."
  fi
}

function restart_osds_by_host() {
  local host=$1
  echo "INFO: beginning restart of daemons on ${host}."
  fail_active_mgr_if_needed ${host}
  ceph osd set noout
  ceph osd set norecover
  ceph osd set nobackfill
  ceph orch host maintenance enter ${host} --force
  wait_for_stopped_daemons ${host}
  ceph orch host maintenance exit ${host}
  wait_for_osds_up 360 # 3 hour max
  ceph osd unset noout
  ceph osd unset norecover
  ceph osd unset nobackfill
  wait_for_health_ok 360 # 30 min max
  echo "INFO: done with restart of daemons on ${host}."
}

function restart_osds() {
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    restart_osds_by_host ${host}
    restart_osds_by_host ${host} # second restart frees up memory
  done
}

function set_memory_target_settings() {
  ceph config rm osd bluestore_rocksdb_options
  ceph config set osd osd_memory_target_autotune true
  ceph config set osd osd_memory_target ${osd_memory_target_bytes}
}

function repair_ceph_latency() {
  set_memory_target_settings
  restart_osds
  echo "INFO: failing active manager to another node one final time."
  ceph mgr fail
  echo "SUCCESS: all restarts complete."
}

wait_for_health_ok 60 # 5 minutes max
repair_ceph_latency
