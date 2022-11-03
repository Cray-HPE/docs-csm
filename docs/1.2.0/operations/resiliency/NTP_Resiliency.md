# NTP Resiliency

Sync the time on all non-compute nodes \(NCNs\) via Network Time Protocol \(NTP\). Avoid a single point of failure for NTP when testing system resiliency.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Set the date manually if the time on NCNs is off by more than an a few hours, days, or more.

    For example:

    ```bash
    ncn-m001# timedatectl set-time "2021-02-19 15:04:00"
    ```

2.  Configure NTP on the Pre-install Toolkit \(PIT\).

    ```bash
    ncn-m001# /root/bin/configure-ntp.sh
    ```

3.  Sync NTP on all other nodes.

    If more than nine NCNs are in use on the system, update the for loop in the following command accordingly.

    ```bash
    ncn-m002# for i in ncn-{w,s}00{1..3} ncn-m00{2..3}; do echo \
    "------$i--------"; ssh $i '/srv/cray/scripts/common/chrony/csm_ntp.py'; done
    ```
