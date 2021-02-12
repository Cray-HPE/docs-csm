# Management Network NTP configuration

This page describes how NTP is setup and configured on the management network switches. 

# Requirements
- Access to switches
- CSI NMN.yaml file

# Configuration
Our NTP servers will be the first 3 worker nodes.  You can find these IPs from the CSI generated NMN.yaml file.


# Dell 

```
ntp server 10.252.1.14 prefer
ntp server 10.252.1.13
ntp server 10.252.1.12
ntp source vlan 2
```

# Mellanox

```
## Network management configuration
##
# web proxy auth basic password ********
no ntp server 10.252.1.12 disable
   ntp server 10.252.1.12 keyID 0
no ntp server 10.252.1.12 trusted-enable
   ntp server 10.252.1.12 version 4
no ntp server 10.252.1.13 disable
   ntp server 10.252.1.13 keyID 0
no ntp server 10.252.1.13 trusted-enable
   ntp server 10.252.1.13 version 4
no ntp server 10.252.1.14 disable
   ntp server 10.252.1.14 keyID 0
no ntp server 10.252.1.14 trusted-enable
   ntp server 10.252.1.14 version 4
```

# Aruba

```
sw-spine01(config)# ntp enable
sw-spine01(config)# ntp server 10.252.1.10
sw-spine01(config)# ntp server 10.252.1.11
sw-spine01(config)# ntp server 10.252.1.12
```


