#!/bin/bash

main() {
    if pod_notrunning; then
        pod_count=1
    else
        pod_count=0
    fi

    if fs_check; then
        fs_full=1
    else
        fs_full=0
    fi

    count_success=$(($pod_count + $fs_full))
    count_total=2
    count_failed=$(($count_total - $count_success))

    echo " "
    echo "======================================="
    echo " "
    echo "Summary: $count_failed of $count_total tests FAILED"
    if [[ "$pod_count" == 0 ]]; then
        echo " "
        echo "- Some pods are in not running or completed state follow https://github.com/Cray-HPE/docs-csm/blob/main/operations/validate_csm_health.md#12-ncn-resource-checks-optional for remediation steps"
        echo " "
    fi

    if [[ "$fs_full" == 0 ]]; then
        echo "- Root Fileystem has over 80% of use, follow https://github.com/Cray-HPE/docs-csm/blob/main/operations/validate_csm_health.md#121-known-issues-with-ncn-resource-checks to remediate"
        echo " "
    fi
}

pod_notrunning() {
    echo "Checking for any Pod with status different of  Completed/Running"
    sleep 2
    pod=$(kubectl get pods -A -o wide | grep -v "Completed\|Running")
    if [[ $? != 0 ]]; then
        echo "No issues found."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found failed POD Check list below ##"
        kubectl get pods -A -o wide | grep -v "Completed\|Running"
        echo "---------------------------------------"
        return 1
    fi
}

fs_check() {
    echo "Checking is Filesystem usage is over 80%"
    sleep 2
    fs_check=$(df -P / | awk '0+$5 >= 80 {print}')
    if [[ -n $fs_check ]]; then
        df -P / | awk '0+$5 >= 10 {print}'
        echo "---------------------------------------"
        return 1
    else
        echo " "
        echo "No issue found"
        echo "---------------------------------------"
        return 0
    fi
}

main "$@"
