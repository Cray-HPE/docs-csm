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

# File name is a bit of a historical misnomer, this does upload executable
# ceph container images from a storage node to nexus, but it also changes what
# is running (so that those pushed images are actually used). It does this by
# modifying the /etc/containers/registry.conf file on the storage node to point
# to the nexus registry and then restarting the services.

m002_ip=$(host ncn-m002 | awk '{ print $NF }')
ssh-keygen -R ncn-m002 -f ~/.ssh/known_hosts > /dev/null 2>&1
ssh-keygen -R "${m002_ip}" -f ~/.ssh/known_hosts > /dev/null 2>&1
ssh-keyscan -H "ncn-m002,${m002_ip}" >> ~/.ssh/known_hosts

nexus_username=$(ssh ncn-m002 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.username}} | base64 --decode')
nexus_password=$(ssh ncn-m002 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.password}} | base64 --decode')
ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ceph_nexus_digest_file="/tmp/ceph_nexus_digest"

function oneshot_health_check() {
  ceph_status=$(ceph health -f json-pretty | jq -r .status)
  if [[ $ceph_status != "HEALTH_OK" ]]; then
    echo "ERROR: Ceph is not healthy!"
    return 1
  fi
}

function wait_for_health_ok() {
  cnt=0
  cnt2=0
  while true; do
    if [[ -n "$node" ]] && [[ "$cnt" -eq 300 ]] ; then
      check_mon_daemon "${node}"
    else
      if [[ "$cnt" -eq 360 ]]; then
        echo "ERROR: Giving up on waiting for Ceph to become healthy..."
        break
      fi
      if [[ $(ceph crash ls-new -f json|jq -r '.|map(.crash_id)|length') -gt 0 ]]; then
        echo "archiving ceph crashes that may have been caused by restarts."
	ceph crash archive-all
      fi
      ceph_status=$(ceph health -f json-pretty | jq -r .status)
      if [[ $ceph_status == "HEALTH_OK" ]]; then
        echo "Ceph is healthy -- continuing..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for Ceph to be healthy..."
    cnt2=$((cnt2+1))
    if [[ $cnt2 -ge 10 ]]; then
      echo "Failing Ceph mgr daemon over to clear any stuck messages and sleeping 20 seconds."
      ceph mgr fail
      sleep 20
      cnt2=0
    fi
  done
} # end wait_for_health_ok()

function wait_for_running_daemons() {
  daemon_type=$1
  num_daemons=$2
  cnt=0
  while true; do
    if [[ "$cnt" -eq 60 ]]; then
      echo "ERROR: Giving up on waiting for $num_daemons $daemon_type daemons to be running..."
      break
    fi
    output=$(ceph orch ps --daemon-type "$daemon_type" -f json-pretty | jq -r '.[] | select(.status_desc=="running") | .daemon_id')
    if [[ -n "$output" ]]; then
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
    until ceph orch host ls -f json-pretty | jq -r '.[].hostname' | grep -q "$host"; do
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
      # shellcheck disable=SC2046
      ceph mgr fail $(ceph mgr dump | jq -r .active_name)
      cnt=$((cnt+1))
      continue
    fi
    if [[ "$cnt" -eq 60 ]]; then
      echo "ERROR: Giving up on waiting for osd.$osd daemon to be running..."
      exit 1
    fi
    output=$(ceph orch ps --daemon-type osd -f json-pretty | jq -r '.[] | select(.status_desc=="running") | .daemon_id')
    if [[ -n "$output" ]]; then
      echo "$output" | grep -q "$osd"
      if echo "$output" | grep -q "$osd"; then
        echo "Found osd.$osd daemon running -- continuing..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for osd.$osd running daemon..."
    cnt=$((cnt+1))
  done
} # end wait_for_osd()

function wait_for_osds() {
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    for osd in $(ceph node ls| jq --arg host_key "$host" -r '.osd[$host_key]|values|tostring|ltrimstr("[")|rtrimstr("]")'| sed "s/,/ /g"); do
      wait_for_osd "$osd"
   done
 done
}

function get_ip_from_metadata() {
  host=$1
  ip=$(cloud-init query ds | jq -r ".meta_data[].host_records[] | select(.aliases[]? == \"$host\") | .ip" 2>/dev/null)
  echo "$ip"
}

function wait_for_mon_stat() {
  node=$1
  cnt=0
  while true; do
    if [[ "$cnt" -eq 60 ]]; then
      echo "ERROR: Giving up waiting for mon process to start on $node..."
      break
    fi
    if [[ "$cnt" -eq 30 ]]; then
      echo "Manually adding mon process for $node..."
      ip=$(get_ip_from_metadata "${node}.nmn")
      ceph mon add "$node" "$ip"
    else
      state_name=$(ceph mon stat -f json-pretty | jq --arg node "$node" -r '.quorum[] | select(.name==$node) | .name' )
      if [ "$state_name" == "$node" ]; then
        echo "Found mon process on $node..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for mon process to start on $node..."
    cnt=$((cnt+1))
  done
}

