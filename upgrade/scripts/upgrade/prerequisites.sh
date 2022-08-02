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
locOfScript=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${locOfScript}/../common/upgrade-state.sh
#shellcheck disable=SC2046
. ${locOfScript}/../common/ncn-common.sh $(hostname)
trap 'err_report' ERR INT TERM HUP EXIT
# array for paths to unmount after chrooting images
#shellcheck disable=SC2034
declare -a UNMOUNTS=()

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --csm-version)
    CSM_RELEASE="$2"
    CSM_REL_NAME="csm-${CSM_RELEASE}"
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

if [[ -z ${SW_ADMIN_PASSWORD} ]]; then
    echo "SW_ADMIN_PASSWORD environment variable has not been set"
    exit 1
fi

if [[ -z ${CSM_ARTI_DIR} ]]; then
    echo "CSM_ARTI_DIR environment variable has not been set"
    echo "make sure you have run: prepare-assets.sh"
    exit 1
fi

state_name="CHECK_WEAVE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
TOKEN=$(curl -s -S -d grant_type=client_credentials \
                   -d client_id=admin-client \
                   -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
                   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN

if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    SLEEVE_MODE="yes"
    weave --local status connections | grep -q sleeve || SLEEVE_MODE="no"
    if [ "${SLEEVE_MODE}" == "yes" ]; then
        echo "Detected that weave is in sleeve mode with at least one peer.   Please consult FN6636 before proceeding with the upgrade."
        exit 1
    fi

    # get bss global cloud-init data
    curl -k -H "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global|jq .[] > cloud-init-global.json

    CURRENT_MTU=$(jq '."cloud-init"."meta-data"."kubernetes-weave-mtu"' cloud-init-global.json)
    echo "Current kubernetes-weave-mtu is $CURRENT_MTU"

    # make sure kubernetes-weave-mtu is set to 1376
    jq '."cloud-init"."meta-data"."kubernetes-weave-mtu" = "1376"' cloud-init-global.json > cloud-init-global-update.json

    echo "Setting kubernetes-weave-mtu to 1376"
    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
        --request PUT \
        --data @cloud-init-global-update.json \
        https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} "$(hostname)"
    echo
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_SSH_KEYS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {

    test -f /root/.ssh/config && mv /root/.ssh/config /root/.ssh/config.bak
    cat <<EOF> /root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF

    grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'truncate --size=0 ~/.ssh/known_hosts'

    grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts'

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="REPAIR_AND_VERIFY_CHRONY_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
TOKEN=$(curl -s -S -d grant_type=client_credentials \
                   -d client_id=admin-client \
                   -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
                   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ "$(hostname)" == "ncn-m002" ]]; then
        # we already did this from ncn-m001
        echo "====> ${state_name} has been completed"
    else
      # shellcheck disable=SC2013
      for target_ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do

        # ensure host is accessible, skip it if not
        if ! ssh "$target_ncn" hostname > /dev/null; then
            continue
        fi

        # ensure the directory exists
        ssh "$target_ncn" mkdir -p /srv/cray/scripts/common/

        # copy the NTP script and template to the target ncn
        rsync -aq "${CSM_ARTI_DIR}"/chrony "$target_ncn":/srv/cray/scripts/common/

        # shellcheck disable=SC2029 # it's ok that $TOKEN expands on the client side
        # run the script
        if ! ssh "$target_ncn" "TOKEN=$TOKEN /srv/cray/scripts/common/chrony/csm_ntp.py"; then
            echo "${target_ncn} csm_ntp failed"
            exit 1
        fi

        ssh "$target_ncn" chronyc makestep
        loop_idx=0
        in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
        # wait up to 90s for the node to be in sync
        while [[ $loop_idx -lt 18 && "$in_sync" == "no" ]]; do
            sleep 5
            in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
            loop_idx=$(( loop_idx+1 ))
        done

        if [[ "$in_sync" == "no" ]]; then
            echo "The clock for ${target_ncn} is not in sync.  Wait a bit more or try again."
            exit 1
        fi
      done
      record_state "${state_name}" "$(hostname)"
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi

