#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
. ${BASEDIR}/ncn-upgrade-common.sh $(hostname)
trap 'err_report' ERR
# array for paths to unmount after chrooting images
declare -a UNMOUNTS=()

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
    ENDPOINT="$2"
    shift # past argument
    shift # past value
    ;;
    --tarball-file)
    TARBALL_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "[ERROR] - unknown options"
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
        ENDPOINT=https://artifactory.algol60.net/artifactory/releases/csm/1.2/
        echo "Use internal endpoint: ${ENDPOINT}"
    fi

    # Ensure we have enough disk space
    reqSpace=80000000 # ~80GB
    availSpace=$(df "$HOME" | awk 'NR==2 { print $4 }')
    if (( availSpace < reqSpace )); then
        echo "Not enough space, required: $reqSpace, available space: $availSpace" >&2
        exit 1
    fi

    # Download tarball file
    state_name="GET_CSM_TARBALL_FILE"
    state_recorded=$(is_state_recorded "${state_name}" $(hostname))
    if [[ $state_recorded == "0" ]]; then
        # Because we are getting a new tarball
        # this has to be a new upgrade
        # clean up myenv 
        # this is block/breaking 1.0 to 1.0 upgrade
        rm -rf /etc/cray/upgrade/csm/myenv || true
        touch /etc/cray/upgrade/csm/myenv
        echo "====> ${state_name} ..."
        wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
        # set TARBALL_FILE to newly downloaded file
        TARBALL_FILE=${CSM_RELEASE}.tar.gz

        record_state ${state_name} $(hostname)
        echo
    else
        echo "====> ${state_name} has been completed"
    fi
fi

