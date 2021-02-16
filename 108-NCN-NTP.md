# NTP On NCNs

>See this epic for details: [MTL-1182](https://connect.us.cray.com/jira/browse/MTL-1182).

The NCNs serve NTP at stratum 3 and all NCNs peer with each other.  Currently, the LiveCD does is not running NTP, but the other nodes are when they are booted.

NTP is currently allowed on the NMN and HMN networks.

The NTP peers are set in `data.json`, which is normally created during an initial install.  It is possible to edit this file at a later point, restart basecamp, and then reboot the nodes to apply the change.

## Upstream

The upstream NTP server is also set in `data.json`.  If left blank, the NCNs will simply peer with themselves.  Until an upstream NTP server is configured, the time on the NCNs may not match the current time at the site, but they will stay in sync with each other.

## Changing the config

If you need to adjust the config, you have three options:

- edit `data.json`, restart basecamp (`systemctl restart basecamp`), run the ntp script on each node (`/srv/cray/scripts/metal/set-ntp-config.sh`)
- edit `data.json`, restart basecamp, restart nodes so cloud-init runs on boot
- manually edit `/etc/chrony.d/cray.conf` and restart chrony (`systemctl restart chronyd`) on each node

The first two options are not fully fleshed out yet as we haven't done much testing around changing things.  Cloud-init does cache data, so there could be inconsistent results until further testing is done.

## Troubleshooting

`chronyc` can be used to gather information on the state of NTP.

`chronyc accheck HOST` - checks if a host is allowed to use NTP from HOST

Example:

```
ncn-w001:~ # chronyc accheck 10.252.0.7
208 Access allowed
```

`chronyc tracking` displays system clock performance

Example:

```
ncn-s001:~ # chronyc tracking
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
ncn-s001:~ # chronyc sourcestats
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
ncn-s001:~ # chronyc sources
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

You can step the clocks and force a sync of NTP.  If Kubernetes is already up or other services, they don't always react well if there is a large jump, so ideally, you would do this as the node is booting (our images do this automatically now):

```
chronyc burst 4/4
# wait about 15 seconds while NTP measurements are gathered
# jump the clock manually
chronyc makestep
```
