# Backup a Custom Configuration

## Prerequisites

- Access to the switches.

If your doing a fresh install of CSM but previously had a different version of CSM installed you will need to backup/restore certain switch config after the switch has been wiped.

This needs to be done before wiping the switch.

This includes:

- users and passwords
- snmp credentials
- site connections
- interface speed commands
- default routes
- any other customized config for this system

This configuration will likely vary from site to site. This guide will cover the most common site setup.

### Backup site connection configuration

You can find the site connections on the SHCD.

```
CAN switch	cfcanb6s1	 	 	-	31	sw-25g01	x3000	u39	-	j36
CAN switch	cfcanb6s1	 	 	-	46	sw-25g02	x3000	u40	-	j36
```

With this info we know that we need to back the config on port 36 on both spine switches.

log onto the switches and get the configs of the ports and the default route config. Save this output, this will be used after we apply the generated configs.

#### Aruba

```
sw-spine-001# show run int 1/1/36
interface 1/1/36 
    no shutdown 
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```
sw-spine-001(config)# show run | include interface-group
system interface-group 3 speed 10g
```

```
sw-spine-002# show run int 1/1/36
interface 1/1/36 
    no shutdown 
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

```
sw-spine-002(config)# show run | include interface-group
system interface-group 3 speed 10g
```

```
sw-spine-001# show run | include "ip route"
ip route 0.0.0.0/0 10.101.15.141
```

```
sw-spine-002# show run | include "ip route"
ip route 0.0.0.0/0 10.101.15.189
```

### Mellanox

```
sw-spine-001 [mlag-domain: master] # show run int ethernet 1/16
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```
sw-spine-002 [mlag-domain: master] # show run int ethernet 1/16
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

```
sw-spine-001 [mlag-domain: master] # show run | include "ip route"
   ip route 0.0.0.0/0 10.102.3.3 5
   ip route 0.0.0.0/0 10.102.255.9
```

```
sw-spine-002 [mlag-domain: master] # show run | include "ip route"
   ip route 0.0.0.0/0 10.102.3.2 5
   ip route 0.0.0.0/0 10.102.255.85
```

### Backup users/password

#### Aruba

```
sw-leaf-bmc-001# show run | include user
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

##### Dell

```
sw-leaf-001# show running-configuration | grep user
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

##### Mellanox

```
sw-spine-001 [standalone: master] # show run | include username
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

#### Backup SNMP credentials

SNMP is currently only used on sw-leaf-bmc switches, these credentials can be retrieved from vault. More info on SNMP creds can be found on the [Change SNMP Credentials on Leaf Switches](../../../operations/security_and_authentication/Change_SNMP_Credentials_on_Leaf_Switches.md) page.

Once these credentials are retrieved from Vault you can fill in the `xxxxxx` fields below.

##### Aruba

```
sw-leaf-001# show run | include snmp
snmp-server vrf default
snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxxx
 ```

##### Dell

```
sw-leaf-001# show running-configuration | include snmp
snmp-server group cray-reds-group 3 noauth read cray-reds-view
snmp-server user xxxxxx cray-reds-group 3 auth md5 xxxxxx priv des xxxxxx
snmp-server view cray-reds-view 1.3.6.1.2 included
 ```
