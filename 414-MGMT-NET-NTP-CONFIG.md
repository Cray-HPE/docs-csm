# Management Network NTP configuration

This page describes how NTP is setup and configured on the management network switches. 

# Requirements
- Access to switches
- CSI NMN.yaml file

# Configuration
Our NTP servers will be the first 3 worker nodes.  You can find these IPs from the CSI generated NMN.yaml file.

# Aruba

Get current NTP configuration.
```
sw-spine-001(config)# show run | include ntp
ntp server 10.252.1.7
ntp server 10.252.1.8
ntp server 10.252.1.9
ntp enable
```

Delete current NTP configuration.
```
sw-spine-001(config)# no ntp server 10.252.1.7
sw-spine-001(config)# no ntp server 10.252.1.8
sw-spine-001(config)# no ntp server 10.252.1.9
```

Add new NTP configuration.
```
sw-spine-001(config)# ntp enable
sw-spine-001(config)# ntp server 10.252.1.10
sw-spine-001(config)# ntp server 10.252.1.11
sw-spine-001(config)# ntp server 10.252.1.12
```

Verify NTP status.
```
sw-spine-001(config)# show ntp associations
----------------------------------------------------------------------
 ID            NAME          REMOTE          REF-ID ST LAST POLL REACH
----------------------------------------------------------------------
  1      10.252.1.7      10.252.1.7     172.30.47.5  3   18   64     1
  2      10.252.1.8      10.252.1.8     172.30.47.5  3   11   64     1
  3      10.252.1.9      10.252.1.9     172.30.47.5  3   11   64     1
----------------------------------------------------------------------
```

# Dell 

Get current NTP configuration.
```
sw-leaf-001# show running-configuration | grep ntp
ntp server 10.252.1.12
ntp server 10.252.1.13
ntp server 10.252.1.14 prefer
```

Delete current NTP configuration.
```
sw-leaf-001# configure terminal
sw-leaf-001(config)# no ntp server 10.252.1.12
sw-leaf-001(config)# no ntp server 10.252.1.13
sw-leaf-001(config)# no ntp server 10.252.1.14
```
Add new NTP server configuration.
```
ntp server 10.252.1.10 prefer
ntp server 10.252.1.11
ntp server 10.252.1.12
ntp source vlan 2
```

Verify NTP status.
```
sw-leaf-001# show ntp associations
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*10.252.1.12     10.252.1.4       4 u   52   64    3    0.420   -0.262   0.023
 10.252.1.13     10.252.1.4       4 u   51   64    3    0.387   -0.225   0.043
 10.252.1.14     10.252.1.4       4 u   48   64    3    0.399   -0.222   0.050
* master (synced), # master (unsynced), + selected, - candidate, ~ configured
```

# Mellanox

Get current NTP configuration.
```
sw-spine-001 [standalone: master] (config) # show run | include ntp
no ntp server 10.252.1.9 disable
   ntp server 10.252.1.9 keyID 0
no ntp server 10.252.1.9 trusted-enable
   ntp server 10.252.1.9 version 4
no ntp server 10.252.1.10 disable
   ntp server 10.252.1.10 keyID 0
no ntp server 10.252.1.10 trusted-enable
   ntp server 10.252.1.10 version 4
no ntp server 10.252.1.11 disable
   ntp server 10.252.1.11 keyID 0
no ntp server 10.252.1.11 trusted-enable
   ntp server 10.252.1.11 version 4
```

Delete current NTP configuration.
```
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.9
sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.10
sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.11
```

Add New NTP configuration.
```
sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.12
sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.13
sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.14
```

Verify NTP configuration.
```
sw-spine-001 [standalone: master] # show ntp

NTP is administratively            : enabled
NTP Authentication administratively: disabled
NTP server role                    : enabled

Clock is synchronized:
  Reference: 10.252.1.14
  Offset   : -0.056 ms

Active servers and peers:
  10.252.1.12:
    Conf Type          : serv
    Status             : candidat(+)
    Stratum            : 4
    Offset(msec)       : -0.119
    Ref clock          : 10.252.1.4
    Poll Interval (sec): 128
    Last Response (sec): 107
    Auth state         : none

  10.252.1.13:
    Conf Type          : serv
    Status             : candidat(+)
    Stratum            : 4
    Offset(msec)       : -0.059
    Ref clock          : 10.252.1.4
    Poll Interval (sec): 128
    Last Response (sec): 96
    Auth state         : none

  10.252.1.14:
    Conf Type          : serv
    Status             : sys.peer(*)
    Stratum            : 4
    Offset(msec)       : -0.056
    Ref clock          : 10.252.1.4
    Poll Interval (sec): 128
    Last Response (sec): 118
    Auth state         : none
```

