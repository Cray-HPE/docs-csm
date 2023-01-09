#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

function pre_pull_ceph_images () {
  #shellcheck disable=SC2154
  IMAGE="$registry/ceph/ceph:v15.2.8"
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    echo "Pre-pulling $IMAGE image on $host"
    ssh "$host" "cephadm --image $IMAGE pull"
    echo "Verify the image on present on $host"
    ssh "$host" "podman image inspect $IMAGE > /dev/null 2>&1 && echo -e 'Image $IMAGE is present on $host'|| echo 'Image is missing exiting script'; exit 1"
    echo -e "\n"
  done
}
