#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

. /etc/cray/upgrade/csm/myenv

state_name="VERIFY_K8S_NODES_UPGRADED"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/verify-k8s-nodes-upgraded.sh

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PRE_CSM_UPGRADE_RESIZE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    /usr/share/doc/csm/upgrade/1.0.1/scripts/postgres-operator/pre-service-upgrade.sh

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CSM_SERVICE_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    # try csm service upgrade (3 times)
    set +e
    n=0
    csm_upgraded=0
    pushd ${CSM_ARTI_DIR}
    until [ "$n" -ge 3 ]
    do
        ./upgrade.sh
        if [[ $? -eq 0 ]]; then
            csm_upgraded=1
            break
        else
            n=$((n+1))
        fi
    done
    popd +0
    set -e
    if [[ $csm_upgraded -ne 1 ]]; then
        echo "CSM Service upgrade failed after 3 retries"
        exit 1
    fi

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_UPGRADE_RESIZE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    /usr/share/doc/csm/upgrade/1.0.1/scripts/postgres-operator/post-service-upgrade.sh

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_UPGRADE_APPLY_POD_PRIORITY"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/add_pod_priority.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_ENABLE_PSP"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/enable-psp.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

ok_report
