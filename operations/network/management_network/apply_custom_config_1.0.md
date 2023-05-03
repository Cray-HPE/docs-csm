# Apply Custom Switch Configurations for CSM 1.0

Apply the backed up site connection configuration with a couple modifications. Since virtual routing and forwarding (VRF) is now used to separate customer traffic, the site ports and default routes must be added to that VRF.

## Prerequisites

* Access to the switches
* Custom switch configurations
  * [Backup Custom Configurations](backup_custom_configurations.md)
* Generated switch configurations already applied
  * [Apply Switch Configurations](apply_switch_configurations.md)

## Aruba Apply Configurations

```console
conf t
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```console
conf t
sw-spine-001(config)# system interface-group 3 speed 10g
```

```console
conf t
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

If the switch had `system interface-group` commands those would be added here.

```console
sw-spine-001(config)# system interface-group 3 speed 10g
```

```console
conf t
sw-spine-001(config)# ip route 0.0.0.0/0 10.101.15.141 vrf default
```

```console
conf t
sw-spine-002(config)# ip route 0.0.0.0/0 10.101.15.189 vrf default
```

## Mellanox Apply Configurations

```console
sw-spine-001 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```console
sw-spine-002 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

```console
sw-spine-001 [mlag-domain: master] # conf t
   ip route vrf default 0.0.0.0/0 10.102.255.9
```

```console
sw-spine-002 [mlag-domain: master] # conf t
   ip route vrf default 0.0.0.0/0 10.102.255.85
```

## Apply Users/Password

All that is required to re-apply the users is to get into global configuration mode with `conf t` and to paste in the configuration that was copied from the previous step.

### Aruba credentials

```console
conf t
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Dell Credentials

```console
conf t
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

### Mellanox credentials

```console
sw-spine-001 [standalone: master] # conf t
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Apply SNMP credentials

### Dell SNMP

```console
conf t
   snmp-server group cray-reds-group 3 noauth read cray-reds-view
   snmp-server user testuser cray-reds-group 3 auth md5 xxxxxxxx priv des xxxxxxx
   snmp-server view cray-reds-view 1.3.6.1.2 included
```

### Aruba SNMP

```console
conf t
   snmp-server vrf default
   snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
```

For more information on SNMP credentials, see [Configuring SNMP in CSM](configure_snmp.md) and [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../../../operations/security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md)

## Write memory

Save the configuration once the configuration is applied. See [Saving Configuration](saving_config.md).
