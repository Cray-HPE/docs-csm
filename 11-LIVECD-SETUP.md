# Interfaces

Setting up the NICS requires two things:
1. Network information (manual now, automated by 1.4)
2. A terminal to the system (ncn-w001, or ncn-m001)

Follow this process to setup external access and netbooting...the example values are for EXAMPLE
only.

## Site-link (worker nodes, or managers for v3 networking)

External, direct access.

```bash
cidr=172.30.53.68/20 
gw=172.30.48.1
dns='172.30.84.40 172.31.84.40'
nic=eth0
/root/bin/sic-setup-lan0.sh $cidr $gw $dns $nic
```

Note: If you were on the Serial-over-LAN, now is a good time to log back in with SSH.
Setup the bond for talking to the full system, leverage link-resilience.

## Non-Compute Bond

Internal, access to the Cray High-Performance Computer.

Note, you must choose which interfaces to use for members in the 
LACP Link Aggregation. 

> If you're coming from 1.3, these would be the same as 
> `lan1` and `lan3` in the `platform.yml` file.

```bash
cidr=10.1.1.1/16
mem1=eth4
mem2=eth1
/root/bin/sic-setup-bond0.sh $cidr $mem1 $mem2
# If you have only one nic for the bond, then use this instead:
/root/bin/sic-setup-bond0.sh $cidr $mem1
```

## VLANS

#### Node management

This subnet handles discovering any trunked nodes (such as NCNs) 
and devices on unconfigured switchports (new switches, or factory reset).

```bash
cidr=10.252.1.1/17
/root/bin/sic-setup-vlan002.sh $cidr
```

#### Hardware management

This subnet handles hardware control, and communication. It is the primary
network for talking to and powering on other nodes during bootstrap.

```bash
cidr=10.254.1.1/17
/root/bin/sic-setup-vlan004.sh $cidr
```

## STOP :: Validate the LiveCD platform.

Check that IPs are set for each interface:

```bash
spit:~ # ip a show lan0
spit:~ # ip a show bond0
spit:~ # ip a show vlan002
spit:~ # ip a show vlan004
```

# Services

Support netbooting for trunked devices (non-compute nodes and UANs):

```bash
cidr=10.1.1.1/16
dhcp_start=10.1.2.1
dhcp_end=10.1.255.254
dhcp_ttl=10m
/root/bin/sic-pxe-bond0.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
```

Support node networking, serve DHCP/DNS/NTP over the NMN:

```bash
cidr=10.252.1.1/16
dhcp_start=10.252.2.1
dhcp_end=10.252.127.254
dhcp_ttl=10m
/root/bin/sic-pxe-vlan002.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
```

Support hardware controllers, serve DHCP/DNS/NTP over the HMN:

```bash
cidr=10.254.1.1/16
dhcp_start=10.254.2.1
dhcp_end=10.254.127.254
dhcp_ttl=10m
/root/bin/sic-pxe-vlan004.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
```

## STOP :: Validate the LiveCD platform.

Now verify service health:
- both dnsmasq and podman should report HEALTHY and running.
- No container(s) should be dead.
```bash
spit:~ # systemctl status dnsmasq
spit:~ # systemctl status basecamp
spit:~ # podman container ls -a
```
If basecamp is dead, restart it with `systemctl restart basecamp`.