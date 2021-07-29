#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
# Author: Russell Bunch <doomslayer@hpe.com>
# usage:
#   - export DRY_RR=1 # Dry Rolling Reboot; do not actually reboot the nodes
#   - <args>          # Comma delimited list of NCN hostnames to skip (must exist in /etc/hosts to matter)

export logdir=/var/log/metal/rolling-reboot
mkdir -p $logdir
export log=$(date '+%F-%H-%M-%S').log
export log=$logdir/$log

(
    set -ex
    [ -z "$DRY_RR" ] && reboot_cmd='echo reboot' || reboot_cmd='ipmitool power cycle'
    exit
    num_nodes=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | wc -l)
    echo 'Welcome to the metal rolling-reboot script'
    echo 'This will reboot each NCN one-by-one, using a soft power-cycle. If any fail this script will exit.'
    echo "Skip NCNs by providing a comma <,> delimited list of NCNs (e.g. $0 ncn-m*,ncn-s*)"
    skip="$*"
    skip=$(echo -n $skip | tr -s ',' '|')
    skip=$(echo -n $skip | sed 's/*/.*/g')
    timer=10
    echo 'remaining seconds to interrupt the rolling reboot (press return to skip the countdown):'
    while [ $timer -gt 0 ]; do
        [ $timer != 1 ] && unit=seconds || unit=second
        [ $timer = 10 ] && printf '%2d %7s' $timer $unit || printf '\r% 2d %-7s' $timer $unit
        read -t 1 && printf '\rskipping!!' && break
        timer=$((timer - 1))
    done
    echo "Commencing rolling-reboot for (all) $num_nodes non-compute nodes ..."
    [ -n "$skip" ] && echo >&2 Skipping "$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | grep -vE ($skip) | wc -l) NCNs [pattern: ($skip)]" || echo 'no skip pattern provided'
    [ -z "$skip" ] && hosts=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | grep -v ($(hostname)|ncn-m001) | tr -t '\n' ' ') || hosts=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | grep -Ev "($skip)" | tr -t '\n' ' ')
    for host in $hosts; do
        echo "$host setting one-time boot option and commencing an ACPI power cycle"
        ssh $host -o BatchMode=yes -o StrictHostKeyChecking=no 'echo $(hostname) is running: $(uname -a); echo "$(hostname) is going to reboot with the following intent:";next="$(efibootmgr | grep -i bootcurrent | cut -d " " -f2)"; efibootmgr -n $next | grep $next;' || echo >&2 "failed to reach $host over SSH"
        echo "$host is rebooting ..." && ssh $host -o BatchMode=yes -o StrictHostKeyChecking=no $reboot_cmd 2>/dev/null
        while ! ping -c 1 $host >/dev/null 2>&1 ; do printf '% 10s: Waiting for ICMP/ping ...\n' $host && sleep 2 ; done
        while ! ssh $host >/dev/null 2>&1; do printf '% 10s: Waiting for SSH\n' $host && sleep 2 ; done
        ssh $host -o BatchMode=yes -o StrictHostKeyChecking=no 'printf "%s [uptime: % 10s] is now running: %s\n" $(cat /etc/hostname) $(uptime | cut -d " " -f 2) "$(uname -a)"' 2>/dev/null
        echo next ...
    done
) | tee $log
echo "Done ... see persistent log-file at $log"{{{}}}