#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
. ./upgrade-state.sh
ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-unstable-local/csm/
CSM_RELEASE=$1

if [[ -z ${CSM_RELEASE} ]]; then
    echo "CSM RELEASE is not specified"
    exit 1
fi

state_name="GET_CSM_TARBALL_FILE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="UNTAR_CSM_TARBALL_FILE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    tar -xzf ${CSM_RELEASE}.tar.gz
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="INSTALL_CSI"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="INSTALL_WAR_DOC"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    rpm -Uvh \
        https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm && \
    rpm -Uvh \
        https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    ./${CSM_RELEASE}/lib/setup-nexus.sh
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="UPGRADE_BSS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    helm -n services upgrade cray-hms-bss ./${CSM_RELEASE}/helm/cray-hms-bss-*.tgz
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="APPLY_POD_PRIORITY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    . ./add_pod_priority.sh
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi


state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
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
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="EXPORT_GLOBAL_ENV"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    
    echo "export CEPH_VERSION=${CEPH_VERSION}" >> myenv
    echo "export KUBERNETES_VERSION=${KUBERNETES_VERSION}" >> myenv
    echo "export CSM_RELEASE=${CSM_RELEASE}" >> myenv
    
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."

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

    rpm -Uvh $(find $CSM_RELEASE -name \*csm-testing\* | sort | tail -1)
    goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
    
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has beed completed"
fi
