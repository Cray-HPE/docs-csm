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

#!/bin/bash

m001_ip=$(host ncn-m001 | awk '{ print $NF }')
ssh-keygen -R ncn-m001 -f ~/.ssh/known_hosts > /dev/null 2>&1
ssh-keygen -R ${m001_ip} -f ~/.ssh/known_hosts > /dev/null 2>&1
ssh-keyscan -H "ncn-m001,${m001_ip}" >> ~/.ssh/known_hosts

nexus_username=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.username}} | base64 --decode')
nexus_password=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.password}} | base64 --decode')

ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
function upload_image_and_upgrade() {
    # get local image and nexus image location
    name=$1
    prefix=$2
    to_configure=$3
    local_image=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON $name '.[] | select(.daemon_type == $DAEMON) | .container_image_name' | tr -d '"' | sort -u | tail -1)
    # if sha in image then remove and use version
    if [[ $local_image == *"@sha"* ]]; then
        without_sha=${local_image%"@sha"*}
        version=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON $name '.[] | select(.daemon_type == $DAEMON) | .version' | tr -d '"' | sort -u)
        if [[ $version != "v"* ]]; then version="v""$version"; fi
        local_image="$without_sha"":""$version"
    fi
    nexus_location="${prefix}""$(echo "$local_image" | rev | cut -d "/" -f1 | rev)"

    # push images to nexus, point to nexus and run upgrade
    echo "Pushing image: $local_image to $nexus_location"
    podman pull $local_image
    podman tag $local_image $nexus_location
    podman push --creds $nexus_username:$nexus_password $nexus_location
    for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        ssh $storage_node ${ssh_options} "ceph config set mgr $to_configure $nexus_location"
        if [[ $? == 0 ]]; then
          break
        fi
    done
    
    # run upgrade if mgr
    if [[ $name == "mgr" ]]; then
      for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        ssh $storage_node ${ssh_options} "ceph config set global container_image $nexus_location"
        ssh $storage_node ${ssh_options} "ceph orch upgrade start --image $nexus_location"
        if [[ $? == 0 ]]; then
          break
        fi
      done
    fi
}

#prometheus, node-exporter, and alertmanager have this prefix
prometheus_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/"
upload_image_and_upgrade "prometheus" $prometheus_prefix "mgr/cephadm/container_image_prometheus"
upload_image_and_upgrade "node-exporter" $prometheus_prefix "mgr/cephadm/container_image_node_exporter"
upload_image_and_upgrade "alertmanager" $prometheus_prefix "mgr/cephadm/container_image_alertmanager"

# mgr and grafana have this prfix
ceph_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/"
upload_image_and_upgrade "grafana" $ceph_prefix "mgr/cephadm/container_image_grafana"
upload_image_and_upgrade "mgr" $ceph_prefix "container_image_base"

# watch upgrade status
echo "Waiting for upgrade to complete..."
sleep 10
int=0
success=false
while [[ $int -lt 100 ]] && ! $success; do
  for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
    error=$(ssh $storage_node ${ssh_options} "ceph orch upgrade status --format json | jq '.message' | grep Error")
    if [[ -n $error ]]; then
      echo "Error: there was an issue with the upgrade. Run 'ceph orch upgrade status' from ncn-s00[1/2/3]."
      exit 1
    fi
    if [[ $(ssh $storage_node ${ssh_options} "ceph orch upgrade status --format json | jq '.in_progress'") != "true" ]]; then
      echo "Upgrade complete"
      success=true
      break
    else
      int=$(( $int + 1 ))
      sleep 10
    fi
  done
done
if ! $success; then
  echo "Error completing 'ceph orch upgrade'. Check upgrade status by running 'ceph orch upgrade status' from ncn-s00[1/2/3]."
  exit 1 
fi

# restart daemons
for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
  daemons_to_restart=$(ceph --name client.ro orch ps | awk '{print $1}' | grep $daemon)
  for each in $daemons_to_restart; do
    for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        ssh $storage_node ${ssh_options} "ceph orch daemon redeploy $each"
        if [[ $? == 0 ]]; then
          break
        fi
      done
  done
done

echo "Process is complete."