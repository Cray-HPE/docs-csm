#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --csm-version)
    CSM_RELEASE="$2"
    shift # past argument
    shift # past value
    ;;
    --endpoint)
    SEARCHPATH="$2"
    shift # past argument
    shift # past value
    ;;
    --tarball-file)
    TARBALL_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "[ERROR] - unknow options"
    exit 1
    ;;
esac
done


if [[ -z ${CSM_RELEASE} ]]; then
    echo "CSM RELEASE is not specified"
    exit 1
fi

if [[ -z ${TARBALL_FILE} ]]; then
    # Download tarball from internet 
    
    if [[ -z ${ENDPOINT} ]]; then
        # default endpoint to internal artifactory
        ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-unstable-local/csm/
        echo "Use internal endpoint: ${ENDPOINT}"
    fi

    # Download tarball file
    state_name="GET_CSM_TARBALL_FILE"
    state_recorded=$(is_state_recorded "${state_name}" $(hostname))
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."
        wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
        # set TARBALL_FILE to newly downloaded file
        TARBALL_FILE=${CSM_RELEASE}.tar.gz

        record_state ${state_name} $(hostname)
        echo
    else
        echo "====> ${state_name} has beed completed"
    fi
fi

# untar csm tarball file
state_name="UNTAR_CSM_TARBALL_FILE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    tar -xzf ${TARBALL_FILE}

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="INSTALL_CSI"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    rpm --force -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
    
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="INSTALL_WAR_DOC"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    rpm --force -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/noarch/csm-install-workarounds-*.noarch.rpm
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    ./${CSM_RELEASE}/lib/setup-nexus.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="UPGRADE_BSS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    helm -n services upgrade cray-hms-bss ./${CSM_RELEASE}/helm/cray-hms-bss-*.tgz
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="APPLY_POD_PRIORITY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    . ${BASEDIR}/add_pod_priority.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="UPGRADE_BSS_CLOUD_INIT"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."

    # get bss cloud-init data with host_records
    curl -k -H "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global|jq .[] > cloud-init-global.json

    # get ip of api-gw in nmn
    ip=$(dig api-gw-service-nmn.local +short)

    # get entry number to add record to
    entry_number=$(jq '."cloud-init"."meta-data".host_records|length' cloud-init-global.json )

    # check for record already exists and create the script to be idempotent
    for ((i=0;i<$entry_number; i++)); do
        record=$(jq '."cloud-init"."meta-data".host_records['$i']' cloud-init-global.json)
        if [[ $record =~ "packages.local" ]] || [[ $record =~ "registry.local" ]]; then
                echo "packages.local and registry.local already in BSS cloud-init host_records"
                exit 0
        fi
    done

    # create the updated json
    jq '."cloud-init"."meta-data".host_records['$entry_number']|= . + {"aliases": ["packages.local", "registry.local"],"ip": "'$ip'"}' cloud-init-global.json  > cloud-init-global_update.json

    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
	    --request PUT \
	    --data @cloud-init-global_update.json \
	    https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="UDATE_CRAY_DHCP_KEA_TRAFFIC_POLICY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    kubectl -n services patch service cray-dhcp-kea-tcp-hmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-tcp-nmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-udp-nmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-udp-hmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    temp_file=$(mktemp)
    artdir=./${CSM_RELEASE}/images
    csi handoff ncn-images \
          --kubeconfig /etc/kubernetes/admin.conf \
          --k8s-kernel-path $artdir/kubernetes/*.kernel \
          --k8s-initrd-path $artdir/kubernetes/initrd.img*.xz \
          --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
          --ceph-kernel-path $artdir/storage-ceph/*.kernel \
          --ceph-initrd-path $artdir/storage-ceph/initrd.img*.xz \
          --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs | tee $temp_file

    KUBERNETES_VERSION=`cat $temp_file | grep "export KUBERNETES_VERSION=" | awk -F'=' '{print $2}'`
    CEPH_VERSION=`cat $temp_file | grep "export CEPH_VERSION=" | awk -F'=' '{print $2}'`
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="EXPORT_GLOBAL_ENV"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    rm -rf myenv
    echo "export CEPH_VERSION=${CEPH_VERSION}" >> myenv
    echo "export KUBERNETES_VERSION=${KUBERNETES_VERSION}" >> myenv
    echo "export CSM_RELEASE=${CSM_RELEASE}" >> myenv
    echo "export DOC_RPM_NEXUS_URL=https://packages.local/repository/csm-sle-15sp2/$(ls ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/noarch/docs-csm-install-*.noarch.rpm | awk -F'/sle-15sp2/' '{print $2}')" >> myenv
    
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    REQUIRED_PATCH_NUM=3
    versions=$(kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm')
    patch_versions=$(echo "${versions}" | grep ^0.9)

    if [ "$patch_versions" == "" ]; then
      echo "Required CSM patch 0.9.3 has not been applied to this system"
      exit 1
    fi

    highest_patch_num=0
    for patch_version in $patch_versions; do
      patch_num=$(echo $patch_version | sed 's/://' | awk -F '.' '{print $NF}')
      if [[ "$patch_num" -gt "$highest_patch_num" ]]; then
        highest_patch_num=$patch_num
      fi
    done

    if [[ "$highest_patch_num" -ne "$REQUIRED_PATCH_NUM" ]]; then
      echo "Required CSM patch 0.9.3 has not been applied to this system"
      exit 1
    fi

    rpm --force -Uvh $(find $CSM_RELEASE -name \*csm-testing\* | sort | tail -1)
    goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
    
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has beed completed"
fi
