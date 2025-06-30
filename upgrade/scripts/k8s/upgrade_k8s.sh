#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
set -euo pipefail

PROG=$(basename "$0")
usage() {
  echo "Usage: ${PROG} [-h] -v <kubernetes_versions_array>"
  echo "    -h                Print this help message"
  echo "    -v                Array containing all kubernetes intermediate versions along with from and to versions needed"
  echo "                      to perform the upgrade in increasing order. List cannot contain more than 3 versions."
  echo "                      Example: '1.27.16 1.28.15 1.29.15'"
  echo "    -d                When running outside of IUF, drain and uncordon master nodes when upgrading kubelet."
}

while getopts "v:dh" opt; do
  case "${opt}" in
    v)
      # shellcheck disable=SC2206
      KUBERNETES_VERSIONS=(${OPTARG})
      # Length of list cannot be more than 3
      if [ ${#KUBERNETES_VERSIONS[@]} -gt 3 ]; then
        echo "Too many versions! Cannot have more than 3."
        usage >&2
        exit 1
      fi
      ;;
    d)
      echo "Drain master nodes when upgrading kubelet."
      DRAIN="true"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] && {
  echo "${PROG}: Too many arguments" >&2
  usage >&2
  exit 1
}

if [[ ! -v KUBERNETES_VERSIONS ]]; then
  echo "Missing option '-v' which is required" >&2
  usage >&2
  exit 1
fi

if [[ ! -v DRAIN ]]; then
  # Not draining master nodes before kubelet upgrade because could terminate argo pod
  # running this script. If running script outside of IUF, use '-d' option.
  echo "DO NOT drain master nodes when upgrading kubelet."
  DRAIN="false"
fi

# Hashmaps for rpms we need to install per k8s version beyond k8s v1.26
# Assumption is that we're already at k8s v1.26
#
# Note: there is no hash map for cri-tools because it is upgraded automatically
# by kubeadm.
declare -A k8s_cni
k8s_cni["1.27"]="1.2.0"
k8s_cni["1.28"]="1.2.0"
k8s_cni["1.29"]="1.3.0"
k8s_cni["1.30"]="1.4.0"
k8s_cni["1.31"]="1.5.1"
k8s_cni["1.32"]="1.6.0"

declare -A pause
pause["1.27"]="3.9"
pause["1.28"]="3.9"
pause["1.29"]="3.9"
pause["1.30"]="3.9"
pause["1.31"]="3.10"
pause["1.32"]="3.10"

function prefix() {
  # We hardcode a log level of INFO for now to ensure IUF displays our logs.
  echo -n "INFO $(date --iso-8601=seconds) $(basename "$0")"
}

function fix_sysconfig() {
  # fix_sysconfig $host
  # Where 'host' is a master or worker host. For example, ncn-m001
  NODE_IP=$(ssh $1 "dig +short \$(hostname).nmn | grep -v -E '^;;'")

  ssh "$1" "cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS=\"--node-ip ${NODE_IP}\"
EOF"
}

function update_kubelet_config_cm() {
  # First, update kubelet-config configmap to add containerRuntimeEndpoint. This
  # is necessary because --container-runtime-endpoint was deprecated as a kubelet
  # command line argument in K8s 1.27.
  workdir="$(mktemp -d)"
  kubectl get configmap kubelet-config -n kube-system -o yaml > "${workdir}/kubelet-config.yaml"
  yq4 eval -P '.data.kubelet' "${workdir}/kubelet-config.yaml" > "${workdir}/kubelet-config-kubelet.yaml"
  yq4 eval -i -P '.containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock"' "${workdir}/kubelet-config-kubelet.yaml"

  # Merge our kubelet config back into the kubelet-config manifest.
  if IFS= read -rd '' -a kubelet_config; then
    :
  fi <<< "$(cat "${workdir}/kubelet-config-kubelet.yaml")"
  kubelet_config=$kubelet_config yq4 eval -i '.data.kubelet = strenv(kubelet_config)' "${workdir}/kubelet-config.yaml"

  # Update the kubelet-config configmap.
  kubectl -n kube-system apply -f "${workdir}/kubelet-config.yaml"
}

function migrate_kubeadmcfg_yaml() {
  # migrate_kubeadmcfg_yaml ncn-m001
  # Given master host, run kubeadm config migrate on /etc/kubernetes/kubeadmcfg.yaml
  host=$1
  yaml_file="/etc/kubernetes/kubeadmcfg.yaml"
  workdir="$(mktemp -d)"
  echo "$(prefix) INFO Working directory for $host is $workdir"
  old_yaml_file="${workdir}/v1beta3-kubeadmcfg.yaml"
  new_yaml_file="${workdir}/v1beta4-kubeadmcfg.yaml"
  # Make a copy of yaml file
  ssh "$host" "mkdir -p $workdir; cp ${yaml_file} ${old_yaml_file}"
  # Migrate v1beta3 config to v1beta4 config
  ssh $host kubeadm config migrate --old-config ${old_yaml_file} | yq4 '. | select(.kind == "ClusterConfiguration") | pick(["apiVersion", "kind", "kubernetesVersion", "caCertificateValidityPeriod", "certificateValidityPeriod", "etcd"])' > ${new_yaml_file}
  # The new_yaml_file is located on the calling host
  # Update cert validity period to 3 years
  yq4 eval -i -P '.certificateValidityPeriod = "26280h0m0s"' ${new_yaml_file}
  # Copy new_yaml_file to $host:$yaml_file
  scp $new_yaml_file $host:${yaml_file}
}

masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)
workers=$(grep -oP 'ncn-w\d+' /etc/hosts | sort -u)

# We'll only upgrade the kubelet on the masters and the workers to the target version
# which is the last version in the KUBERNETES_VERSIONS list
target_version="${KUBERNETES_VERSIONS[-1]}"
v_target_version="v${target_version}"
minor_target_version=${target_version%.*}

echo "$(prefix) Beginning Kubernetes upgrade to ${target_version}."

for version in "${KUBERNETES_VERSIONS[@]}"; do
  minor_version=${version%.*}

  if [[ $(bc -l <<< "${minor_version} < 1.27") -eq 1 ]]; then
    echo "$(prefix) ERROR Upgrade version cannot be less than v1.27. Exiting ..." >&2
    usage >&2
    exit 1
  fi

  # If there is one time config map work to do for a k8s version, put it here
  if [ "$minor_version" = "1.27" ]; then
    # Edit kubelet-config cm
    update_kubelet_config_cm
  fi

  for host in ${masters}; do
    # Check that current k8s version is less than or equal to the minor_version.
    # We don't want to downgrade, so if minor_version is less than current version, do nothing.
    current_version=$(ssh $host kubeadm version -o json | jq -r '.clientVersion.gitVersion' | cut -c 2-5)
    if [[ $(bc -l <<< "${minor_version} > ${current_version}") -eq 1 ]]; then
      echo "$(prefix) Installing [kubeadm-${version}] on [${host}]."
      ssh "${host}" zypper --non-interactive install "kubeadm-${version}"
      ssh "${host}" zypper --non-interactive install "kubernetes-cni-${k8s_cni[${minor_version}]}"

      echo "$(prefix) Running kubeadm upgrade apply v${version} on [${host}]."
      if [[ $(bc -l <<< "${minor_version} < 1.30") -eq 1 ]]; then
        ssh "${host}" kubeadm upgrade apply -y "v${version}" --force
      else
        ssh "${host}" kubeadm upgrade apply -y "v${version}"
      fi
    else
      echo "$(prefix) INFO Version ${minor_version} is less than ${current_version}. Don't need to upgrade kubeadm for '$host'."
    fi
  done
done

# Upgrade kubelet on master nodes for target_version.
echo "$(prefix) Upgrading kubelet on master nodes to ${target_version}."

for host in ${masters}; do
  # Check current kubelet version.
  current_version=$(ssh $host kubelet --version | awk '{ print $2 }' | cut -c 2-5)
  if [[ $(bc -l <<< "${minor_target_version} > ${current_version}") -eq 1 ]]; then
    if [ "$DRAIN" = "true" ]; then
      # Drain the node, ignoring daemonsets and deleting emptydir data.
      echo "$(prefix) Draining node: [${host}]."
      kubectl drain "${host}" --ignore-daemonsets --delete-emptydir-data
    fi

    # Fix /etc/sysconfig/kubelet
    fix_sysconfig "${host}"

    # Update pause version in containerd
    pause_version="pause:${pause[${minor_target_version}]}"
    ssh "${host}" sed -i -e "s/pause:[0-9]*.[0-9]*/$pause_version/g" /etc/containerd/config.toml
    # Restart containerd.
    ssh "${host}" systemctl restart containerd

    # Update kubelet and kubectl. We don't need to update these one at a
    # time; we can skip up to three versions at a time.
    echo "$(prefix) Installing [kubelet-${target_version}] and [kubectl-${target_version}] on [${host}]."
    ssh "${host}" zypper --non-interactive install "kubelet-${target_version}" "kubectl-${target_version}"

    # Reload daemons and restart kubelet.
    ssh "${host}" systemctl daemon-reload
    ssh "${host}" systemctl restart kubelet

    # Update K8s version in /etc/cray/kubernetes/kubeadmcfg.yaml, only on masters
    ssh "${host}" "V_TARGET_VERSION=$v_target_version yq4 eval -i -P '.kubernetesVersion = strenv(V_TARGET_VERSION)' '/etc/kubernetes/kubeadmcfg.yaml'"

    if [ "$DRAIN" = "true" ]; then
      # Mark the node ready for scheduling.
      echo "$(prefix) Uncordoning node: [${host}]."
      kubectl uncordon "${host}"
    fi
  else
    echo "$(prefix) INFO Version ${minor_target_version} is less than ${current_version}. Don't need to upgrade kubelet for '$host'."
  fi
