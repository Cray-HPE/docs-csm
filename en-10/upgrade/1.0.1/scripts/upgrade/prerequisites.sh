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
echo " ****** WARNING ******"
echo " ****** /mnt/pitdata WILL BE UNMOUNTED ******"
echo " ****** YOU NEED TO MOUNT IT AGAIN IF YOU WANT TO USE /mnt/pitdata ******"
read -p "Read and act on above steps. Press Enter key to continue ..."

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
    rm -rf /root/.ssh/known_hosts || true
    touch /root/.ssh/known_hosts
    for i in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ' ')
    do
        ssh_keygen_keyscan $i
    done

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

# Apply WAR for CASMINST-2689, just in case
state_name="APPLY_CASMINST-2689"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
  echo "====> ${state_name} ..."
  echo "Opening and refreshing fallback artifacts on the NCNs.."
    
  "${BASEDIR}"/CASMINST-2689.sh

  # only fix ntp if we are coming from 0.9
  if [[ "$CSM1_EXISTS" == "false" ]]; then
  # Check if ncn-m001 is using itself for an upstream server
  if [[ "$(awk '/^server/ {print $2}' /etc/chrony.d/cray.conf)" == ncn-m001 ]] ||
      [[ "$(chronyc tracking | awk '/Reference ID/ {print $5}' | tr -d '()')" == ncn-m001 ]]; then
        # Get the upstream NTP server from cloud-init metadata, trying a few different sources before failing
        upstream_ntp_server=$(craysys metadata get upstream_ntp_server)
        # check to make sure we are not re-creating the bug by setting m001 to use itself as an upstream
        if [[ "$upstream_ntp_server" == "ncn-m001" ]]; then
          # if a pool is set, and we did not find an upstream server, just use the pool
          if grep "^\(pool\).*" /etc/chrony.d/cray.conf >/dev/null ; then
            sed -i "/^\(server ncn-m001\).*/d" /etc/chrony.d/cray.conf
          # otherwise error
          else
            echo "Upstream server cannot be $upstream_ntp_server"
            exit 1
          fi
        else
          # Swap in the "real" NTP server
          sed -i "s/^\(server ncn-m001\).*/server $upstream_ntp_server iburst trust/" /etc/chrony.d/cray.conf
          # add a new config that will step the clock if it is less that 1s of drift, otherwise, it will slew it
          # this applies on startups of the system from a reboot only
          sed -i "/^\(logchange 1.0\)\$/a initstepslew 1 $upstream_ntp_server" /etc/chrony.d/cray.conf
          # Apply the change to use the new upstream server
        fi
        systemctl restart chronyd
  fi
  fi
  record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_CSI"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    rpm --force -Uvh $(find ${CSM_ARTI_DIR}/rpm/cray/csm/ -name "cray-site-init*.rpm") 

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_WAR_DOC"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    rpm --force -Uvh $(find ${CSM_ARTI_DIR}/rpm/cray/csm/ -name "csm-install-workarounds-*.rpm") 
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_DOC_RPM"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    if [[ ! -f /root/docs-csm-latest.noarch.rpm ]]; then
        echo "ERROR: docs-csm-latest.noarch.rpm is missing under: /root -- halting..."
        exit 1
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

state_name="APPLY_POD_PRIORITY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    . ${BASEDIR}/add_pod_priority.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UPDATE_BSS_CLOUD_INIT_RECORDS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
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
        fi
    done

    # create the updated json
    jq '."cloud-init"."meta-data".host_records['$entry_number']|= . + {"aliases": ["packages.local", "registry.local"],"ip": "'$ip'"}' cloud-init-global.json  > cloud-init-global_update.json

    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
        --request PUT \
        --data @cloud-init-global_update.json \
        https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

    # perform additional cloud-init updates
    for upgrade_ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ' '); do
        . ${BASEDIR}/ncn-upgrade-cloud-init.sh $upgrade_ncn
    done

    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has been completed"
fi

