# Configure NTP on NCNs

The management nodes serve Network Time Protocol (NTP) at stratum 10, except for ncn-m001, which serves at stratum 8 (or lower if an upstream NTP server is set), and all management nodes peer with each other. 

Until an upstream NTP server is configured. The time on the NCNs may not match the current time at the site, but they will stay in sync with each other.

### Topics:
   * [Change NTP Config](#change_ntp_config)
   * [Troubleshooting NTP](#troubleshooting_ntp)
      * [chrony Log Files](#chrony_log_files)
      * [Force a Time Sync](#force_a_time_sync)
   * [Customize NTP](#customize_ntp)
      * [Set A Local Timezone](#set-a-local-timezone)
      * [Configure NTP on PIT to Local Timezone](#configure_ntp_on_pit_to_local_timezone)
      * [Configure NCN Images to Use Local Timezone](#configure_ncn_images_to_use_local_timezone)

## Details

<a name="change_ntp_config"></a>
### Change NTP Config

There are three different methods for configuring NTP, which are described below. The first option is the
recommended method.

   * Edit /etc/chrony.d/cray.conf and restart chronyd on each node.

      ```bash
      ncn# vi /etc/chrony.d/cray.conf
      ncn# systemctl restart chronyd
      ```

   * Edit the data.json file, restart basecamp, and run the NTP script on each node.

      ```bash
      ncn-m001# vi data.json
      ncn-m001# systemctl restart basecamp
      ncn# /srv/cray/scripts/metal/set-ntp-config.sh
      ```

   * Edit the data.json file, restart basecamp, and restart nodes so cloud-init runs on boot.

      ```bash
      ncn-m001# vi data.json
      ncn-m001# systemctl restart basecamp
      ```

      Reboot each node.

      ```bash
      ncn# reboot
      ```

      Cloud-init caches data, so there could be inconsistent results with this method.

<a name="troubleshooting_ntp"></a>
### Troubleshooting NTP

Verify NTP is configured correctly and troubleshoot any issues.

The `chronyc` command can be used to gather information on the state of NTP.

1. Check if a host is allowed to use NTP from HOST. This example sets HOST to 10.252.0.7

   ```bash
   ncn# chronyc accheck 10.252.0.7
   ```

   `208 Access allowed` will be returned if a host is allowed to use NTP from HOST.

1. Check the system clock performance.

   ```bash
   ncn# chronyc tracking
   ```

   Example output:

   ```
   Reference ID    : 0AFC0104 (ncn-s003)
   Stratum         : 4
   Ref time (UTC)  : Mon Nov 30 20:02:24 2020
   System time     : 0.000007622 seconds slow of NTP time
   Last offset     : -0.000014609 seconds
   RMS offset      : 0.000015776 seconds
   Frequency       : 6.773 ppm fast
   Residual freq   : -0.000 ppm
   Skew            : 0.008 ppm
   Root delay      : 0.000075896 seconds
   Root dispersion : 0.000484318 seconds
   Update interval : 513.7 seconds
   Leap status     : Normal
   ```

1. View information on drift and offset

   ```bash
   ncn# chronyc sourcestats
   ```

   Example output:

   ```
   210 Number of sources = 8
   Name/IP Address            NP  NR  Span  Frequency  Freq Skew  Offset  Std Dev
   ==============================================================================
   ncn-w001                    6   3   42m     -0.029      0.126  +4104ns    28us
   ncn-w002                    6   6   42m     -0.028      0.030    +44us  7278ns
   ncn-w003                   12   7   23m     -0.059      0.023    -35us  8359ns
   ncn-s002                   36  17  213m     -0.001      0.010  +5794ns    54us
   ncn-s003                   36  17  212m     -0.000      0.007   -178ns    40us
   ncn-m001                    0   0     0     +0.000   2000.000     +0ns  4000ms
   ncn-m002                   28  15  192m     -0.007      0.009  +9942ns    49us
   ncn-m003                   24  15  197m     -0.005      0.009  +9442ns    46us
   ```

1. View the NTP servers, pools, and peers.

   ```bash
   ncn# chronyc sources
   ```

   Example output:

   ```
   210 Number of sources = 8
   MS Name/IP address         Stratum Poll Reach LastRx Last sample
   ===============================================================================
   =? ncn-w001                      4   9   377   435   +162us[ +164us] +/-  679us
   =? ncn-w002                      4   9   377   505   +118us[ +120us] +/-  277us
   =? ncn-w003                      4   7   377    82   +850ns[+2686ns] +/-  504us
   =? ncn-s002                      4   9   377   542    -38us[  -36us] +/-  892us
   =* ncn-s003                      3   9   377    19    +13us[  +15us] +/-  110us
   =? ncn-m001                      0   9     0     -     +0ns[   +0ns] +/-    0ns
   =? ncn-m002                      4   8   377   161    -47us[  -45us] +/-  408us
   =? ncn-m003                      4   8   377   215    -11us[-9109ns] +/-  446us
   ```

<a name="chrony_log_files"></a>
#### chrony Log Files

The `chrony` logs are stored at `/var/log/chrony/`

<a name="force_a_time_sync"></a>
#### Force a Time Sync

1. If the time is out of sync, force a sync of NTP.

   If Kubernetes or other services are already up, they do not always react well if there is a large time jump.
   Ideally, this action should be made as the node is booting.

   ```bash
   ncn# chronyc burst 4/4
   ```

1. Wait about 15 seconds while NTP measurements are gathered

   ```bash
   ncn# sleep 15
   ```

1. Jump the clock manually

   ```bash
   ncn# chronyc makestep
   ```

<a name="known-issues-and-bugs"></a>

#### Known Issues and Bugs

As the NTP setup switched from a homegrown shell script into a native cloud-init module, there were some bugs that ended up shipping with older versions of CSM. If customers upgraded, these bugs carried forward and can present problems with time syncing correctly. This section aims to describe how to diagnose and fix these.

These issues all relate to certain nodes not being in a correct state.

##### Correct State

ncn-m001 should have these important settings in `/etc/chrony.d/cray.conf`:

```
server time.nist.gov iburst trust
# or 
pool time.nist.gov iburst
# ncn-m001 should NOT use itself as a server and is known to cause issues

# this allows the clock to step itself during a restart without affecting running apps if it drifts more than 1 second
initstepslew 1 time.nist.gov
# the other ncns are set to 10, so in the event of a tie, ncn-m001 is chosen as the leader
local stratum 8 orphan
```

These settings ensure there is a low-stratum NTP server that ncn-m001 has access to. ncn-m001 also has the following:

```
# all non-ncn-m001 NCNs use ncn-m001 as their server, and they trust it
server ncn-m001 iburst trust
# no pools are on the other ncns
# ncn-m001 should NOT use itself as a server and is known to cause issues

# this allows the clock to step itself during a restart without affecting running apps if it drifts more than 1 second
initstepslew 1 ncn-m001
# the ncns peer with each other at a high stratum, and choose ncn-m001 (statum 8 or lower) in the event of a tie
local stratum 10 orphan

# The nodes should have a max of 9 peers and should not include themselves in the list
peer ncn-m001 minpoll -2 maxpoll 9 iburst
peer ncn-m003 minpoll -2 maxpoll 9 iburst
peer ncn-s001 minpoll -2 maxpoll 9 iburst
peer ncn-s002 minpoll -2 maxpoll 9 iburst
peer ncn-s003 minpoll -2 maxpoll 9 iburst
peer ncn-w001 minpoll -2 maxpoll 9 iburst
peer ncn-w002 minpoll -2 maxpoll 9 iburst
peer ncn-w003 minpoll -2 maxpoll 9 iburst
```

##### Quick Fixes

###### Fix ncn-m001

Most of the bugs from 0.9.x+ carried forward with upgrades. Most commonly, ncn-m001 is the problem as it either does not have a valid upstream, or has a bad config. This can be quickly remedied by running three commands to download the latest `cc_ntp` module, downloading an updated template, and re-running cloud-init.

```
wget -O /usr/lib/python3.6/site-packages/cloudinit/config/cc_ntp.py https://raw.githubusercontent.com/Cray-HPE/metal-cloud-init/main/cloudinit/config/cc_ntp.py
wget -O /etc/cloud/templates/chrony.conf.cray.tmpl https://raw.githubusercontent.com/Cray-HPE/metal-cloud-init/main/config/cray.conf.j2
cloud-init single --name ntp --frequency always
```

###### Fix other NCNs

The other NCNs sometimes have the wrong stratum set or are missing the `initstepslew` directive. These can be added in fairly quickly with some `sed` commands:

```
# increase the stratum on non-ncn-m001 NCNs
sed -i "s/local stratum 3 orphan/local stratum 10 orphan/" /etc/chrony.d/cray.conf
# add a new line after the logchange directive
sed -i "/^\(logchange 1.0\)\$/a initstepslew 1 ncn-m001" /etc/chrony.d/cray.conf
# restart
systemctl restart chronyd
```


<a name="customize_ntp"></a>
### Customize NTP

<a name="set-a-local-timezone"></a>
#### Set A Local Timezone

This procedure needs to be completed on the PIT node before the other management nodes are deployed.

<a name="configure_ntp_on_pit_to_local_timezone"></a>
#### Configure NTP on PIT to Local Timezone

HPE Cray EX systems with CSM software have UTC as the default time zone. To change this, you will need
to set an environment variable, as well as `chroot` into the node images and change some files
there. You can find a list of timezones to use in the commands below by running `timedatectl list-timezones`.

1. Run the following commands, replacing them with your timezone as needed.

   ```bash
   pit# export NEWTZ=America/Chicago
   pit# echo -e "\nTZ=${NEWTZ}" >> /etc/environment
   pit# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone ${NEWTZ}#" /root/bin/configure-ntp.sh
   pit# sed -i 's/--utc/--localtime/' /root/bin/configure-ntp.sh
   pit# /root/bin/configure-ntp.sh
   ```

1. The configure-ntp.sh script should have the information for your local timezone in the output.

   ```
   pit# /root/bin/configure-ntp.sh
   CURRENT TIME SETTINGS
   rtc: 2021-03-26 11:34:45.873331+00:00
   sys: 2021-03-26 11:34:46.015647+0000
   200 OK
   200 OK
   NEW TIME SETTINGS
   rtc: 2021-03-26 06:35:16.576477-05:00
   sys: 2021-03-26 06:35:17.004587-0500
   ```

1. Verify the new timezone setting by running `timedatectl` and `hwclock --verbose`.

   ```bash
   pit# timedatectl
   ```

   Example output:

   ```
         Local time: Fri 2021-03-26 06:35:58 CDT
     Universal time: Fri 2021-03-26 11:35:58 UTC
           RTC time: Fri 2021-03-26 11:35:58
          Time zone: America/Chicago (CDT, -0500)
    Network time on: no
   NTP synchronized: no
    RTC in local TZ: no
   ```

   ```bash
   pit# hwclock --verbose
   ```

   Example output:

   ```
   hwclock from util-linux 2.33.1
   System Time: 1616758841.688220
   Trying to open: /dev/rtc0
   Using the rtc interface to the clock.
   Last drift adjustment done at 1616758836 seconds after 1969
   Last calibration done at 1616758836 seconds after 1969
   Hardware clock is on local time
   Assuming hardware clock is kept in local time.
   Waiting for clock tick...
   ...got clock tick
   Time read from Hardware Clock: 2021/03/26 06:40:42
   Hw clock time : 2021/03/26 06:40:42 = 1616758842 seconds since 1969
   Time since last adjustment is 6 seconds
   Calculated Hardware Clock drift is 0.000000 seconds
   2021-03-26 06:40:41.685618-05:00
   ```

1. If the time is off and not accurate to your timezone, you will need to _manually_ set the date and then run the NTP script again.

   ```bash
   # Set as close as possible to the real time
   pit# timedatectl set-time "2021-03-26 00:00:00"
   pit# /root/bin/configure-ntp.sh
   ```

   The PIT is now configured to your local timezone.

<a name="configure_ncn_images_to_use_local_timezone"></a>
#### Configure NCN Images to Use Local Timezone

You need to adjust the node images so that they also boot in the local timezone. This is accomplished by `chroot`ing into the unsquashed images, making some modifications, and then squashing it back up and moving the new images into place.

1. Set some variables.

   This example uses `IMGTYPE=ceph` for the utility storage nodes, but the same process should also be done
   with `IMGTYPE=k8s` for the Kubernetes master and worker nodes.

   ```bash
   pit# export NEWTZ=America/Chicago
   pit# export IMGTYPE=ceph
   pit# export IMGDIR=/var/www/ephemeral/data/${IMGTYPE}
   ```

1. Go to the Ceph image directory and unsquash the image.

    ```bash
    pit# cd ${IMGDIR}
    pit# unsquashfs *.squashfs
    ```

1. Start a chroot session inside the unsquashed image. Your prompt may change to reflect that you are now in the root directory of the image.

    ```bash
    pit# chroot ./squashfs-root
    ```

1. Inside the chroot session, you will modify a few files by running the following commands, and then exit from the chroot session.

    ```bash
    pit-chroot# echo TZ=${NEWTZ} >> /etc/environment
    pit-chroot# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/set-ntp-config.sh
    pit-chroot# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/set-ntp-config.sh
    pit-chroot# /srv/cray/scripts/common/create-kis-artifacts.sh
    pit-chroot# exit
    pit#
    ```

1. Back outside the chroot session, you will now back up the original images and copy the new ones into place.

    ```bash
    pit# mkdir -v ${IMGDIR}/orig
    pit# mv -v *.kernel *.xz *.squashfs ${IMGDIR}/orig/
    pit# cp -v squashfs-root/squashfs/* .
    pit# chmod -v 644 ${IMGDIR}/initrd.img.xz
    ```

1. Unmount the squashfs mount (which was mounted by the earlier unsquashfs command).

    ```bash
    pit# umount -v ${IMGDIR}/squashfs-root/mnt/squashfs
    ```

1. Repeat all of the previous steps, with this change to the IMGTYPE variable.

   This example uses `IMGTYPE=k8s` for the Kubernetes master and worker nodes.

   ```bash
   pit# export IMGTYPE=k8s
   pit# export IMGDIR=/var/www/ephemeral/data/${IMGTYPE}
   ```

1. Go to the k8s image directory and unsquash the image.

    ```bash
    pit# cd ${IMGDIR}
    pit# unsquashfs *.squashfs
    ```

1. Start a chroot session inside the unsquashed image. Your prompt may change to reflect that you are now in the root directory of the image.

    ```bash
    pit# chroot ./squashfs-root
    ```

1. Inside the chroot session, you will modify a few files by running the following commands, and then exit from the chroot session.

    ```bash
    pit-chroot# echo TZ=${NEWTZ} >> /etc/environment
    pit-chroot# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/set-ntp-config.sh
    pit-chroot# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/set-ntp-config.sh
    pit-chroot# /srv/cray/scripts/common/create-kis-artifacts.sh
    pit-chroot# exit
    pit#
    ```

1. Back outside the chroot session, you will now back up the original images and copy the new ones into place.

    ```bash
    pit# mkdir -v ${IMGDIR}/orig
    pit# mv -v *.kernel *.xz *.squashfs ${IMGDIR}/orig/
    pit# cp -v squashfs-root/squashfs/* .
    pit# chmod -v 644 ${IMGDIR}/initrd.img.xz
    ```

1. Unmount the squashfs mount (which was mounted by the earlier unsquashfs command)

    ```bash
    pit# umount -v ${IMGDIR}/squashfs-root/mnt/squashfs
    ```

1. Now link the new images so that the NCNs will get them from the LiveCD node when they boot.

    ```bash
    pit# set-sqfs-links.sh
    ```

1. Make a note that when performing the [csi handoff of NCN boot artifacts in Deploy Final NCN](../../install/deploy_final_ncn.md#ncn-boot-artifacts-hand-off), you must be sure to specify these new images. Otherwise ncn-m001 will use the default timezone when it boots, and subsequent reboots of the other NCNs will also lose the customized timezone changes.
