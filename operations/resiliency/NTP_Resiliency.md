## NTP Resiliency

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
    "------$i--------"; ssh $i '/srv/cray/scripts/metal/set-ntp-config.sh'; done
    ```

    Example output:

    ```
    ------ncn-w001--------
    CURRENT TIME SETTINGS
    rtc: 2021-01-16 15:04:57.593224+00:00
    sys: 2021-01-16 15:05:07.449052+0000
    200 OK
    200 OK
    NEW TIME SETTINGS
    rtc: 2021-02-19 13:02:28.811921+00:00
    sys: 2021-02-19 13:02:28.924540+0000
    ------ncn-w002--------
    CURRENT TIME SETTINGS
    rtc: 2021-01-16 15:05:35.390043+00:00
    sys: 2021-01-16 15:05:45.838885+0000
    200 OK
    200 OK
    NEW TIME SETTINGS
    rtc: 2021-02-19 13:03:06.515083+00:00
    sys: 2021-02-19 13:03:07.184846+0000
    
    [...]
    ```

4.  Reboot each node.

    If manually adjust the time is not effective, reboot each node to trigger the NTP script to run on first boot from cloud-init.