done

echo "$(prefix) Upgrading kubelet on worker nodes to ${target_version}."

for host in ${workers}; do
  # Check current kubelet version.
  current_version=$(ssh $host kubelet --version | awk '{ print $2 }' | cut -c 2-5)
  if [[ $(bc -l <<< "${minor_target_version} > ${current_version}") -eq 1 ]]; then
    echo "$(prefix) Installing [kubeadm-${target_version}] on [${host}]."
    ssh "${host}" zypper --non-interactive install "kubeadm-${target_version}"
    ssh "${host}" zypper --non-interactive install "kubernetes-cni-${k8s_cni[${minor_target_version}]}"
    ssh "${host}" kubeadm upgrade node
    kubectl drain --ignore-daemonsets --delete-emptydir-data "${host}"

    # Fix /etc/sysconfig/kubelet
    fix_sysconfig "${host}"
    # Remove --container-runtime=remote argument from KUBELET_KUBEADM_ARGS.
    kube_kubeadm_args='KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=/run/containerd/containerd.sock --pod-infra-container-image=artifactory.algol60.net/csm-docker/stable/k8s.gcr.io/pause:'${pause[${minor_target_version}]}'"'
    echo "$kube_kubeadm_args" > /var/lib/kubelet/kubeadm-flags.env

    # Update pause version in containerd
    pause_version="pause:${pause[${minor_target_version}]}"
    ssh "${host}" sed -i -e "s/pause:[0-9]*.[0-9]*/$pause_version/g" /etc/containerd/config.toml
    # Restart containerd.
    ssh "${host}" systemctl restart containerd

    # Update kubelet and kubectl. We don't need to update these one at a
    # time; we can skip up to three versions at a time.
    echo "$(prefix) Installing [kubelet-${target_version}] and [kubectl-${target_version}] on [${host}]."
    ssh "${host}" zypper --non-interactive install "kubelet-${target_version}" "kubectl-${target_version}"

    # Reload daemons and restart kubelet.
    ssh "${host}" systemctl daemon-reload
    ssh "${host}" systemctl restart kubelet

    kubectl uncordon "${host}"

    # Need to wait 2 minutes for pods to settle before doing another drain.
    echo "$(prefix) Waiting 2 minutes for pods to settle ..."
    sleep 120
  else
    echo "$(prefix) INFO Version ${minor_target_version} is less than ${current_version}. Don't need to upgrade kubelet for '$host'."
  fi
done

echo "$(prefix) Upgrade to ${target_version} complete."

echo "$(prefix) Verifying that all ncn nodes at expected K8s ${v_target_version}"
all_ncns="${masters} ${workers}"
BAD_NODES=0
for host in ${all_ncns}; do
  # Check kubeadm version on all nodes and make sure it matches v_target_version
  current_version=$(ssh $host kubeadm version -o json | jq -r '.clientVersion.gitVersion')
  current_minor_version=${current_version%.*}
  current_minor_version=${current_minor_version#v}
  if [ "${current_minor_version}" = "1.32" ]; then
    echo "$(prefix) ${host} version is already at ${current_version}"
  elif [ "${current_version}" != "${v_target_version}" ]; then
    echo "$(prefix) ERROR K8s version on $host is ${current_version} expected ${v_target_version}." >&2
    ((BAD_NODES++))
  else
    echo "$(prefix) ${host} version is ${current_version} expect ${v_target_version}"
  fi
done

# If we have any bad nodes ... exit
if [ $BAD_NODES -gt 0 ]; then
  echo "$(prefix) ERROR ${BAD_NODES} nodes not at expected K8s ${v_target_version} version. Exiting ..." >&2
  exit 1
fi

# If minor_target_version is 1.32, on all master nodes
# migrate kubeadmcfg.yaml and kubeadm.cfg to v1beta4 and renew all certificates
if [ "${minor_target_version}" = "1.32" ]; then
  for host in ${masters}; do
    echo "$(prefix) Migrating /etc/kubernetes/kubeadmcfg.yaml to v1beta4 on each of the master nodes."
    migrate_kubeadmcfg_yaml $host
    # Generate certs with new kubeadmcfg.yaml on each master node
    ssh $host kubeadm certs renew all --config /etc/kubernetes/kubeadmcfg.yaml
    ssh $host kubeadm certs check-expiration
    # Running kubeadm upgrade apply will restart all kube-system pods and services
    current_version=$(ssh $host kubeadm version -o json | jq -r '.clientVersion.gitVersion')
    ssh $host kubeadm upgrade apply -y "${current_version}"
  done
  echo "$(prefix) Migration to kubeadm v1beta4 complete."
  echo "$(prefix) All certificates have been renewed."
fi
