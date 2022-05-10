# Apply Custom Switch Configurations for CSM 1.0

Apply the backed up site connection configuration with a couple modifications. Since virtual routing and forwarding (VRF) is now used to separate customer traffic, the site ports and default routes must be added to that VRF.

## Prerequisites

* Access to the switches
* Custom switch configurations
  * [Backup Custom Configurations](backup_custom_config.md)
* Generated switch configurations already applied
  * [Apply Switch Configurations](apply_switch_configs.md)

## Aruba

```text
sw-spine-001# conf t
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```text
sw-spine-001# conf t
sw-spine-001(config)# system interface-group 3 speed 10g
```

```text
sw-spine-002# conf t
interface 1/1/36
    no shutdown
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

If the switch had `system interface-group` commands those would be added here.

```text
sw-spine-001(config)# system interface-group 3 speed 10g
```

```text
sw-spine-001# conf t
sw-spine-001(config)# ip route 0.0.0.0/0 10.101.15.141 vrf default
```

```text
sw-spine-002# conf t
sw-spine-002(config)# ip route 0.0.0.0/0 10.101.15.189 vrf default
```

## Mellanox

```text
sw-spine-001 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```text
sw-spine-002 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

```text
sw-spine-001 [mlag-domain: master] # conf t
   ip route vrf default 0.0.0.0/0 10.102.255.9
```

```text
sw-spine-002 [mlag-domain: master] # conf t
   ip route vrf default 0.0.0.0/0 10.102.255.85
```

## Apply Users/Password

All that is required to re-apply the users is to get into global configuration mode with `conf t` and to paste in the configuration that was copied from the previous step.

### Aruba Credentials

```text
sw-leaf-bmc-001# conf t
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Dell Credentials

```text
sw-leaf-001# conf t
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

### Mellanox Credentials

```text
sw-spine-001 [standalone: master] # conf t
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Write memory

Save the configuration once the configuration is applied. See [Saving Configuration](saving_config.md).