state_name="CHECK_CLOUD_INIT_PREREQ"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    echo "Ensuring cloud-init is healthy"
    set +e
    # K8s nodes
    for host in $(kubectl get nodes -o json |jq -r '.items[].metadata.name')
    do
        echo "Node: $host"
        counter=0
        ssh_keygen_keyscan $host
        until ssh $host test -f /run/cloud-init/instance-data.json
        do
            #shellcheck disable=SC2069
            ssh $host cloud-init init 2>&1 >/dev/null
            counter=$((counter+1))
            sleep 10
            if [[ $counter -gt 5 ]]
            then
            echo "Cloud init data is missing and cannot be recreated. Existing upgrade.."
            fi
        done
    done


    ## Ceph nodes
    for host in $(ceph node ls|jq -r '.osd|keys[]')
    do
        echo "Node: $host"
        counter=0
        ssh_keygen_keyscan $host
        until ssh $host test -f /run/cloud-init/instance-data.json
        do
            #shellcheck disable=SC2069
            ssh $host cloud-init init 2>&1 >/dev/null
            counter=$((counter+1))
            sleep 10
            #shellcheck disable=SC2071
            if [[ $counter > 5 ]]
            then
                echo "Cloud init data is missing and cannot be recreated. Existing upgrade.."
            fi
        done
    done

    set -e
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_DOC_RPM"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ ! -f /root/docs-csm-latest.noarch.rpm ]]; then
        echo "ERROR: docs-csm-latest.noarch.rpm is missing under: /root -- halting..."
        exit 1
    fi
    cp /root/docs-csm-latest.noarch.rpm ${CSM_ARTI_DIR}/rpm/cray/csm/sle-15sp2/
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_CUSTOMIZATIONS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    # get existing customization.yaml file
    SITE_INIT_DIR=/etc/cray/upgrade/csm/${CSM_REL_NAME}/site-init
    mkdir -p "${SITE_INIT_DIR}"
    pushd "${SITE_INIT_DIR}"
    DATETIME=$(date +%Y-%m-%d_%H-%M-%S)
    CUSTOMIZATIONS_YAML=$(mktemp -p "${SITE_INIT_DIR}" "customizations-${DATETIME}-XXX.yaml")
    set -o pipefail
    kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > "${CUSTOMIZATIONS_YAML}"
    set +o pipefail

    # NOTE:  There are currently no sealed secrets being added so we are skipping the sealed secrets steps

    cp "${CUSTOMIZATIONS_YAML}" "${CUSTOMIZATIONS_YAML}.bak"
    . ${locOfScript}/util/update-customizations.sh -i ${CUSTOMIZATIONS_YAML}

    # rename customizations file so k8s secret name stays the same
    cp "${CUSTOMIZATIONS_YAML}" customizations.yaml

    # push updated customizations.yaml to k8s
    kubectl delete secret -n loftsman site-init
    kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    popd
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="SETUP_NEXUS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    ${CSM_ARTI_DIR}/lib/setup-nexus.sh

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_NLS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
        "${locOfScript}"/util/upgrade-cray-nls.sh
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    temp_file=$(mktemp)
    artdir=${CSM_ARTI_DIR}/images
    #shellcheck disable=SC2155
    export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
    set -o pipefail
    NCN_IMAGE_MOD_SCRIPT="$(rpm -ql docs-csm | grep ncn-image-modification.sh)"
    set +o pipefail
    DEBUG=1 $NCN_IMAGE_MOD_SCRIPT \
        -d /root/.ssh \
        -k $artdir/kubernetes/kubernetes*.squashfs \
        -s $artdir/storage-ceph/storage-ceph*.squashfs \
        -p

    radosgw-admin bucket link --uid=STS --bucket=ncn-images
    set -o pipefail
    csi handoff ncn-images \
          --kubeconfig /etc/kubernetes/admin.conf \
          --k8s-kernel-path $artdir/kubernetes/*.kernel \
          --k8s-initrd-path $artdir/kubernetes/initrd*.xz \
          --k8s-squashfs-path $artdir/kubernetes/secure-kubernetes*.squashfs \
          --ceph-kernel-path $artdir/storage-ceph/*.kernel \
          --ceph-initrd-path $artdir/storage-ceph/initrd*.xz \
          --ceph-squashfs-path $artdir/storage-ceph/secure-storage-ceph*.squashfs | tee $temp_file
    set +o pipefail

    KUBERNETES_VERSION=`cat $temp_file | grep "export KUBERNETES_VERSION=" | awk -F'=' '{print $2}'`
    CEPH_VERSION=`cat $temp_file | grep "export CEPH_VERSION=" | awk -F'=' '{print $2}'`
    echo "export CEPH_VERSION=${CEPH_VERSION}" >> /etc/cray/upgrade/csm/myenv
    echo "export KUBERNETES_VERSION=${KUBERNETES_VERSION}" >> /etc/cray/upgrade/csm/myenv

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_CLOUD_INIT_RECORDS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    # get bss cloud-init data with host_records
    curl -k -H "Authorization: Bearer $TOKEN" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global|jq .[] > cloud-init-global.json

    # get ip of api-gw in nmn
    ip=$(dig api-gw-service-nmn.local +short)

    # get entry number to add record to
    entry_number=$(jq '."cloud-init"."meta-data".host_records|length' cloud-init-global.json )

    # check for record already exists and create the script to be idempotent
    for ((i=0;i<$entry_number; i++)); do
        record=$(jq '."cloud-init"."meta-data".host_records['$i']' cloud-init-global.json)
        #shellcheck disable=SC2076
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

    csi upgrade metadata --1-2-to-1-3 \
        --k8s-version ${KUBERNETES_VERSION} \
        --storage-version ${CEPH_VERSION}

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
    echo
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE NCN KERNEL PARAMETERS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    # shellcheck disable=SC2155,SC2046
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    export TOKEN

    # As boot parameters are added or removed, update these arrays.
    # NOTE: bootparameters_to_delete should contain keys only, nothing should have "=<value>" appended to it.
    bootparameters_to_set=( "psi=1" )
    bootparameters_to_delete=()

    for bootparameter in "${bootparameters_to_delete[@]}"; do
        csi handoff bss-update-param --delete ${bootparameter}
    done

    for bootparameter in "${bootparameters_to_set[@]}"; do
        csi handoff bss-update-param --set ${bootparameter}
    done

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
    echo
else
    echo "====> ${state_name} has been completed"
fi

state_name="PREFLIGHT_CHECK"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    #shellcheck disable=SC2046
    rpm --force -Uvh $(find $CSM_ARTI_DIR/rpm/cray/csm/ -name \*csm-testing\*.rpm | sort -V | tail -1)
    /opt/cray/tests/install/ncn/scripts/validate-bootraid-artifacts.sh

    # get all installed csm version into a file
    kubectl get cm -n services cray-product-catalog -o json | jq  -r '.data.csm' | yq r -  -d '*' -j | jq -r 'keys[]' > /tmp/csm_versions
    # sort -V: version sort
    highest_version=$(sort -V /tmp/csm_versions | tail -1)
    minimum_version="1.2.0"
    # compare sorted versions with unsorted so we know if our highest is greater than minimum
    if [[ $(printf "$minimum_version\n$highest_version") != $(printf "$minimum_version\n$highest_version" | sort -V) ]]; then
      echo "Required CSM patch $minimum_version or above has not been applied to this system"
      exit 1
    fi

    GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_PRECACHE_CHART"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    tmp_current_configmap=/tmp/precache-current-configmap.yaml
    kubectl get configmap -n nexus cray-precache-images -o yaml > $tmp_current_configmap
    helm uninstall -n nexus cray-precache-images
    tmp_manifest=/tmp/precache-manifest.yaml

cat > $tmp_manifest <<EOF
apiVersion: manifests/v1beta1
metadata:
  name: cray-precache-images-manifest
spec:
  charts:
  -
EOF

    yq r "${CSM_ARTI_DIR}/manifests/platform.yaml" 'spec.charts.(name==cray-precache-images)' | sed 's/^/    /' >> $tmp_manifest
    loftsman ship --charts-path "${CSM_ARTI_DIR}/helm" --manifest-path $tmp_manifest

    #
    # Now edit the configmap with the images necessary to move the former nexus
    # pod around on an upgraded NCN (before we deploy the new nexus chart)
    #
    current_nexus_mobility_images=$(yq r $tmp_current_configmap 'data.images_to_cache' | grep -e 'sonatype\|busy\|proxyv2\|envoy' | sort | uniq)
    current_nexus_mobility_images=$(echo ${current_nexus_mobility_images} | sed 's/ /\n/g; s/^/\n/')

    echo "Adding the following pre-upgrade images to new pre-cache configmap:"
    echo "$current_nexus_mobility_images"
    echo ""

    kubectl get configmap -n nexus cray-precache-images -o json | jq --arg value "$current_nexus_mobility_images" '.data.images_to_cache |= . + $value' | kubectl replace --force -f -

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POD_ANTI_AFFINITY"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    kubectl patch deployment -n spire spire-jwks -p '{
        "spec": {
        "strategy": {"rollingUpdate": {"maxSurge": 0}},
        "template": {
            "spec": {
                "affinity": {
                    "podAntiAffinity": {
                        "requiredDuringSchedulingIgnoredDuringExecution": [
                            {
                            "labelSelector": {
                                "matchLabels": {
                                    "app.kubernetes.io/name":"spire-jwks"
                                }
                            },
                            "topologyKey": "kubernetes.io/hostname"
                            }
                        ]
                    }
                }
            }
        }
    }}'

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CREATE_CEPH_RO_KEY"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    ceph-authtool -C /etc/ceph/ceph.client.ro.keyring -n client.ro --cap mon 'allow r' --cap mds 'allow r' --cap osd 'allow r' --cap mgr 'allow r' --gen-key
    ceph auth import -i /etc/ceph/ceph.client.ro.keyring
    for node in $(ceph orch host ls --format=json|jq -r '.[].hostname'); do scp /etc/ceph/ceph.client.ro.keyring $node:/etc/ceph/ceph.client.ro.keyring; done
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_BSS_DATA"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    #shellcheck disable=SC2046
    cray bss bootparameters list --format json > bss-backup-$(date +%Y-%m-%d).json

    backupBucket="config-data"
    set +e
    cray artifacts list config-data
    if [[ $? -ne 0 ]]; then
        backupBucket="vbis"
    fi
    set -e

    #shellcheck disable=SC2046
    cray artifacts create ${backupBucket} bss-backup-$(date +%Y-%m-%d).json bss-backup-$(date +%Y-%m-%d).json

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_VCS_DATA"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    pgLeaderPod=$(kubectl exec gitea-vcs-postgres-0 -n services -c postgres -it -- patronictl list | grep Leader | awk -F'|' '{print $2}')
    kubectl exec -it ${pgLeaderPod} -n services -c postgres -- pg_dumpall -c -U postgres > gitea-vcs-postgres.sql

    SECRETS="postgres service-account standby"
    echo "---" > gitea-vcs-postgres.manifest
    for secret in $SECRETS; do
        kubectl get secret "${secret}.gitea-vcs-postgres.credentials" -n services -o yaml >> gitea-vcs-postgres.manifest
        echo "---" >> gitea-vcs-postgres.manifest
    done

    POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
    #
    # Gitea change in 1.2 from /data to /var/lib/gitea, see which version we're
    # backing up (in support of 1.2 -> 1.2 upgrades)
    #
    if kubectl -n services exec -it ${POD} -c vcs -- /bin/sh -c 'ls /data' >/dev/null 2>&1; then
      kubectl -n services exec ${POD} -c vcs -- tar -cvf vcs.tar /data/
    else
      kubectl -n services exec ${POD} -c vcs -- tar -cvf vcs.tar /var/lib/gitea/
    fi

    kubectl -n services -c vcs cp ${POD}:vcs.tar ./vcs.tar

    backupBucket="config-data"
    set +e
    cray artifacts list config-data
    if [[ $? -ne 0 ]]; then
        backupBucket="vbis"
    fi
    set -e

    cray artifacts create ${backupBucket} gitea-vcs-postgres.sql gitea-vcs-postgres.sql
    cray artifacts create ${backupBucket} gitea-vcs-postgres.manifest gitea-vcs-postgres.manifest
    cray artifacts create ${backupBucket} vcs.tar vcs.tar

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="TDS_LOWER_CPU_REQUEST"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    numOfActiveWokers=$(kubectl get nodes | grep "ncn-w" | grep "Ready" | wc -l)
    minimal_count=4
    if [[ $numOfActiveWokers -lt $minimal_count ]]; then
        /usr/share/doc/csm/upgrade/scripts/k8s/tds_lower_cpu_requests.sh
    else
        echo "==> TDS: false"
    fi

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CHECK_BMC_NCN_LOCKS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    # install the hpe-csm-scripts rpm early to get lock_management_nodes.py
    #shellcheck disable=SC2046
    rpm --force -Uvh $(find $CSM_ARTI_DIR/rpm/cray/csm/ -name \*hpe-csm-scripts\*.rpm | sort -V | tail -1)

    # mark the NCN BMCs with the Management role in HSM
    #shellcheck disable=SC2046
    cray hsm state components bulkRole update --role Management --component-ids \
                            $(cray hsm state components list --role management --type node --format json | \
                                jq -r .Components[].ID | sed 's/n[0-9]*//' | tr '\n' ',' | sed 's/.$//')

    # ensure that they are all locked
    python3 /opt/cray/csm/scripts/admin_access/lock_management_nodes.py

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

# restore previous ssh config if there was one, remove ours
rm -f /root/.ssh/config
test -f /root/.ssh/config.bak && mv /root/.ssh/config.bak /root/.ssh/config

ok_report

