# Apply Custom Switch Config CSM 1.2

Apply the backed up site connection configuration with a couple modifications. Since virtual routing and forwarding (VRF) is now used to separate customer traffic, the site ports and default routes must be added to that VRF.

## Prerequisites

- Access to the switches
- Custom switch configurations
  - [Backup Custom Config](backup_custom_config.md)

- Generated switch configurations already applied
  - [Apply Switch Configs](apply_switch_configs.md)

## Aruba

`vrf attach Customer` will be added to the port configuration that connects to the site. This has to be applied before the `ip address` configuration.

```bash
sw-spine-001# conf t
interface 1/1/36
    no shutdown
    vrf attach Customer
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```bash
sw-spine-001# conf t
sw-spine-001(config)# system interface-group 3 speed 10g
```

```bash
sw-spine-002# conf t
interface 1/1/36
    no shutdown
    vrf attach Customer
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

If the switch had `system interface-group` commands those would be added here.

```bash
sw-spine-001(config)# system interface-group 3 speed 10g
```

`vrf Customer` will be appended to the default route configuration.

```bash
sw-spine-001# conf t
sw-spine-001(config)# ip route 0.0.0.0/0 10.101.15.141 vrf Customer
```

```bash
sw-spine-002# conf t
sw-spine-002(config)# ip route 0.0.0.0/0 10.101.15.189 vrf Customer
```

## Mellanox

`vrf forwarding Customer` will be added to the port config. This has to be applied before the `ip address` configuration.

```bash
sw-spine-001 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 vrf forwarding Customer
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```bash
sw-spine-002 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 vrf forwarding Customer
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

`vrf Customer` will replace `vrf default`

```bash
sw-spine-001 [mlag-domain: master] # conf t
   ip route vrf Customer 0.0.0.0/0 10.102.255.9
```

```bash
sw-spine-002 [mlag-domain: master] # conf t
   ip route vrf Customer 0.0.0.0/0 10.102.255.85
```

## Apply users/password

All that is required to re-apply the users is to get into the global configuration mode using `conf t` and paste in the configuration that was copied from the previous step.

### Aruba Credentials

```bash
sw-leaf-bmc-001# conf t
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Dell Credentials

```bash
sw-leaf-001# conf t
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

### Mellanox

```bash
sw-spine-001 [standalone: master] # conf t
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Apply SNMP credentials

### Dell SNMP

```bash
sw-leaf-bmc-001# conf t
   snmp-server group cray-reds-group 3 noauth read cray-reds-view
   snmp-server user testuser cray-reds-group 3 auth md5 xxxxxxxx priv des xxxxxxx
   snmp-server view cray-reds-view 1.3.6.1.2 included
```

### Aruba SNMP

```bash
sw-leaf-bmc-001# conf t
   snmp-server vrf default
   snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
```

For more information on SNMP credentials, see [Change SNMP Credentials on Leaf-BMC Switches](../../../operations/security_and_authentication/Change_SNMP_Credentials_on_Leaf_BMC_Switches.md) & [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../../../operations/security_and_authentication/Change_SNMP_Credentials_on_Leaf_BMC_Switches.md)

## Write memory

Save the configuration once the configuration is applied. See [Saving Config](saving_config.md).