function check_mon_daemon() {
  node=$1
  state_name=$(ceph mon stat -f json-pretty | jq --arg node "$node" -r '.quorum[] | select(.name==$node) | .name' )
  if [ "$state_name" == "$node" ]; then
    echo "Found ${node} in ceph mon stat command, continuing..."
  else
    echo "Didn't find ${node} in ceph mon stat command, ensuring we have quorum before restarting daemon..."
    if ! ceph mon ok-to-stop "${node}"; then
      echo "Unable to restart mon process for ${node}, would break quorum, halting..."
      exit 1
    fi
    echo "Removing/restarting mon daemon for node ${node}..."
    ceph orch daemon rm mon."${node}" --force
    wait_for_running_daemons "mon" 3
    wait_for_mon_stat "${node}"
    echo "Archiving daemon crash info..."
    ceph crash archive-all
  fi
}

function check_currently_running_nexus_image() {
  node=$1
  nexus_sha=$(cat ${ceph_nexus_digest_file})
  for daemon in "mon" "mgr" "osd" "mds" "crash" "rgw"; do
    for each in $(ssh ${node} ${ssh_options} "podman ps --filter name=$daemon --format {{.Image}}" ); do
      if [[ -z $(echo $each | grep "$nexus_sha" ) && -z $(echo $each | grep $nexus_location) ]]; then
        echo "false"
        return 0
      fi
    done
  done
  echo "true"
}

function redeploy_monitoring_stack() {
# restart daemons
for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
  daemons_to_restart=$(ceph --name client.ro orch ps | awk '{print $1}' | grep $daemon)
  for each in $daemons_to_restart; do
    for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        # shellcheck disable=SC2086
        # shellcheck disable=SC2029
        if ssh ${storage_node} ${ssh_options} "ceph orch daemon redeploy $each"; then
          break
        fi
      done
  done
done
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
    echo "Pushing image: $local_image to $nexus_location"
    podman pull "$local_image"
    podman tag "$local_image" "$nexus_location"
    if [[ $name == "mgr" ]]; then
      # save the digestfile of the mgr image, this contains the sha in nexus
      podman push --creds "$nexus_username":"$nexus_password" "$nexus_location" --digestfile=${ceph_nexus_digest_file}
    else
      podman push --creds "$nexus_username":"$nexus_password" "$nexus_location"
    fi
    for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        # shellcheck disable=SC2086
        # shellcheck disable=SC2029
        if [[ $(ssh ${storage_node} ${ssh_options} "ceph config set mgr $to_configure $nexus_location") ]]; then
          break
        fi
    done
    for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        # shellcheck disable=SC2086
        if [[ $(ssh ${storage_node} ${ssh_options} "ceph config rm mgr mgr/cephadm/container_image_base ") ]]; then
          break
        fi
    done
} # end of upload_image()

function redeploy_ceph_services(){
  # restart daemons
  for node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
    running_nexus_image=$(check_currently_running_nexus_image $node)
    if ! $running_nexus_image; then
      echo "$node is not running all ceph services using the image in nexus. Redeploying these daemons using the nexus image."
      enter_maintenance_mode
      # shellcheck disable=SC2086
      ssh ${node} ${ssh_options} "podman rmi --all --force"
      exit_maintenance_mode
      for daemon in "mon" "mgr" "osd" "mds" "crash" "rgw"; do
        daemons_to_restart=$(ceph --name client.ro orch ps "$node"| awk '{print $1}' | grep $daemon)
        for each in $daemons_to_restart; do
          #shellcheck disable=SC2086
          if [[ $(hostname) = @("ncn-s001"|"ncn-s002"|"ncn-s003") ]]; then
            ceph config set global container_image ${nexus_location}
            ceph orch daemon redeploy "$each" --image "$nexus_location"
          else
            echo "This script can only be run from ncn-s001/2/3."
            exit 1
          fi
        done
      done
      wait_for_health_ok
    else
      echo "$node is already running all ceph services using the image in nexus."
    fi
  done
}

function enter_maintenance_mode() {
  # shellcheck disable=SC2076
  if [[ $(ceph mgr stat|jq -r '.active_name') =~ "$node" ]]; then
    echo "Active Ceph mgr process detected on $node.  Failing the Ceph mgr process to another node."
    ceph mgr fail
  fi
  # shellcheck disable=SC2076
  until [[ ! "$(ceph mgr stat|jq -r '.active_name')" =~ "$node" ]]; do
    echo "waiting for mgr to fail over"
    sleep 10
  done
  echo "entering mainenance mode for $node"
  ceph orch host maintenance enter "$node" --force
  counter=0
  # shellcheck disable=SC2086
  until [[ "$(ceph orch host ls --host_pattern $node --format json-pretty|jq -r '.[].status')" == "maintenance" ]]; do
    echo "Waiting for node $node to enter maintenance mode."
    (( counter ++ ))
    if [[ $counter -ge 5 ]]; then
      echo "First Attempt to enter maintenance mode on $node was not possible due to cluster recovery. Attempting to enter mainenance mode for $node again."
      ceph orch host maintenance enter "$node" --force
    fi
    sleep 10
  done
}

