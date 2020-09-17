# Interfaces

Setting up the NICS requires two things:
1. Network information (manual now, automated by 1.4)
2. A terminal to the system (ncn-w001, or ncn-m001)

Follow this process to setup external access and netbooting...the example values are for EXAMPLE
only.

## 1.3.X Testing

If you made `qnd-1.4.sh` you can run that now to fill-in all of the required variables
for setting up interfaces.

```shell script
# Note this may be different then the previous device you mounted on the 1.3 system
spit:~ # mount /dev/sdb4 /mnt
spit:~ # source /mnt/qnd-1.4.sh
spit:~ # env
```

> Note: you will need to fetch your external interface information from somewhere else.

## Site-link (worker nodes, or managers for v3 networking)

External, direct access.

```shell script
# These may have already been defined if you made them as part of the previous doc
# Example below uses loki-ncn-m001.
/root/bin/sic-setup-lan0.sh $site_cidr $site_gw $site_dns $site_nic
```

Note: If you were on the Serial-over-LAN, now is a good time to log back in with SSH.
Setup the bond for talking to the full system, leverage link-resilience.

## Non-Compute Bond

Internal, access to the Cray High-Performance Computer.

Note, you must choose which interfaces to use for members in the
LACP Link Aggregation.


```shell script
/root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0 $bond_member1
# If you have only one nic for the bond, then use this instead:
/root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0
```

## VLANS

#### Node management

This subnet handles discovering any trunked nodes (such as NCNs)
and devices on unconfigured switchports (new switches, or factory reset).

```shell script
/root/bin/sic-setup-vlan002.sh $nmn_cidr
```

#### Hardware management

This subnet handles hardware control, and communication. It is the primary
network for talking to and powering on other nodes during bootstrap.

```shell script
/root/bin/sic-setup-vlan004.sh $hmn_cidr
```

#### Customer Access

This subnet handles customer access to nodes and services as well as access to outside services from inside the cluster. It is the primary
network for talking to UANs and NCNs from outside the cluster and access services in the cluster.

```shell script
/root/bin/sic-setup-vlan007.sh $can_cidr
```

## STOP :: Validate the LiveCD platform.

Check that IPs are set for each interface:

```shell script
ip a show lan0
ip a show bond0
ip a show vlan002
ip a show vlan004
ip a show vlan007
```

# Services

Support netbooting for trunked devices (non-compute nodes and UANs):

If you made `qnd-1.4.sh` you can run that now to fill-in all of the required variables
for setting up service, or they may have already been added in a previous step.ß

```shell script
dhcp_ttl=10m
/root/bin/sic-pxe-bond0.sh $mtl_cidr $mtl_dhcp_start $mtl_dhcp_end $dhcp_ttl
```

Support node networking, serve DHCP/DNS/NTP over the NMN:

```shell script
dhcp_ttl=10m
/root/bin/sic-pxe-vlan002.sh $nmn_cidr $nmn_dhcp_start $nmn_dhcp_end $dhcp_ttl
```

Support hardware controllers, serve DHCP/DNS/NTP over the HMN:

```shell script
dhcp_ttl=10m
/root/bin/sic-pxe-vlan004.sh $hmn_cidr $hmn_dhcp_start $hmn_dhcp_end $dhcp_ttl
```

Support customer access network interfaces:

You may have already added this to `qnd-1.4.sh` from an earlier doc.
```shell script
can_gw=10.102.9.111
can_dhcp_start=10.102.9.4
can_dhcp_end=10.102.9.109
dhcp_ttl=10m
/root/bin/sic-pxe-vlan007.sh $can_cidr $can_dhcp_start $can_dhcp_end $dhcp_ttl
```

## STOP :: Validate the LiveCD platform.

Now verify service health:
- both dnsmasq and podman should report HEALTHY and running.
- No container(s) should be dead.
```shell script
systemctl status dnsmasq
systemctl status basecamp
podman container ls -a
```

> If basecamp is dead, restart it with `systemctl restart basecamp`.

Now you can start **Booting NCNs** [12-LIVECD-NCN-BOOTS.md](12-LIVECD-NCN-BOOTS.md)