state_name="UPDATE_CRAY_DHCP_KEA_TRAFFIC_POLICY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "${state_name} ..."
    kubectl -n services patch service cray-dhcp-kea-tcp-hmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-tcp-nmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-udp-nmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    kubectl -n services patch service cray-dhcp-kea-udp-hmn --type merge -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    record_state ${state_name} $(hostname)
    echo
else
    echo "${state_name} has been completed"
fi

# only the modify the image if we are coming from 0.9.x
if [[ "$CSM1_EXISTS" == "false" ]]; then

state_name="MODIFYING_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    artdir=${CSM_ARTI_DIR}/images
    # for both the Kubernetes and storage images,
    for d in kubernetes storage-ceph
    do
      # begin the perilous process of unsquashing the image, modifying it, and re-creating the artifacts
      pushd "$artdir/$d" || exit 1
        # get the original file names for naming new artifacts
        # shellcheck disable=SC2061
        initrd_name=$(find . -name *.xz)
        # shellcheck disable=SC2061
        squashfs_name=$(find . -name *.squashfs)

        # Make a spot for the original artifacts
        mkdir -pv ../images-bak/$d

        # unsquash the image
        # shellcheck disable=SC2061
        find . -name *.squashfs -print0 | xargs --null unsquashfs

        # back up the existing artifacts there in case of catastrophe
        mv *.squashfs *.kernel *.xz ../images-bak/$d

        echo "Fixing ntp-upgrade and create-kis-artifacts script via chroot..."
        # Some images may not have the upgrade script yet, so copy it into place
        if ! [[ -f squashfs-root/srv/cray/scripts/metal/ntp-upgrade-config.sh ]]; then
          cp squashfs-root/srv/cray/scripts/metal/set-ntp-config.sh squashfs-root/srv/cray/scripts/metal/ntp-upgrade-config.sh
        fi

        chroot squashfs-root/ /bin/bash <<'EOF'