function exit_maintenance_mode() {
  echo "exiting maintenance mode for ${node}"
  # shellcheck disable=SC2086
  if [[ "$(ceph orch host maintenance exit $node)" ]]; then
    # shellcheck disable=SC2086
    counter=0
    until [[ "$(ceph orch host ls --host_pattern $node --format json-pretty|jq -r '.[].status')" != "maintenance" ]]; do
      echo "Waiting for node $node to exit maintenance mode."
      sleep 15
      counter=$(( counter + 1 ))
      if [[ $counter -ge 5 ]]; then
        echo "$node is still in maintenance mode. Failing the Ceph mgr process to another node to force $node to exit maintenance mode."
        ceph mgr fail
        counter=0
      fi
    done
  else
    echo "Could not exit maintenance mode on $node.  Please check ceph services on $node and ensure they are started."
  fi
}

function disable_local_registries() {
  echo "Disabling local docker registries"
  systemctl_force="--now"

  for storage_node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
    #shellcheck disable=SC2029
    if ssh "${storage_node}" "${ssh_options}" "systemctl disable registry.container.service ${systemctl_force}"; then
       if ! ssh "${storage_node}" "${ssh_options}" "systemctl is-enabled registry.container.service"; then
         echo "Docker registry service on ${storage_node} has been disabled"
       fi
    fi
  done
}

function fix_registries_conf() {
  HEREFILE=$(mktemp)
  cat > "${HEREFILE}" <<'EOF'
# For more information on this configuration file, see containers-registries.conf(5).
#
# Registries to search for images that are not fully-qualified.
# i.e. foobar.com/my_image:latest vs my_image:latest
[registries.search]
registries = []
unqualified-search-registries = ["registry.local", "localhost"]

# Registries that do not use TLS when pulling images or uses self-signed
# certificates.
[registries.insecure]
registries = []
unqualified-search-registries = ["localhost", "registry.local"]

# Blocked Registries, blocks the  from pulling from the blocked registry.  If you specify
# "*", then the docker daemon will only be allowed to pull from registries listed above in the search
# registries.  Blocked Registries is deprecated because other container runtimes and tools will not use it.
# It is recommended that you use the trust policy file /etc/containers/policy.json to control which
# registries you want to allow users to pull and push from.  policy.json gives greater flexibility, and
# supports all container runtimes and tools including the docker daemon, cri-o, buildah ...
[registries.block]
registries = []

## ADD BELOW

[[registry]]
prefix = "registry.local"
location = "registry.local"
insecure = true

[[registry.mirror]]
prefix = "registry.local"
location = "localhost:5000"
insecure = true

[[registry]]
location = "localhost:5000"
insecure = true

[[registry]]
prefix = "localhost"
location = "localhost:5000"
insecure = true

[[registry]]
prefix = "artifactory.algol60.net/csm-docker/stable/quay.io"
location = "artifactory.algol60.net/csm-docker/stable/quay.io"
insecure = true

[[registry.mirror]]
prefix = "artifactory.algol60.net/csm-docker/stable/quay.io"
location = "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io"
insecure = true

EOF

  for storage_node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
    scp "${ssh_options}" "${HEREFILE}" "${storage_node}":/etc/containers/registries.conf
  done
} #end fix_registries_conf()

#First check to make sure ceph is healthy prior to making any changes
if ! oneshot_health_check; then
  echo "Ceph is not healthy.  Please check ceph status and try again."
  exit 1
fi


# Begin upload of local images into nexus
#prometheus, node-exporter, and alertmanager have this prefix
ceph_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/"
ceph_grafana_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana/"
prometheus_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/"
disable_local_registries
fix_registries_conf
upload_image "prometheus" $prometheus_prefix "mgr/cephadm/container_image_prometheus"
upload_image "node-exporter" $prometheus_prefix "mgr/cephadm/container_image_node_exporter"
upload_image "alertmanager" $prometheus_prefix "mgr/cephadm/container_image_alertmanager"
upload_image "grafana" $ceph_grafana_prefix "mgr/cephadm/container_image_grafana"

## mgr and grafana have this prfix
#ceph_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/"
upload_image "mgr" $ceph_prefix "container_image"

wait_for_health_ok

redeploy_monitoring_stack
wait_for_health_ok
redeploy_ceph_services
wait_for_health_ok
echo "Process is complete."
