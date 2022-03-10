# Apply Custom Switch Config CSM 1.2

Apply the backed up site connection configuration with a couple modifications. Since virtual routing and forwarding (VRF) is now used to separate customer traffic, the site ports and default routes must be added to that VRF.

#### Prerequisites 

- Access to the switches
- Custom Switch configs
    - [Backup Custom Config](backup_custom_config.md)
- Generated switch configs already applied
    - [apply switch configs](apply_switch_configs.md)


##### Aruba

- `vrf attach Customer` will be added to the port configuration that connects to the site.
- This has to be applied before the `ip address` configuration.

```
sw-spine-001# conf t
interface 1/1/36 
    no shutdown
    vrf attach Customer 
    description to:CANswitch_cfcanb6s1-31:from:sw-25g01_x3000u39-j36
    ip address 10.101.15.142/30
    exit
```

```
sw-spine-001# conf t
sw-spine-001(config)# system interface-group 3 speed 10g
```

```
sw-spine-002# conf t
interface 1/1/36 
    no shutdown 
    vrf attach Customer
    description to:CANswitch_cfcanb6s1-46:from:sw-25g02_x3000u40-j36
    ip address 10.101.15.190/30
    exit
```

If the switch had `system interface-group` commands those would be added here.

```
sw-spine-001(config)# system interface-group 3 speed 10g
```

`vrf Customer` will be appended to the default route configuration.

```
sw-spine-001# conf t
sw-spine-001(config)# ip route 0.0.0.0/0 10.101.15.141 vrf Customer
```

```
sw-spine-002# conf t
sw-spine-002(config)# ip route 0.0.0.0/0 10.101.15.189 vrf Customer
```

##### Mellanox

- `vrf forwarding Customer` will be added to the port config.  
- This has to be applied before the `ip address` configuration.

```
sw-spine-001 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 vrf forwarding Customer
interface ethernet 1/16 ip address 10.102.255.10/30 primary
```

```
sw-spine-002 [mlag-domain: master] # conf t
interface ethernet 1/16 speed 10G force
interface ethernet 1/16 mtu 1500 force
interface ethernet 1/16 no switchport force
interface ethernet 1/16 vrf forwarding Customer
interface ethernet 1/16 ip address 10.102.255.86/30 primary
```

`vrf Customer` will replace `vrf default`

```
sw-spine-001 [mlag-domain: master] # conf t
   ip route vrf Customer 0.0.0.0/0 10.102.255.9
```

```
sw-spine-002 [mlag-domain: master] # conf t
   ip route vrf Customer 0.0.0.0/0 10.102.255.85
```

#### Apply users/password

All that is required to re-apply the users is get into global configuration mode `conf t` and paste in the config that was copied from the previous step.
 
##### Aruba

```
sw-leaf-bmc-001# conf t
user admin group administrators password ciphertext xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

##### Dell

```
sw-leaf-001# conf t
system-user linuxadmin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
username admin password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx role sysadmin priv-lvl 15
```

##### Mellanox

```
sw-spine-001 [standalone: master] # conf t
   username admin password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   username monitor password 7 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Write memory

- Save the configuration once the configuration is applied.
  - [Saving Config](saving_config.md)