# Remove set -e for this run
sed -i 's/^set -e$/#set -e/' srv/cray/scripts/common/create-kis-artifacts.sh
# it is possible more than one kernel is installed, so this version of the script needs to be adjusted to account for that
kernel_version_full=$(rpm -qa | grep kernel-default | grep -v devel | tail -n 1 | cut -f3- -d'-')
kernel_version=$(ls -1tr /boot/vmlinuz-* | tail -n 1 | cut -d '-' -f2,3,4)
sed -i 's/version_full=.*/version_full='"$kernel_version_full"'/g' srv/cray/scripts/common/create-kis-artifacts.sh
sed -i 's/kernel_version=.*/kernel_version='"$kernel_version"'/g' srv/cray/scripts/common/create-kis-artifacts.sh
# set the local stratum lower so it is not selected over ncn-m001 in most cases
sed -i 's/^\(  echo "local stratum 3 orphan" >>"$CHRONY_CONF"$\)/  echo "local stratum 10 orphan" >>"$CHRONY_CONF"/' srv/cray/scripts/metal/ntp-upgrade-config.sh
# if drift > 1s, step the clock on reboot, otherwise, slew it. Add this line after the logchange line in the script
sed -i '/^\(  echo "logchange 1.0" >>"$CHRONY_CONF"$\)/a \ \ echo "initstepslew 1 $UPSTREAM_NTP_SERVER" >>"$CHRONY_CONF"' srv/cray/scripts/metal/ntp-upgrade-config.sh
# remove the unreachable default ntp pools
rm -f etc/chrony.d/pool.conf
# silence some of the noise mksquashfs creates
sed -i 's/^mksquashfs.*/& 1>\/dev\/null/' srv/cray/scripts/common/create-kis-artifacts.sh
# silence xattr/inode errors
sed -i 's/-xattrs/-no-xattrs/' srv/cray/scripts/common/create-kis-artifacts.sh
# Create the new artifacts
srv/cray/scripts/common/create-kis-artifacts.sh
# set -e back
sed -i 's/^#set -e$/set -e/' srv/cray/scripts/common/create-kis-artifacts.sh
EOF
        # find the path of the mounted chroot
        squash_path="$(mount | grep "$CSM_RELEASE" | awk '$3 ~ /squashfs-root$/ {print $3}')"
        # if a mount is found, attempt to unmount it, but it is not critical if we cannot
        if [[ -n "$squash_path" ]]; then
            # alert the user so they can umount it later
            # Unmounting during this automation proved problematic, so cleanup can be done manually at the end of pre-req
            echo "Please unmount $squash_path after this script is complete"
            UNMOUNTS+=("$squash_path")
        fi

        # Move the newly-generated artifacts into place
        # We may have more than one kernel, so mv them all over
        mv squashfs-root/squashfs/*.kernel .
        mv squashfs-root/squashfs/*.xz "${initrd_name}"
        # initrd also needs its permissions adjusted
        chmod 644 "${initrd_name}"
        mv squashfs-root/squashfs/*.squashfs "${squashfs_name}"
        # cleanup by removing the unsquashed image
        #rm -rf squashfs-root/
      # pop out of the dir
      popd || exit 1
      
    done
    record_state ${state_name} "$(hostname)"
else
    echo "====> ${state_name} has been completed"
fi
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    temp_file=$(mktemp)
    artdir=${CSM_ARTI_DIR}/images
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

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    # get all installed csm version into a file
    kubectl get cm -n services cray-product-catalog -o json | jq  -r '.data.csm' | yq r -  -d '*' -j | jq -r 'keys[]' > /tmp/csm_versions
    # sort -V: version sort
    highest_version=$(sort -V /tmp/csm_versions | tail -1)
    minimum_version="0.9.4"
    # compare sorted versions with unsorted so we know if our highest is greater than minimum
    if [[ $(printf "$minimum_version\n$highest_version") != $(printf "$minimum_version\n$highest_version" | sort -V) ]]; then
      echo "Required CSM patch $minimum_version or above has not been applied to this system"
      exit 1
    fi

    rpm --force -Uvh $(find $CSM_ARTI_DIR/rpm/cray/csm/ -name \*csm-testing\*.rpm | sort -V | tail -1)
    GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="UNINSTALL_CONMAN"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    numOfDeployments=$(helm list -n services | grep cray-conman | wc -l)
    if [[ $numOfDeployments -ne 0 ]]; then
        helm uninstall -n services cray-conman
    fi

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_NEW_CONSOLE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    numOfDeployments=$(helm list -n services | grep cray-console | wc -l)
    if [[ $numOfDeployments -eq 0 ]]; then
        helm -n services upgrade --install --wait cray-console-operator ${CSM_ARTI_DIR}/helm/cray-console-operator-*.tgz
        helm -n services upgrade --install --wait cray-console-node ${CSM_ARTI_DIR}/helm/cray-console-node-*.tgz
        helm -n services upgrade --install --wait cray-console-data ${CSM_ARTI_DIR}/helm/cray-console-data-*.tgz
    fi

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PRECACHE_NEXUS_IMAGES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    pdsh -b -S -w $(grep -oP 'ncn-w\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'for image in sonatype/nexus3:3.25.0 dtr.dev.cray.com/cray/proxyv2:1.6.13-cray1 dtr.dev.cray.com/baseos/busybox:1 docker.io/sonatype/nexus3:3.25.0 dtr.dev.cray.com/cray/cray-nexus-setup:0.3.2; do crictl pull $image; done'

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi


state_name="CSM_UPDATE_SPIRE_ENTRIES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" && $(hostname) == "ncn-m001" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/update-spire-entries.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

# Take cps deployment snapshot (if cps installed)
set +e
trap - ERR
kubectl get pod -n services | grep -q cray-cps
if [ "$?" -eq 0 ]; then
  cps_deployment_snapshot=$(cray cps deployment list --format json | jq -r \
    '.[] | select(."podname" != "NA" and ."podname" != "") | .node' || true)
  echo $cps_deployment_snapshot > /etc/cray/upgrade/csm/${CSM_RELEASE}/cp.deployment.snapshot
fi
trap 'err_report' ERR
set -e

# Alert the user of action to take for cleanup
if [[ ${#UNMOUNTS[@]} -ne 0 ]]; then
    for m in "${UNMOUNTS[@]}"
    do
        echo "Please umount -l $m"
    done
fi

ok_report
