# NTP Resiliency

Synchronize the time on all non-compute nodes \(NCNs\) via Network Time Protocol \(NTP\). Avoid a single point of failure for NTP when testing system resiliency.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn#`) Set the date manually if the time on NCNs is off by more than an a few hours.

    For example:

    ```bash
    timedatectl set-time "2021-02-19 15:04:00"
    ```

1. (`pit#`) Configure NTP on the Pre-install Toolkit \(PIT\).

    ```bash
    /root/bin/configure-ntp.sh
    ```

1. (`ncn#`) Sync NTP on all other nodes.

    If more than nine NCNs are in use on the system, update the loop in the following command accordingly.

    ```bash
    for i in ncn-{w,s}00{1..3} ncn-m00{2..3}; do echo "------$i--------"; ssh $i '/srv/cray/scripts/common/chrony/csm_ntp.py'; done
    ```
