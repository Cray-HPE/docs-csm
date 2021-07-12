# NTP On NCNs

> **Internal use only** See this epic for details: [MTL-1182](https://connect.us.cray.com/jira/browse/MTL-1182).

The NCNs serve NTP at stratum 3 and all NCNs peer with each other. Currently, the LiveCD does is not running NTP, but the other nodes are when they are booted.

NTP is currently allowed on the NMN and HMN networks.

The NTP peers are set in `data.json`, which is normally created during an initial install. It is possible to edit this file at a later point, restart basecamp, and then reboot the nodes to apply the change.

## Upstream

The upstream NTP server is also set in `data.json`. If left blank, the NCNs will simply peer with themselves. Until an upstream NTP server is configured, the time on the NCNs may not match the current time at the site, but they will stay in sync with each other.

## Changing the config

If you need to adjust the config, you have three options:

- edit `data.json`, restart basecamp (`systemctl restart basecamp`), run the ntp script on each node (`/srv/cray/scripts/metal/set-ntp-config.sh`)
- edit `data.json`, restart basecamp, restart nodes so cloud-init runs on boot
- manually edit `/etc/chrony.d/cray.conf` and restart chrony (`systemctl restart chronyd`) on each node

The first two options are not fully fleshed out yet as we have not done much testing around changing things. Cloud-init does cache data, so there could be inconsistent results until further testing is done.

## Troubleshooting

`chronyc` can be used to gather information on the state of NTP.

`chronyc accheck HOST` - checks if a host is allowed to use NTP from HOST

Example:

```
ncn# chronyc accheck 10.252.0.7
208 Access allowed
```

`chronyc tracking` displays system clock performance

Example:

```
ncn# chronyc tracking
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

`chronyc sourcestats` show information on drift and offset

Example:

```
ncn# chronyc sourcestats
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

`chronyc sources` shows the NTP servers, pools, peers

Example:

```
ncn# chronyc sources
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

### Log files

Logs exist at `/var/log/chrony/`, which can be used for further troubleshooting.

### Forcing a time sync

You can step the clocks and force a sync of NTP. If Kubernetes is already up or other services, they do not always react well if there is a large jump, so ideally, you would do this as the node is booting (our images do this automatically now):

```
chronyc burst 4/4
# wait about 15 seconds while NTP measurements are gathered
# jump the clock manually
chronyc makestep
```

# Customizing NTP
<a name="setting-a-local-timezone"></a>
## Setting A Local Timezone

**This procedure needs to be completed _before_ the NCNs are deployed**

## Configure NTP on PIT to your local timezone

Shasta ships with UTC as the default time zone. To change this, you will need to set an environment variable, as well as `chroot` into the node images and change some files there. You can find a list of timezones to use in the commands below by running `timedatectl list-timezones`.

Run the following commands, replacing them with your timezone as needed.

```bash
pit# export NEWTZ=America/Chicago
pit# echo -e "\nTZ=${NEWTZ}" >> /etc/environment
pit# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone ${NEWTZ}#" /root/bin/configure-ntp.sh
pit# sed -i 's/--utc/--localtime/' /root/bin/configure-ntp.sh
pit# /root/bin/configure-ntp.sh
```

You should see the output in your local timezone.

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

You can verify as well by running `timedatectl` and `hwclock --verbose`.

```bash
pit# timedatectl
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

If the time is off and not accurate to your timezone, you will need to _manually_ set the date and then run the NTP script again.

```bash
# Set as close as possible to the real time
pit# timedatectl set-time "2021-03-26 00:00:00"
pit# /root/bin/configure-ntp.sh
```

The PIT is now configured to your local timezone.

## Configure NCN Images To Use Your Local Timezone

You need to adjust the node images so that they also boot in the local timezone. This is accomplished by `chroot`ing into the unsquashed images, making some modifications, and then squashing it back up and moving the new images into place.

1. Set some variables
    ```bash
    pit# export NEWTZ=America/Chicago
    pit# export IMGTYPE=ceph
    pit# export IMGDIR=/var/www/ephemeral/data/${IMGTYPE}
    ```
1. Go to the image directory and unsquash the image
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
1. Back outside the chroot session, you will now backup the original images and copy the new ones into place.
    ```bash
    pit# mkdir ${IMGDIR}/orig
    pit# mv *.kernel *.xz *.squashfs ${IMGDIR}/orig/
    pit# cp squashfs-root/squashfs/* .
    pit# chmod 644 ${IMGDIR}/initrd.img.xz
    ```
1. Unmount the squashfs mount (which was mounted by the earlier unsquashfs command)
    ```bash
    pit# umount ${IMGDIR}/squashfs-root/mnt/squashfs
    ```
1. Repeat all of the previous steps, except in the first step, set the IMGTYPE variable as follows:
   ```bash
   pit# export IMGTYPE=k8s
   ```
   **Be sure to also set the IMGDIR variable again, so it gets the new value of IMGTYPE**
1. Now link the new images so that the NCNs will get them from the LiveCD node when they boot
    ```bash
    pit# set-sqfs-links.sh
    ```
1. Make a note that when performing the [csi handoff of NCN boot artifacts in 007-CSM-INSTALL-REBOOT.md](007-CSM-INSTALL-REBOOT.md#ncn-boot-artifacts-hand-off), you must be sure to specify these new images. Otherwise m001 will use the default timezone when it boots, and subsequent reboots of the other NCNs will also lose the customized timezone changes.
