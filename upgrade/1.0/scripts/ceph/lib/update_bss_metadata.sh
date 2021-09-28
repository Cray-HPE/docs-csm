#!/bin/bash

function update_bss_storage() {
  export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
  num_storage_nodes=$(craysys metadata get num-storage-nodes)
  for node_num in $(seq $num_storage_nodes); do
    storage_node=$(printf "ncn-s%03d" "$node_num")
    pdsh -N -w $storage_node "systemctl stop cray-node-exporter.service; systemctl disable cray-node-exporter.service"
    xName=$(ssh -q -o StrictHostKeyChecking=no $storage_node 'cat /etc/cray/xname')
    cray bss bootparameters list --name $xName --format=json | jq '.[]' > /tmp/$xName
    if  grep -q "cray-node-exporter-1.2.2" /tmp/$xName; then
      sed -i '/cray-node-exporter-1.2.2/d' /tmp/$xName
    fi
    if ! grep -q pre-load-images.sh /tmp/$xName; then
      sed -i '/"\/srv\/cray\/scripts\/common\/update_ca_certs.py"/a \        "\/srv\/cray\/scripts\/common\/pre-load-images.sh",' /tmp/$xName
    fi
    if [[ "$storage_node" =~ "ncn-s001" ]]
    then
      sed -i '/storage-ceph-cloudinit.sh/d' /tmp/$xName
    fi
    echo "putting config"
    curl -i -s -k -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/bss/boot/v1/bootparameters" -X PUT -d @/tmp/$xName
  done
}
