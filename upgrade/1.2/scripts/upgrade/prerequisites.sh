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
. ${locOfScript}/../common/ncn-common.sh $(hostname)
trap 'err_report' ERR INT TERM HUP EXIT
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

state_name="UPDATE_SSH_KEYS"
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
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CHECK_CLOUD_INIT_PREREQ"
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
            ssh $host cloud-init init 2>&1 >/dev/null
            counter=$((counter+1))
            sleep 10
            if [[ $counter > 5 ]]
            then
                echo "Cloud init data is missing and cannot be recreated. Existing upgrade.."
            fi
        done
    done

    set -e
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_DOC_RPM"
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
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_CUSTOMIZATIONS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    
    # update podman config
    sed -i 's/.*mount_program =.*/mount_program = "\/usr\/bin\/fuse-overlayfs"/' /etc/containers/storage.conf

    SITE_INIT_DIR=/etc/cray/upgrade/csm/${CSM_RELEASE}/site-init
    mkdir -p ${SITE_INIT_DIR}
    pushd ${SITE_INIT_DIR}
    ${CSM_ARTI_DIR}/hack/load-container-image.sh artifactory.algol60.net/csm-docker/stable/docker.io/zeromq/zeromq:v4.0.5
    cp -r ${CSM_ARTI_DIR}/shasta-cfg/* ${SITE_INIT_DIR}
    mkdir -p certs
    set -o pipefail
    kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
    kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
    kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
    set +o pipefail
    . ${locOfScript}/util/update-customizations.sh -i ${SITE_INIT_DIR}/customizations.yaml
    yq delete -i ./customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
    yq delete -i ./customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
    yq delete -i ./customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
    ./utils/secrets-reencrypt.sh customizations.yaml ./certs/sealed_secrets.key ./certs/sealed_secrets.crt
    ./utils/secrets-seed-customizations.sh customizations.yaml || true
    kubectl delete secret -n loftsman site-init
    kubectl create secret -n loftsman generic site-init --from-file=./customizations.yaml
    popd
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    ${CSM_ARTI_DIR}/lib/setup-nexus.sh

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="DISABLE_SERVICE_REPOS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    NCNS=$(${CSM_ARTI_DIR}/lib/list-ncns.sh | paste -sd,)
    pdsh -w "$NCNS" 'zypper ms -d Basesystem_Module_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d Public_Cloud_Module_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d SUSE_Linux_Enterprise_Server_15_SP2_x86_64'
    pdsh -w "$NCNS" 'zypper ms -d Server_Applications_Module_15_SP2_x86_64'
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="REMOVE_DUPLICATE_BMC_DNS_RECORDS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
        set +e
        # Find a pod that works.
        # List names of all Running vault pods, grep for just the cray-vault-# pods, and try them in
        # turn until one of them has the IPMI credentials.
        USERNAME=""
        IPMI_PASSWORD=""
        VAULT_TOKEN=$(kubectl get secrets cray-vault-unseal-keys -n vault -o jsonpath={.data.vault-root} | base64 -d)
        for VAULT_POD in $(kubectl get pods -n vault --field-selector status.phase=Running --no-headers \
                            -o custom-columns=:.metadata.name | grep -E "^cray-vault-(0|[1-9][0-9]*)$") ; do
            USERNAME=$(kubectl exec -it -n vault -c vault ${VAULT_POD} -- sh -c \
                "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; \
                vault kv get -format=json secret/hms-creds/$TARGET_MGMT_XNAME" |
                jq -r '.data.Username')
            # If we are not able to get the username, no need to try and get the password.
            [[ -n ${USERNAME} ]] || continue
            export IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault ${VAULT_POD} -- sh -c \
                "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; \
                vault kv get -format=json secret/hms-creds/$TARGET_MGMT_XNAME" |
                jq -r '.data.Password')
            break
        done
        # Make sure we found a pod that worked
        [[ -n ${USERNAME} ]]

        # Install our pit-init RPM and pull in any dependencies it has.
        zypper --no-gpg-checks --plus-repo=https://packages.local/repository/csm-sle-15sp2 in -y pit-init
        /root/bin/bios-baseline.sh -y

        # Remove our pit-init RPM and any dependencies it had.
        zypper rm -u -y pit-init

        # Check for and remove any duplicate DNS entries for BMCs
        bmc_duplicate_error=0
        for ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do
            if [[ "$(dig +short ${ncn}-mgmt | wc -l)" > "1" ]]; then
                bmc_duplicate_error=1
            fi
        done
        if [ $bmc_duplicate_error = 1 ]; then
            export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                              -d client_id=admin-client \
                              -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                              https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
            /usr/share/doc/csm/scripts/CASMINST-1309.sh
        fi
        set -e
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_BSS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    helm -n services upgrade cray-hms-bss ${CSM_ARTI_DIR}/helm/cray-hms-bss-*.tgz
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_KEA"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    helm -n services upgrade cray-dhcp-kea ${CSM_ARTI_DIR}/helm/cray-dhcp-kea-*.tgz
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_UNBOUND"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    manifest_folder='/tmp'
    dns_forwarder=$(kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d|yq r - spec.network.netstaticips.system_to_site_lookups)
    system_name=$(kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d|yq r - spec.network.dns.external)
    unbound_version=$(ls ${CSM_ARTI_DIR}/helm |grep cray-dns-unbound|sed -e 's/\.[^./]*$//'|cut -d '-' -f4)


    if [ -z "$dns_forwarder" ] || [ -z "$system_name" ] || [ -z "$unbound_version" ]; then
      echo "ERROR: null value found.  See list of variables"
      echo "dns_forwarder is $dns_forwarder."
      echo "system_name is $system_name."
      echo "unbound_version is $unbound_version."
      exit 1
    fi

    cat > $manifest_folder/unbound.yaml <<EOF
apiVersion: manifests/v1beta1
metadata:
  name: unbound
spec:
  charts:
  - name: cray-dns-unbound
    namespace: services
    source: csm
    values:
      domain_name: $system_name
      forwardZones:
      - forwardIps: [$dns_forwarder]
        name: .
      global:
        appVersion: $unbound_version
      localZones:
      - localType: static
        name: local
    version: $unbound_version
EOF

    echo "$manifest_folder/unbound.yaml"
    cat $manifest_folder/unbound.yaml

    loftsman ship --charts-path ${CSM_ARTI_DIR}/helm/ --manifest-path $manifest_folder/unbound.yaml

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    temp_file=$(mktemp)
    artdir=${CSM_ARTI_DIR}/images

    export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
    DEBUG=1 ${CSM_ARTI_DIR}/ncn-image-modification.sh \
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
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_CLOUD_INIT_RECORDS"
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

    csi upgrade metadata --1-0-to-1-2 \
        --k8s-version ${KUBERNETES_VERSION} \
        --storage-version ${CEPH_VERSION}

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
    echo
else
    echo "====> ${state_name} has been completed"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
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

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPGRADE_PRECACHE_CHART"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
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
    # Now edit the configmap with the three images that 1.x nexus
    # needs so it can move around on an upgraded NCN (before we deploy
    # the new nexus chart)
    #
    kubectl get configmap -n nexus cray-precache-images -o yaml | sed '/kind: ConfigMap/i\    docker.io/sonatype/nexus3:3.25.0\n    dtr.dev.cray.com/baseos/busybox:1\n    dtr.dev.cray.com/cray/istio/proxyv2:1.7.8-cray2-distroless' | kubectl apply -f -

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POD_ANTI_AFFINITY"
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
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

${locOfScript}/../cps/snapshot-cps-deployment.sh

state_name="ADD_MTL_ROUTES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {

    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    NCNS=$(grep -oP 'ncn-w\w\d+|ncn-s\w\d+' /etc/hosts | sort -u)
    Ncount=$(echo $NCNS | wc -w)
    HOSTS=$(echo $NCNS | tr -t ' ' ',')
    GATEWAY=$(cray sls networks describe NMN --format json | \
        jq -r '.ExtraProperties.Subnets[]|select(.FullName=="NMN Management Network Infrastructure")|.Gateway')
    SUBNET=$(cray sls networks describe MTL --format json | \
        jq -r '.ExtraProperties.Subnets[]|select(.FullName=="MTL Management Network Infrastructure")|.CIDR')
    DEVICE="vlan002"
    set +e
    ip addr show | grep $DEVICE
    if [[ $? -ne 0 ]]; then
        DEVICE="bond0.nmn0"
    fi
    set -e
    pdsh -w $HOSTS ip route add $SUBNET via $GATEWAY dev $DEVICE
    Rcount=$(pdsh -w $HOSTS ip route show | grep $SUBNET | wc -l)
    pdsh -w $HOSTS ip route show | grep $SUBNET


    if [[ $Rcount -ne $Ncount ]]; then
        echo ""
        echo "Could not set routes on all worker and storage nodes."
        exit 1
    fi

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CREATE_CEPH_RO_KEY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    ceph-authtool -C /etc/ceph/ceph.client.ro.keyring -n client.ro --cap mon 'allow r' --cap mds 'allow r' --cap osd 'allow r' --cap mgr 'allow r' --gen-key
    ceph auth import -i /etc/ceph/ceph.client.ro.keyring
    for node in $(ceph orch host ls --format=json|jq -r '.[].hostname'); do scp /etc/ceph/ceph.client.ro.keyring $node:/etc/ceph/ceph.client.ro.keyring; done
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_BSS_DATA"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    
    cray bss bootparameters list --format=json > bss-backup-$(date +%Y-%m-%d).json

    backupBucket="config-data"
    set +e
    cray artifacts list config-data
    if [[ $? -ne 0 ]]; then
        backupBucket="vbis"
    fi
    set -e

    cray artifacts create ${backupBucket} bss-backup-$(date +%Y-%m-%d).json bss-backup-$(date +%Y-%m-%d).json
    
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_VCS_DATA"
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
    if kubectl -n services exec -it ${POD} -- /bin/sh -c 'ls /data' >/dev/null 2>&1; then
      kubectl -n services exec ${POD} -- tar -cvf vcs.tar /data/
    else
      kubectl -n services exec ${POD} -- tar -cvf vcs.tar /var/lib/gitea/
    fi

    kubectl -n services cp ${POD}:vcs.tar ./vcs.tar

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
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="TDS_LOWER_CPU_REQUEST"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    
    numOfActiveWokers=$(kubectl get nodes | grep "ncn-w" | grep "Ready" | wc -l)
    minimal_count=4
    if [[ $numOfActiveWokers -lt $minimal_count ]]; then
        /usr/share/doc/csm/upgrade/1.2/scripts/k8s/tds_lower_cpu_requests.sh
    else
        echo "==> TDS: false"
    fi
    
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="RECONFIGURE_HAPROXY_MASTERS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)
    for master in $masters
    do
      echo "Reconfiguring haproxy on $master:"
      scp /usr/share/doc/csm/upgrade/1.2/scripts/k8s/reconfigure_haproxy.sh $master:/tmp/reconfigure_haproxy.sh
      pdsh -b -S -w $master '/tmp/reconfigure_haproxy.sh'
    done
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="SUSPEND_NCN_CONFIGURATION"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    
    export CRAY_FORMAT=json
    for xname in $(cray hsm state components list --role Management --type node | jq -r .Components[].ID)
    do
        cray cfs components update --enabled false --desired-config "" $xname
    done
    
    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CHECK_BMC_NCN_LOCKS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    {
    # install the hpe-csm-scripts rpm early to get lock_management_nodes.py
    rpm --force -Uvh $(find $CSM_ARTI_DIR/rpm/cray/csm/ -name \*hpe-csm-scripts\*.rpm | sort -V | tail -1)

    # mark the NCN BMCs with the Management role in HSM
    cray hsm state components bulkRole update --role Management --component-ids \
                            $(cray hsm state components list --role management --type node --format json | \
                                jq -r .Components[].ID | sed 's/n[0-9]*//' | tr '\n' ',' | sed 's/.$//')

    # ensure that they are all locked
    python3 /opt/cray/csm/scripts/admin_access/lock_management_nodes.py

    } >> ${LOG_FILE} 2>&1
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

# restore previous ssh config if there was one, remove ours
rm -f /root/.ssh/config
test -f /root/.ssh/config.bak && mv /root/.ssh/config.bak /root/.ssh/config

ok_report

