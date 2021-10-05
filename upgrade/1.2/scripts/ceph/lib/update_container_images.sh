#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

function update_image_values () {
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
