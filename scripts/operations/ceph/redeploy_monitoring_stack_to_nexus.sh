#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

# This script moves the Ceph monitoring daemons running a local image
# to an image in Nexus. This pushes the local images to Nexus, sets the
# Ceph configuration, and then redeploys the monitoring stack. Once this
# script has completed, all Ceph monitoring daemons should be using an image
# in Nexus.

function redeploy_monitoring_stack() {
  echo -e "\nREDEPLOYING CEPH MONITORING STACK."
  echo "(This will redeploy all prometheus, node-exporter, alertmanager, and grafana daemons so that they will be using the container image in nexus.)"
  for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
    echo "Redploying $daemon daemons."
    daemons_to_restart=$(ceph --name client.ro orch ps --daemon_type $daemon | awk '{print $1}' | tail -n+2)
    for each in $daemons_to_restart; do
      ceph orch daemon redeploy $each
    done
  done
  sleep 90
  verify_monitoring_stack
}

function verify_monitoring_stack() {
  monitoring_stack_redeployed="false"
  mon_count=0
  until [[ $monitoring_stack_redeployed == "true" ]]; do
    redeploy_failed_monitoring_daemons
    check_monitoring_daemons_using_nexus_image "false"
    if [[ $? -eq 0 ]]; then
        monitoring_stack_redeployed="true"
    fi
    mon_count=$(( mon_count + 1 ))
    if [[ $mon_count -eq 10 ]] && [[ $monitoring_stack_redeployed != "true" ]]; then
      echo "ERROR Redeploying monitoring stack onto images in Nexus. Manually investigate Ceph to see why monitoring stack cannot redeploy."
      echo "Run 'ceph health detail'."
      exit 1
    fi
  done
  echo "All Ceph monitoring daemons are using the image in Nexus."
}

function redeploy_failed_monitoring_daemons() {
  echo -e "\nVerifying monitoring stack daemons are 'running'."
  should_recheck=0
  count=0
  until [[ $should_recheck == 0 ]]; do
    should_recheck=0
    for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
      # using grep to get the info below. jq cannot be used 
      # becasue some ceph 'event' values are incorrectly formatted and jq fails to filter json
      daemons_not_running=$(ceph orch ps --daemon_type $daemon | grep -v 'running' | tail -n+2 | awk '{print $1}')
      for each in $daemons_not_running; do
        should_recheck=1
        echo "${each} is not 'running'. Redeploying ${each}."
        ceph orch daemon redeploy $each
      done
    done
    if [[ $count -eq 10 ]]; then
      echo "ERROR Failed to redeploy Ceph monitoring stack. Please manually check \
that storage nodes are able to pull monitoring images from Nexus and that the 'Ceph Config' \
is set so that daemons are using container images in Nexus."
      exit 1
    else
      count=$((count + 1))
    fi
    if [[ $should_recheck -eq 1 ]]; then
      echo "Sleeping 60 seconds to allow daemons to redeploy."
      sleep 60
    fi
  done
} # end of redeploy_failed_monitoring_daemons()

function check_monitoring_daemons_using_nexus_image() {
  # returns 1 if not all daemons are using Nexus image. Otherwise, returns 0
  check_only=$1
  echo "Checking that monitoring daemons are using the image in Nexus."
  all_using_nexus_image="true"
  for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
    for node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
      for each in $(ssh ${node} ${ssh_options} "podman ps --filter name=$daemon --format='{{.Image}},{{.ID}}'" ); do
        image=$(echo $each | awk -F, '{print $1}')
        container_id=$(echo $each | awk -F, '{print $2}')
        if [[ -z $(echo $image | grep "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io") ]]; then
          daemon_name=$(ceph orch ps --daemon_type $daemon | grep $container_id | awk '{print $1}')
          if [[ $check_only != "true" ]]; then
            echo "$daemon_name is not using the image in Nexus. Redeploy $daemon_name."
            ceph orch daemon redeploy $daemon_name
            all_using_nexus_image="false"
          else
            return 1
          fi
        fi
      done
    done
  done
  if [[ $all_using_nexus_image == "false" ]] && [[ $check_only != "true" ]]; then
    echo "Sleeping 60 seconds to allow daemons to redeploy."
    sleep 60
    return 1
  fi
  return 0
}

function upload_ceph_container_images() {
  # Begin upload of local images into nexus
  #prometheus, node-exporter, and alertmanager have this prefix
  prometheus_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/"
  upload_image "prometheus" $prometheus_prefix "mgr/cephadm/container_image_prometheus"
  upload_image "node-exporter" $prometheus_prefix "mgr/cephadm/container_image_node_exporter"
  upload_image "alertmanager" $prometheus_prefix "mgr/cephadm/container_image_alertmanager"
  ## grafana has this prfix
  ceph_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/"
  upload_image "grafana" $ceph_prefix "mgr/cephadm/container_image_grafana"
}

function upload_image() {
  # get local image and nexus image location
  name=$1
  prefix=$2
  to_configure=$3
  local_image=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON "$name" '.[] | select(.daemon_type == $DAEMON) | .container_image_name' | tr -d '"' | sort -u | tail -1)
  # if sha in image then remove and use version
  if [[ $local_image == *"@sha"* ]]; then
    without_sha=${local_image%"@sha"*}
    version=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON "$name" '.[] | select(.daemon_type == $DAEMON) | .version' | tr -d '"' | sort -u)
    if [[ $version != "v"* ]]; then version="v""$version"; fi
    local_image="$without_sha"":""$version"
  fi
  nexus_location="${prefix}""$(echo "$local_image" | rev | cut -d "/" -f1 | rev)"

  # push images to nexus, point to nexus and run upgrade
  echo -e "\nPushing image: $local_image to $nexus_location"
  podman pull "$local_image"
  podman tag "$local_image" "$nexus_location"
  podman push --creds "$nexus_username":"$nexus_password" "$nexus_location"
  ceph config set mgr $to_configure $nexus_location
} # end of upload_image()

### END OF FUNCTIONS ###

# pre-checks
if [[ $(hostname) != @("ncn-s001"|"ncn-s002"|"ncn-s003") ]]; then
  echo "This script can only be run from ncn-s001/2/3."
  exit 1
fi

nexus_username="$(kubectl -n nexus get secret nexus-admin-credential --template '{{.data.username}}' | base64 --decode)"
nexus_password="$(kubectl get secret -n nexus nexus-admin-credential --template '{{.data.password}}' | base64 --decode)"
ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if [[ -z ${nexus_username} ]] || [[ -z ${nexus_password} ]]; then
  echo "ERROR unable to get Nexus username or password. Make sure 'kubectl' commands can be run from the node this script is running on."
  exit 1
fi

check_monitoring_daemons_using_nexus_image "true"
if [[ $? -eq 0 ]]; then
  echo "Ceph monitoring daemons are already using images in Nexus."
  exit 0
fi

upload_ceph_container_images
redeploy_monitoring_stack

echo "Process is complete."
