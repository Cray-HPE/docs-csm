# VLAN Interface

The switch also supports classic L3 VLAN interfaces.

## Configuration Commands

Configure the VLAN:

```text
switch(config)# vlan VLAN
```

Create and enable the VLAN interface, and assign it an IP address:

```text
switch(config)# interface vlan VLAN
switch(config-if-vlan)# ip address IP-ADDR/SUBNET
switch(config-if-vlan)# no shutdown
```

Show commands to validate functionality:

```text
switch# show vlan [VLAN|interface IFACE|summary]
```

## Example Output

```text
switch(config)# vlan 10
switch(config-vlan)# exit
switch(config)# int 1/1/1
switch(config-if)# vlan access 10
switch(config-if)# int vlan 10
switch(config-if-vlan)# ip address 10.0.0.1/24
switch(config-if-vlan)# no shutdown
switch(config-if-vlan)# end
108 bytes from 10.0.0.101: icmp_seq=4 ttl=64 time=2.07 ms
108 bytes from 10.0.0.101: icmp_seq=5 ttl=64 time=1.79 ms
```

## Expected Results

1. Administrators can configure the VLAN
2. Administrators can enable the interface and associate it with the VLAN
3. Administrators can create an IP-enabled VLAN interface, and it is up
4. Administrators validate the configuration is correct
5. Administrators can ping from the switch to the client and from the client to the switch

[Back to Index](../index.md)