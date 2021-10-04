#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function reconfigure-kube-controller() {
  echo "In reconfigure-kube-controller()"

  #
  # This enables prometheus monitoring of the kube controller
  #
  sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-controller-manager.yaml

  echo "Sleeping 10 seconds after reconfiguring kube controller to let things settle.."
  sleep 10
}

function reconfigure-kube-scheduler() {
  echo "In reconfigure-kube-scheduler()"

  #
  # This enables prometheus monitoring of the scheduler
  #
  sed -i '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-scheduler.yaml

  echo "Sleeping 10 seconds after reconfiguring kube scheduler to let things settle.."
  sleep 10
}

reconfigure-kube-scheduler
reconfigure-kube-controller
