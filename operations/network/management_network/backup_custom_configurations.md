# Backup a Custom Configuration

## Prerequisites

- Access to the switches.

If you are doing a fresh install of CSM but previously had a different version of CSM installed, then you will need to backup/restore certain switch configurations after the switch has been wiped.

The backup needs to be done before wiping the switch.

This includes:

- Users and passwords
- SNMP credentials
- Site connections
- Interface speed commands
- Default routes
- Any other customized configuration for this system

This configuration will likely vary from site to site. This guide will cover the most common site setup.

## Backup site connection configuration

You can find the site connections in the SHCD file.

```console
CAN switch  cfcanb6s1         -  31 sw-25g01 x3000 u39   -  j36
CAN switch  cfcanb6s1         -  46 sw-25g02 x3000 u40   -  j36
```

With this information we know that we need to backup the configuration on port 36 on both spine switches.

Log into the switches. Get the configurations of the ports and the default route. Save this output; this will be used after we apply the generated configurations.

### Aruba site connection

```console
show run int 1/1/36
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```console
sw-spine-001(config)# show run | include interface-group
system interface-group 3 speed 10g
```

```console
show run int 1/1/36
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

```console
sw-spine-002(config)# show run | include interface-group
system interface-group 3 speed 10g
```

```console
show run | include "ip route"
ip route 0.0.0.0/0 10.101.15.141
```

```console
show run | include "ip route"
ip route 0.0.0.0/0 10.101.15.189
```

### Mellanox site connection

```console
sw-spine-001 [mlag-domain: master] # show run int ethernet 1/16
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```console
sw-spine-002 [mlag-domain: master] # show run int ethernet 1/16
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

```console
sw-spine-001 [mlag-domain: master] # show run | include "ip route"
   ip route 0.0.0.0/0 10.102.3.3 5
   ip route 0.0.0.0/0 10.102.255.9
```

```console
sw-spine-002 [mlag-domain: master] # show run | include "ip route"
   ip route 0.0.0.0/0 10.102.3.2 5
   ip route 0.0.0.0/0 10.102.255.85
```

## Backup users/passwords

### Aruba users/passwords

```console
show run | include user
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Dell users/passwords

```console
show running-configuration | grep user
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

### Mellanox users and passwords

```console
sw-spine-001 [standalone: master] # show run | include username
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Backup SNMP credentials

For more information on SNMP credentials, see [Configuring SNMP in CSM](configure_snmp.md) and [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../../../operations/security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md)

Once these credentials are retrieved from Vault, the `xxxxxx` fields below can be filled in.

### Aruba SNMP

```console
show run | include snmp
snmp-server vrf default
snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxxx
```

### Dell SNMP

```console
show running-configuration | grep snmp
snmp-server group cray-reds-group 3 noauth read cray-reds-view
snmp-server user xxxxxx cray-reds-group 3 auth md5 xxxxxx priv des xxxxxx
snmp-server view cray-reds-view 1.3.6.1.2 included
```

### Mellanox SNMP

```console
sw-spine-001 [mlag-domain: standby] # show running-config | include snmp
   snmp-server user testuser v3 capability admin
   snmp-server user testuser v3 enable
   snmp-server user testuser v3 enable sets
   snmp-server user testuser v3 encrypted auth md5 xxxxxx priv des xxxxxx
   snmp-server user testuser v3 require-privacy
```
