#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

function wait_for_health_ok() {
  cnt=0
  while true; do
    if [[ "$cnt" -eq 360 ]]; then
      echo "ERROR: Giving up on waiting for Ceph to become healthy..."
      break
    fi
    ceph_status=$(ceph health -f json-pretty | jq -r .status)
    if [[ $ceph_status == "HEALTH_OK" ]]; then
      echo "Ceph is healthy -- continuing..."
      break
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for Ceph to be healthy..."
    cnt=$((cnt+1))
  done
}

function wait_for_running_daemons() {
  daemon_type=$1
  num_daemons=$2
  cnt=0
  while true; do
    if [[ "$cnt" -eq 60 ]]; then
      echo "ERROR: Giving up on waiting for $num_daemons $daemon_type daemons to be running..."
      break
    fi
    output=$(ceph orch ps --daemon-type $daemon_type -f json-pretty | jq -r '.[] | select(.status_desc=="running") | .daemon_id')
    if [[ "$?" -eq 0 ]]; then
      num_active=$(echo "$output" | wc -l)
      if [[ "$num_active" -eq $num_daemons ]]; then
        echo "Found $num_daemons running $daemon_type daemons -- continuing..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for $num_daemons running $daemon_type daemons..."
    cnt=$((cnt+1))
  done
}

function wait_for_orch_hosts() {
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    echo "Verifying $host is in ceph orch host output..."
    cnt=0
    until ceph orch host ls -f json-pretty | jq -r '.[].hostname' | grep -q $host; do
      echo "Sleeping five seconds to wait for $host to appear in ceph orch host output..."
      sleep 5
      cnt=$((cnt+1))
      if [ "$cnt" -eq 120 ]; then
        echo "ERROR: Giving up waiting for $host to appear in ceph orch host output!"
        break
      fi
    done
  done
}

function wait_for_osd() {
  osd=$1
  cnt=0
  while true; do
    #
    # We have already slept 2 minutes adopting the OSD, so if it is not
    # here yet (after 30 seconds of the 5 minutes), let us kick the
    # active mgr.
    #
    if [[ "$cnt" -eq 6 ]]; then
      echo "INFO: Restarting active mgr daemon to kick things along..."
      ceph mgr fail $(ceph mgr dump | jq -r .active_name)
      cnt=$((cnt+1))
      continue
    fi
    if [[ "$cnt" -eq 60 ]]; then
      echo "ERROR: Giving up on waiting for osd.$osd daemon to be running..."
      exit 1
    fi
    output=$(ceph orch ps --daemon-type osd -f json-pretty | jq -r '.[] | select(.status_desc=="running") | .daemon_id')
    if [[ "$?" -eq 0 ]]; then
      echo "$output" | grep -q $osd
      if [[ "$?" -eq 0 ]]; then
        echo "Found osd.$osd daemon running -- continuing..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for osd.$osd running daemon..."
    cnt=$((cnt+1))
  done
}

function wait_for_osds() {
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    for osd in $(ceph node ls| jq --arg host_key $host -r '.osd[$host_key]|values|tostring|ltrimstr("[")|rtrimstr("]")'| sed "s/,/ /g"); do
      wait_for_osd $osd
   done
 done
}
