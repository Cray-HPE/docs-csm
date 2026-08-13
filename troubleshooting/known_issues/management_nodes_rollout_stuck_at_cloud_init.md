# Cloud init loops for master node: unknown field `udpIdleTimeout`

## Issue description

During a CSM upgrade, cloud init keeps looping with an error while fetching the `kubeadm-config` `configmap` due to an unknown field `udpIdleTimeout` being present in the `configmap`.

## Issue identification

1. Console logs from cloud-init shows the below messages and keep looping.

   ```bash
    [ 2793.365094] cloud-init[12289]: [preflight] Running pre-flight checks
    [ 2793.662029] cloud-init[12289]: [preflight] Reading configuration from the cluster...
    [ 2793.662295] cloud-init[12289]: [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
    [ 2793.676480] cloud-init[12289]: W1202 18:35:21.771765   76408 configset.go:177] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: strict decoding error: unknown field "udpIdleTimeout"
    [ 2793.704137] cloud-init[12289]: error execution phase preflight: unable to fetch the kubeadm-config ConfigMap: this version of kubeadm only supports deploying clusters with the control plane version >= 1.25.0. Current version: v1.24.17
    [ 2793.704351] cloud-init[12289]: To see the stack trace of this error execute with --v=5 or higher
    [ 2793.770533] cloud-init[12289]: [preflight] Running pre-flight checks
    [ 2793.770764] cloud-init[12289]: W1202 18:35:21.865871   76487 removeetcdmember.go:106] [reset] No kubeadm config, using etcd pod spec to get data directory
    [ 2793.771215] cloud-init[12289]: [reset] Deleted contents of the etcd data directory: /var/lib/etcd
    [ 2793.771312] cloud-init[12289]: [reset] Stopping the kubelet service
    [ 2793.790699] cloud-init[12289]: [reset] Unmounting mounted directories in "/var/lib/kubelet"
    [ 2793.847330] cloud-init[12289]: [reset] Deleting contents of directories: [/etc/kubernetes/manifests /var/lib/kubelet /etc/kubernetes/pki]
    [ 2793.848054] cloud-init[12289]: [reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
    [ 2793.848241] cloud-init[12289]: The reset process does not clean CNI configuration. To do so, you must remove /etc/cni/net.d
    [ 2793.848377] cloud-init[12289]: The reset process does not reset or clean up iptables rules or IPVS tables.
    [ 2793.848508] cloud-init[12289]: If you wish to reset iptables, you must do so manually by using the "iptables" command.
    [ 2793.848637] cloud-init[12289]: If your cluster was setup to utilize IPVS, run ipvsadm --clear (or similar)
   ```

1. (`ncn-m#`)Check whether `udpIdleTimeout` exists in `kube-proxy`.

   ```bash
   kubectl get cm -n kube-system kube-proxy -o yaml | grep udpIdle
   ```

   Example output:

   ```text
    udpIdleTimeout: 0s
    ```

## Issue conditions

This issue occurs when `PREPARE_KUBEADM` successfully patches `kube-proxy`, but a later process updates `kube-proxy` ConfigMap content and reintroduces `udpIdleTimeout`.

## Workaround description

1. (`ncn-m#`)Create the `PREPARE_KUBEADM.sh` script using the below command

   ```bash
   cat > PREPARE_KUBEADM.sh <<'EOF'
   #!/bin/bash

   tmpdir=$(mktemp -d)

   # This is necessary for the initial 1.24.17 to 1.26.15 bump. Otherwise,
   # kubeadm commands in kubernetes-cloudinit.sh fail. We also need to make
   # sure we don't enable the PodSecurityPolicy plugin by removing it from the
   # existing configmap.
   echo "Patching kubeadm-config configmap to update kubernetesVersion from 1.24.17 to 1.26.15 ..."
   kubectl -n kube-system get configmap kubeadm-config -o go-template --template '{{ .data.ClusterConfiguration }}' \
     | yq4 e '.kubernetesVersion="v1.26.15"' \
     | yq4 e '.apiServer.extraArgs.enable-admission-plugins="NodeRestriction"' \
       > "${tmpdir}/kubeadm-config.yaml"
   patch=$(jq -c -n --rawfile text "${tmpdir}/kubeadm-config.yaml" '.data["ClusterConfiguration"]=$text')
   kubectl -n kube-system patch configmap kubeadm-config --type merge --patch "${patch}"

   echo "Patching kube-proxy configmap to remove udpIdleTimeout ..."
   kubectl -n kube-system get configmap kube-proxy -o go-template --template '{{ index .data "config.conf" }}' \
     | yq4 e 'del(.udpIdleTimeout)' \
       > "${tmpdir}/kube-proxy.yaml"
   patch=$(jq -c -n --rawfile text "${tmpdir}/kube-proxy.yaml" '.data["config.conf"]=$text')
   kubectl -n kube-system patch configmap kube-proxy --type merge --patch "${patch}"

   rm -rf "${tmpdir}"
   EOF
   ```

1. (`ncn-m#`)Execute the script using these command:

   ```bash
   chmod +x PREPARE_KUBEADM.sh
   ./PREPARE_KUBEADM.sh
   ```

1. (`ncn-m#`)Verify that the `udpIdleTimeout` was removed post the script execution:

   ```bash
   kubectl get cm -n kube-system kube-proxy -o yaml | grep udpIdle
   ```
