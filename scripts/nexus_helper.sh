#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025-2026 Hewlett Packard Enterprise Development LP
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
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

function get_latest_alpine() {
  alpine_versions=$(curl -sk https://registry.local/v2/artifactory.algol60.net/csm-docker/stable/docker.io/library/alpine/tags/list | jq '.tags')
  latest= echo "$alpine_versions" | grep -Eo '\b[0-9]+\.[0-9]+\b' | sort -V | tail -n 1
}

function cache_alpine() {
  alpine_version=${1:-$(get_latest_alpine)}
  workerNodes=$(kubectl get nodes | grep "ncn-w" | awk '{print $1}')
  for node in $workerNodes; do
          ssh "$node" "crictl pull artifactory.algol60.net/csm-docker/stable/docker.io/library/alpine:${alpine_version}"
  done
}
