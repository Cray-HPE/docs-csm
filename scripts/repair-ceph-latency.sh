#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

max_latency="${1:-100}"
seconds_sustained_latency="${2:-10}"
osd_memory_target_gb="${3:-6}"
osd_memory_target_bytes=$((osd_memory_target_gb * 1024 * 1024 * 1024))
max_total_latency=$((max_latency * seconds_sustained_latency))
num_osds_with_latency=0
max_osds_with_latency=2

function check_osd_for_sustained_latency() {
  local osd=$1
  local cnt=0
  local total_latency=0
  while true; do
    if [[ "$cnt" -lt "$seconds_sustained_latency" ]]; then
      tmp_latency=$(ceph osd perf | awk '{print $1,$2}' | grep "^${osd}[[:space:]]" | awk '{print $2}')
      total_latency=$((total_latency+tmp_latency))
      sleep 1
    else
      if [[ "$total_latency" -gt "$max_total_latency" ]]; then
         echo "WARNING: osd.${osd} average latency exceeds ${max_latency}ms over ${seconds_sustained_latency} seconds"
         num_osds_with_latency=$((num_osds_with_latency+1))
      else
         echo "INFO: no latency detected for osd.${osd}"
      fi
      break
    fi
    cnt=$((cnt+1))
  done
}

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

function check_osds_for_latency() {
  set_memory_target_settings
  for osd in $(ceph osd ls)
  do
    check_osd_for_sustained_latency ${osd}
    if [ $num_osds_with_latency -ge $max_osds_with_latency ]; then
      echo "WARNING: found ${max_osds_with_latency} osds with latency, proceeding with restarts..."
      restart_osds
      break
    fi
  done

  echo "INFO: failing active manager to another node one final time."
  ceph mgr fail

  if [ $num_osds_with_latency -lt $max_osds_with_latency ]; then
    echo "SUCCESS: found fewer than ${max_osds_with_latency} osds with latency exceeding ${max_latency}ms over ${seconds_sustained_latency} seconds."
  else
    echo "SUCCESS: all restarts complete."
  fi
}

wait_for_health_ok 60 # 5 minutes max
check_osds_for_latency