# untar csm tarball file
state_name="UNTAR_CSM_TARBALL_FILE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    mkdir -p /etc/cray/upgrade/csm/${CSM_RELEASE}/tarball
    tar -xzf ${TARBALL_FILE} -C /etc/cray/upgrade/csm/${CSM_RELEASE}/tarball
    CSM_ARTI_DIR=/etc/cray/upgrade/csm/${CSM_RELEASE}/tarball/${CSM_RELEASE}
    echo "export CSM_ARTI_DIR=/etc/cray/upgrade/csm/${CSM_RELEASE}/tarball/${CSM_RELEASE}" >> /etc/cray/upgrade/csm/myenv
    rm -rf ${TARBALL_FILE}

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    . ${BASEDIR}/ncn-upgrade-common.sh ${upgrade_ncn}
     grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'truncate --size=0 ~/.ssh/known_hosts'

     grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts'

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CHECK_CLOUD_INIT_PREREQ"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    echo "Ensuring cloud-init is healthy"
    set +e
    # K8s nodes
    for host in $(kubectl get nodes -o json |jq -r '.items[].metadata.name')
    do
        echo "Node: $host"
        (( counter=0 ))
        ssh_keygen_keyscan $host
        until ssh $host test -f /run/cloud-init/instance-data.json
        do
            ssh $host cloud-init init 2>&1 >/dev/null
            (( counter++ ))
            sleep 10
            if [[ $counter > 5 ]]
            then
            echo "Cloud init data is missing and cannot be recreated. Existing upgrade.."
            fi
        done
    done


    ## Ceph nodes
    for host in $(ceph node ls|jq -r '.osd|keys[]')
    do
    echo "Node: $host"
    (( counter=0 ))
    ssh_keygen_keyscan $host
    until ssh $host test -f /run/cloud-init/instance-data.json
    do
        ssh $host cloud-init init 2>&1 >/dev/null
        (( counter++ ))
        sleep 10
        if [[ $counter > 5 ]]
        then
            echo "Cloud init data is missing and cannot be recreated. Existing upgrade.."
        fi
    done
    done

    set -e
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_CSI"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    rpm --force -Uvh $(find ${CSM_ARTI_DIR}/rpm/cray/csm/ -name "cray-site-init*.rpm") 

    # upload csi to s3
    csi handoff upload-utils --kubeconfig /etc/kubernetes/admin.conf

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_DOC_RPM"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    if [[ ! -f /root/docs-csm-latest.noarch.rpm ]]; then
        echo "Please make sure 'docs-csm-latest.noarch.rpm' exists under: $(pwd)"
    fi
    cp /root/docs-csm-latest.noarch.rpm ${CSM_ARTI_DIR}/rpm/cray/csm/sle-15sp2/
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    ${CSM_ARTI_DIR}/lib/setup-nexus.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="DISABLE_SERVICE_REPOS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    NCNS=$(${CSM_ARTI_DIR}/lib/list-ncns.sh | paste -sd,)
    pdsh -w "$NCNS" 'zypper ms -d Basesystem_Module_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d Public_Cloud_Module_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d SUSE_Linux_Enterprise_Server_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d Server_Applications_Module_15_SP2_x86_64'
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_BSS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    helm -n services upgrade cray-hms-bss ${CSM_ARTI_DIR}/helm/cray-hms-bss-*.tgz
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_KEA"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    helm -n services upgrade cray-dhcp-kea ${CSM_ARTI_DIR}/helm/cray-dhcp-kea-*.tgz
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_CSM_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    helm -n services upgrade csm-config ${CSM_ARTI_DIR}/helm/csm-config-*.tgz --wait
    CSM_CONFIG_VERSION=$(helm list -n services -o json | jq -r '.[] | select (.name=="csm-config") | .app_version')
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_CFS_OPERATOR"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    helm -n services upgrade cray-cfs-operator ${CSM_ARTI_DIR}/helm/cray-cfs-operator-*.tgz
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_CLOUD_INIT_RECORDS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."

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
        fi
    done

    # create the updated json
    jq '."cloud-init"."meta-data".host_records['$entry_number']|= . + {"aliases": ["packages.local", "registry.local"],"ip": "'$ip'"}' cloud-init-global.json  > cloud-init-global_update.json

    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
        --request PUT \
        --data @cloud-init-global_update.json \
        https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

    csi upgrade metadata --1-0-to-1-2 

    record_state ${state_name} $(hostname)
    echo
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    temp_file=$(mktemp)
    artdir=${CSM_ARTI_DIR}/images
    radosgw-admin bucket link --uid=STS --bucket=ncn-images
    set -o pipefail
    csi handoff ncn-images \
          --kubeconfig /etc/kubernetes/admin.conf \
          --k8s-kernel-path $artdir/kubernetes/*.kernel \
          --k8s-initrd-path $artdir/kubernetes/initrd*.xz \
          --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
          --ceph-kernel-path $artdir/storage-ceph/*.kernel \
          --ceph-initrd-path $artdir/storage-ceph/initrd*.xz \
          --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs | tee $temp_file
    set +o pipefail

    KUBERNETES_VERSION=`cat $temp_file | grep "export KUBERNETES_VERSION=" | awk -F'=' '{print $2}'`
    CEPH_VERSION=`cat $temp_file | grep "export CEPH_VERSION=" | awk -F'=' '{print $2}'`
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="EXPORT_GLOBAL_ENV"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    rm -rf /etc/cray/upgrade/csm/myenv
    echo "export CEPH_VERSION=${CEPH_VERSION}" >> /etc/cray/upgrade/csm/myenv
    echo "export KUBERNETES_VERSION=${KUBERNETES_VERSION}" >> /etc/cray/upgrade/csm/myenv
    echo "export CSM_RELEASE=${CSM_RELEASE}" >> /etc/cray/upgrade/csm/myenv
    echo "export CSM_ARTI_DIR=${CSM_ARTI_DIR}" >> /etc/cray/upgrade/csm/myenv
    echo "export DOC_RPM_NEXUS_URL=https://packages.local/repository/csm-sle-15sp2/docs-csm-latest.noarch.rpm" >> /etc/cray/upgrade/csm/myenv
    echo "export CSM_CONFIG_VERSION=${CSM_CONFIG_VERSION}" >> /etc/cray/upgrade/csm/myenv
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    rpm --force -Uvh $(find $CSM_ARTI_DIR/rpm/cray/csm/ -name \*csm-testing\*.rpm | sort -V | tail -1)
    /opt/cray/tests/install/ncn/scripts/validate-bootraid-artifacts.sh

    # get all installed csm version into a file
    kubectl get cm -n services cray-product-catalog -o json | jq  -r '.data.csm' | yq r -  -d '*' -j | jq -r 'keys[]' > /tmp/csm_versions
    # sort -V: version sort
    highest_version=$(sort -V /tmp/csm_versions | tail -1)
    minimum_version="1.0.1"
    # compare sorted versions with unsorted so we know if our highest is greater than minimum
    if [[ $(printf "$minimum_version\n$highest_version") != $(printf "$minimum_version\n$highest_version" | sort -V) ]]; then
      echo "Required CSM patch $minimum_version or above has not been applied to this system"
      exit 1
    fi

    GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PRECACHE_NEXUS_IMAGES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."

    images=$(kubectl get configmap -n nexus cray-precache-images -o json | jq -r '.data.images_to_cache' | grep "sonatype\|proxy\|busybox")
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    output=$(pdsh -b -S -w $(grep -oP 'ncn-w\w\d+' /etc/hosts | sort -u | tr -t '\n' ',') 'for image in '$images'; do crictl pull $image; done' 2>&1)
    echo "$output"

    if [[ "$output" == *"failed"* ]]; then
      echo ""
      echo "Verify the images which failed in the output above are available in nexus."
      exit 1
    fi

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

# Take cps deployment snapshot (if cps installed)
set +e
trap - ERR
kubectl get pod -n services | grep -q cray-cps
if [ "$?" -eq 0 ]; then
  cps_deployment_snapshot=$(cray cps deployment list --format json | jq -r '.[] | .node' || true)
  echo $cps_deployment_snapshot > /etc/cray/upgrade/csm/${CSM_RELEASE}/cp.deployment.snapshot
fi
trap 'err_report' ERR
set -e

state_name="ADD_MTL_ROUTES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."

    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    NCNS=$(grep -oP 'ncn-w\w\d+|ncn-s\w\d+' /etc/hosts | sort -u)
    Ncount=$(echo $NCNS | wc -w)
    HOSTS=$(echo $NCNS | tr -t ' ' ',')
    GATEWAY=$(cray sls networks describe NMN --format json | \
        jq -r '.ExtraProperties.Subnets[]|select(.FullName=="NMN Management Network Infrastructure")|.Gateway')
    SUBNET=$(cray sls networks describe MTL --format json | \
        jq -r '.ExtraProperties.Subnets[]|select(.FullName=="MTL Management Network Infrastructure")|.CIDR')
    pdsh -w $HOSTS ip route add $SUBNET via $GATEWAY dev vlan002
    Rcount=$(pdsh -w $HOSTS ip route show | grep $SUBNET | wc -l)
    pdsh -w $HOSTS ip route show | grep $SUBNET


    if [[ $Rcount -ne $Ncount ]]; then
        echo ""
        echo "Could not set routes on all worker and storage nodes."
        exit 1
    fi

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi


state_name="SETUP_CFS_CONFIGURATIONS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    tmp_folder="/tmp/csm-config-management"
    # get current csm-config version
    csm_config_version=$(helm list -n services | grep csm-config | awk '{print $10}')
    # get VCS details
    rm -rf ${tmp_folder}
    vcs_password=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    git clone https://crayvcs:${vcs_password}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git ${tmp_folder}
    pushd ${tmp_folder}
    head_commit=$(git show-ref origin/cray/csm/${csm_config_version} --head | grep ${csm_config_version} | awk '{print $1}')
    popd +0
    cat <<EOF > /root/rebuild-ncn.json
{
  "layers": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "commit":"${head_commit}",
      "name": "cray/csm/${csm_config_version}",
      "playbook": "rebuild-ncn.yml"
    }
  ]
}
EOF
    # make sure we have cfs created
    cray cfs sessions delete rebuild-ncn  2>/dev/null || true
    cray cfs configurations update rebuild-ncn --file /root/rebuild-ncn.json --format json
    exit 1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

ok_report