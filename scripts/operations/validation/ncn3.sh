#!/bin/bash

main() {
    if check_bos; then
        bos_count=1
    else
        bos_count=0
    fi

    if check_cfs; then
        cfs_count=1
    else
        cfs_count=0
    fi

    if check_conman; then
        conman_count=1
    else
        conman_count=0
    fi

    if check_crus; then
        crus_count=1
    else
        crus_count=0
    fi

    if check_gitea; then
        gitea_count=1
    else
        gitea_count=0
    fi

    if check_ims; then
        ims_count=1
    else
        ims_count=0
    fi

    if check_ipxe; then
        ipxe_count=1
    else
        ipxe_count=0
    fi

    if check_tftp; then
        tftp_count=1
    else
        tftp_count=0
    fi

    if check_vcs; then
        vcs_count=1
    else
        vcs_count=0
    fi

    count_success=$(($bos_count + $cfs_count + $conman_count + $crus_count + $gitea_count + $ims_count + $ipxe_count + $tftp_count + $vcs_count))
    count_total=9
    count_failed=$(($count_total - $count_success))

    echo " "
    echo "======================================="
    echo " "
    echo "Summary: $count_failed of $count_total SMS tests FAILED"
    if [[ "$count_failed" != 0 ]]; then
        echo " "
        echo "- $count_failed SMS test failed, proceed to https://github.com/Cray-HPE/docs-csm/blob/main/troubleshooting/known_issues/sms_services_health_checks.md for remediation steps"
        echo " "
    fi
}

check_bos() {
    echo "Checking for any bos failed under SMS execution"
    sleep 2
    bos=$(/usr/local/bin/cmsdev test -q bos|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on bos test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS bos execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_cfs() {
    echo "Checking for any cfs failed under SMS execution"
    sleep 2
    cfs=$(/usr/local/bin/cmsdev test -q cfs|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on cfs test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS cfs execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_conman() {
    echo "Checking for any conman failed under SMS execution"
    sleep 2
    conman=$(/usr/local/bin/cmsdev test -q conman|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on conman test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS conman execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_crus() {
    echo "Checking for any crus failed under SMS execution"
    sleep 2
    crus=$(/usr/local/bin/cmsdev test -q crus|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on crus test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS crus execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_gitea() {
    echo "Checking for any gitea failed under SMS execution"
    sleep 2
    gitea=$(/usr/local/bin/cmsdev test -q gitea|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on gitea test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS gitea execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_ims() {
    echo "Checking for any ims failed under SMS execution"
    sleep 2
    ims=$(/usr/local/bin/cmsdev test -q ims|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on ims test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS ims execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_ipxe() {
    echo "Checking for any ipxe failed under SMS execution"
    sleep 2
    ipxe=$(/usr/local/bin/cmsdev test -q ipxe|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on ipxe test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS ipxe execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_tftp() {
    echo "Checking for any tftp failed under SMS execution"
    sleep 2
    tftp=$(/usr/local/bin/cmsdev test -q tftp|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on tftp test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS tftp execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

check_vcs() {
    echo "Checking for any vcs failed under SMS execution"
    sleep 2
    vcs=$(/usr/local/bin/cmsdev test -q vcs|grep -i success|awk -F ":" {'print $2'})
    if [[ $? = 0 ]]; then
        echo "No issues found on vcs test execution."
        echo "---------------------------------------"
        return 0
    else
        echo " "
        echo "##ERROR Found error on SMS vcs execution test ##"
        echo "---------------------------------------"
        return 1
    fi
}

main "$@"
