#!/bin/bash

function reconfigure-kube-controller() {
  echo "In reconfigure-kube-controller()"

  #
  # This enables prometheus monitoring of the kube controller
  #
  sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-controller-manager.yaml
}

function reconfigure-kube-scheduler() {
  echo "In reconfigure-kube-scheduler()"

  #
  # This enables prometheus monitoring of the scheduler
  #
  sed -i '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-scheduler.yaml
}
reconfigure-kube-controller
reconfigure-kube-scheduler
