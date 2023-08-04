#! /bin/bash
#
#  MIT License
#
#  (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.
#

# This script will upgrade the Ceph monitoring stack to the same versions
# that are fresh installed on the Storage nodes. These versions are defined
# in /srv/cray/resources/common/ceph-container-versions.sh on Storage nodes

source /srv/cray/resources/common/ceph-container-versions.sh

function redeploy_all_daemons() {
  already_upgraded=0
  for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
    check_current_running_version $daemon
    is_upgraded=$?
    if [[ $is_upgraded -eq 1 ]]; then
      already_upgraded=1
      echo "Upgrading $daemon to ${version_dict["$daemon"]}."
      ceph orch redeploy $daemon
    else
      echo "$daemon is already running the desired version: ${version_dict["$daemon"]}."
    fi
  done
  if [[ $already_upgraded -eq 0 ]]; then
    echo "All Ceph monitoring daemons are already running the desired versions. Nothing to do."
    exit 0
  else
    echo "sleeping 90 seconds. Waiting for daemons to redeploy..."
    sleep 90
  fi
}

function check_current_running_version() {
  daemon_to_check=$1
  for each_version in $(ceph orch ps --daemon_type=$daemon_to_check --format json | jq '.[].version' | tr -d '"'); do
    if [[ "v$each_version" != "${version_dict[$daemon_to_check]}" ]] && [[ $each_version != "${version_dict[$daemon_to_check]}" ]]; then
      return 1
    fi
  done
  return 0
}

function verify_daemon_upgraded() {
  successful_redeploy=0
  for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
    check_current_running_version $daemon
    is_upgraded=$?
    if [[ $is_upgraded -eq 1 ]]; then
      successful_redeploy=1
      echo "$daemon daemon did not upgrade. Redeploying $daemon."
      ceph orch redeploy $daemon
    fi
  done
  if [[ $successful_redeploy -ne 0 ]]; then
    echo "sleeping 90 seconds. Waiting for daemons to redeploy..."
    sleep 90
  fi
  return $successful_redeploy
}

function upgrade_all_daemons() {
  redeploy_all_daemons
  count=0
  success=1
  while [[ $count -lt 3 ]] && [[ $success -eq 1 ]]; do
    verify_daemon_upgraded
    success=$?
    count=$((count + 1))
  done
  if [[ $success -eq 0 ]]; then
    echo "Successfully upgraded Ceph monitoring daemons."
    exit 0
  else
    echo "Error: failed upgrading monitoring daemons. Daemons are not running desired versions."
    echo "Desired versions are Prometheus:${version_dict['prometheus']}, Ceph-Grafana:${version_dict['grafana']}, \
Node-exporter:${version_dict['node-exporter']}, Alertmanager:${version_dict['alertmanager']}"
    exit 1
  fi
}

function main() {
  if [[ $(hostname) != @("ncn-s001"|"ncn-s002"|"ncn-s003") ]]; then
    echo "This script can only be run from ncn-s001/2/3."
    exit 1
  fi

  declare -A version_dict=(
    ['grafana']="${GRAFANA_VERS}"
    ['prometheus']="${PROMETHEUS_VERS}"
    ['node-exporter']="${NODE_EXPORTER_VERS}"
    ['alertmanager']="${ALERTMANAGER_VERS}"
  )

  grafana_image="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana:${version_dict['grafana']}"
  prometheus_image="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/prometheus:${version_dict['prometheus']}"
  node_exporter_image="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/node-exporter:${version_dict['node-exporter']}"
  alertmanager_image="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/alertmanager:${version_dict['alertmanager']}"

  ceph config set mgr mgr/cephadm/container_image_grafana ${grafana_image}
  ceph config set mgr mgr/cephadm/container_image_prometheus ${prometheus_image}
  ceph config set mgr mgr/cephadm/container_image_node_exporter ${node_exporter_image}
  ceph config set mgr mgr/cephadm/container_image_alertmanager ${alertmanager_image}

  upgrade_all_daemons
}

main
