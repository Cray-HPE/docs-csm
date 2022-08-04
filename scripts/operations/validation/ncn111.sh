#!/bin/bash

main() {
    if check_velero; then
        velero_count=1
    else
        velero_count=0
    fi

    if check_spire_agent; then
        spire_count=1
    else
        spire_count=0
    fi

    if cfs_state_reporter; then
        cfs_count=1
    else
        cfs_count=0
    fi

    if clock_skew; then
        clock_count=1
    else
        clock_count=0
    fi

    count_success=$(($velero_count + $spire_count + $cfs_count + $clock_count))
    count_total=4
    count_failed=$(($count_total - $count_success))

    echo " "
    echo "======================================="
    echo " "
    echo "Summary: $count_failed of $count_total tests FAILED"
    if [[ "$velero_count" == 0 ]]; then
        echo " "
        echo "- Velero failed backups found, proceed to https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5064/troubleshooting/known_issues/issues_with_ncn_health_checks.md for remediation steps"
        echo " "
    fi

    if [[ "$spire_count" == 0 ]]; then
        echo "- spire-agent is not enabled please follow documentation at https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5064/troubleshooting/known_issues/issues_with_ncn_health_checks.md"
        echo " "
    fi

    if [[ "$cfs_count" == 0 ]]; then
        echo "- Issues found on CFS, please proceed to https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5064/troubleshooting/known_issues/issues_with_ncn_health_checks.md"
        echo " "
    fi

    if [[ "$clock_count" == 0 ]]; then
        echo "- Issues found on clock, please proceed to https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5064/troubleshooting/known_issues/issues_with_ncn_health_checks.md"
        echo " "
    fi
}

check_velero() {
    echo "Checking for any Velero failed backups"
    sleep 2
    velero=$(kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name')
    if [[ $? != 0 ]]; then
        echo "No issues found."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found failed backup ##"
        kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name' | sed -e 's/^"//' -e 's/"$//'
        echo "---------------------------------------"
        return 1
    fi
}

check_spire_agent() {
    echo "Checking spire agent status"
    spire=$(kubectl get pods -n spire | grep request-ncn-join-token)
    if [[ $? = 0 ]]; then
        echo "No issues found."
        echo "---------------------------------------"
        return 0
    else
        echo "Issues found"
        return 1
    fi
}

cfs_state_reporter() {
    echo "Checking cfs-state-reporter on HTTPS connection pool"
    cfs_check=$(systemctl status cfs-state-reporter | grep HTTPSConnectionPool)
    if [[ $? != 0 ]]; then
        echo "No issues found."
        echo "---------------------------------------"
        return 0
    else
        echo "Issues found"
        return 1
    fi
}

clock_skew() {
    echo "Checking clock skew"
    clocskew_check=$(chronyc sources -v)
    if [[ $? = 0 ]]; then
        echo "No issues found."
        echo "---------------------------------------"
        return 0
    else
        echo "Issues found, proceed to https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5064/troubleshooting/known_issues/issues_with_ncn_health_checks.md"
        return 1
    fi
}

main "$@"
