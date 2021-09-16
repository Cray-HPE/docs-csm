#!/bin/bash


function update_bss_masters() {
  masters=$(kubectl get node --selector='node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,')
  for master in $masters; do
    xName=$(ssh -q -o StrictHostKeyChecking=no $master 'cat /etc/cray/xname')
    cray bss bootparameters list --name $xName --format=json | jq '.[]' > /tmp/$xName
    sed -i 's/kubernetes-cloudinit.sh\"/kubernetes-cloudinit.sh\",/' /tmp/$xName
    if ! grep -q kube-controller-manager /tmp/$xName; then
      sed -i '/kubernetes-cloudinit.sh\",/a \        "sed -i '\''s\/--bind-address=127.0.0.1\/--bind-address=0.0.0.0\/'\'' \/etc\/kubernetes\/manifests\/kube-controller-manager.yaml",\n        "sed -i '\''/--port=0/d'\'' /etc/kubernetes/manifests/kube-scheduler.yaml",\n        "sed -i '\''s/--bind-address=127.0.0.1/--bind-address=0.0.0.0/'\'' /etc/kubernetes/manifests/kube-scheduler.yaml"' /tmp/$xName
      echo "putting config"
      curl -i -s -k -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/bss/boot/v1/bootparameters" -X PUT -d @/tmp/$xName
    fi
  done
}

function update_bss_storage() {
  num_storage_nodes=$(craysys metadata get num-storage-nodes)
  for node_num in $(seq $num_storage_nodes); do
    storage_node=$(printf "ncn-s%03d" "$node_num")
    xName=$(ssh -q -o StrictHostKeyChecking=no $storage_node 'cat /etc/cray/xname')
    cray bss bootparameters list --name $xName --format=json | jq '.[]' > /tmp/$xName
    if ! grep -q "cray-node-exporter-1.2.2.1-1.x86_64.rpm" /tmp/$xName; then
      sed -i '/"\/srv\/cray\/scripts\/common\/update_ca_certs.py"/a \        "zypper --no-gpg-checks in -y https://packages.local/repository/csm-sle-15sp2/cray-node-exporter-1.2.2.1-1.x86_64.rpm"' /tmp/$xName
    fi
    if [[ "$storage_node" =~ "ncn-s001" ]]
    then
      sed -i '/storage-ceph-cloudinit.sh/d' /tmp/$xName
    else
      sed -i 's/update_ca_certs.py\"/update_ca_certs.py\",/' /tmp/$xName
    fi
    echo "putting config"
    curl -i -s -k -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/bss/boot/v1/bootparameters" -X PUT -d @/tmp/$xName
  done
}
