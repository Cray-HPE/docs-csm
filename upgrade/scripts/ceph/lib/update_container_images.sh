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

function update_image_values () {
 #shellcheck disable=SC2154
 IMAGE="$registry/ceph/ceph:v15.2.8"
 ceph config set global container_image $IMAGE
 for SERVICE in mon mgr osd mds client
  do
   CURRENT_IMG_VALUE=$(ceph config get $SERVICE container_image)
   echo "Current image value for $SERVICE is $CURRENT_IMG_VALUE"
   if [ "$CURRENT_IMG_VALUE" != "$IMAGE" ]
   then
    ceph config set $SERVICE $IMAGE
   fi
  done

  echo "Setting additional ceph container images"
  ceph config set mgr mgr/cephadm/container_image_grafana       "$registry/ceph/ceph-grafana:6.6.2"
  ceph config set mgr mgr/cephadm/container_image_prometheus    "$registry/prometheus/prometheus:v2.18.1"
  ceph config set mgr mgr/cephadm/container_image_alertmanager  "$registry/quay.io/prometheus/alertmanager:v0.20.0"
  ceph config set mgr mgr/cephadm/container_image_node_exporter "$registry/quay.io/prometheus/node-exporter:v0.18.1"
}
