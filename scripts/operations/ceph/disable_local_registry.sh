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

# This will disable the local registry on all storage nodes.
# This should be run once all Ceph daemons have transitioned to
# using images in Nexus. This would have been done through a Ceph
# upgrade and by running redeploy_monitoring_stack_to_nexus.sh.

function validate_all_daemons_are_running_nexus_image() {
    for node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
        for each in $(ssh ${node} ${ssh_options} "podman ps --format {{.Image}}" ); do
            if [[ -z $(echo $each | grep "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io") && -z $(echo $each | grep "localhost/registry") ]]; then
                echo "$each is still being used. Not all Ceph daemons are using an image in Nexus."
                echo "The local registry should not be disabled until no Ceph daemons are using images from the local registry. Exiting."
                exit 1
            fi
        done
    done
}

function disable_local_registries() {
  echo "Disabling local docker registries"
  systemctl_force="--now"

  for storage_node in $(ceph orch host ls -f json |jq -r '.[].hostname'); do
    #shellcheck disable=SC2029
    if ssh ${storage_node} ${ssh_options} "systemctl disable registry.container.service ${systemctl_force}"; then
       if ! ssh ${storage_node} ${ssh_options} "systemctl is-enabled registry.container.service"; then
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
    scp ${ssh_options} "${HEREFILE}" "${storage_node}:/etc/containers/registries.conf"
  done
} #end fix_registries_conf()

ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

validate_all_daemons_are_running_nexus_image
disable_local_registries
fix_registries_conf
