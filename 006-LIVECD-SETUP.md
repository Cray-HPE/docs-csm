# Manual Step 1: Interfaces

Setting up the NICS requires two things:
1. Network information (manual now, automated by 1.4)
2. A terminal to the system (ncn-w001, or ncn-m001)

Follow this process to setup external access and netbooting...the example values are for EXAMPLE
only.

### 1.3.X Testing

If you made `qnd-1.4.sh` you can run that now to fill-in all of the required variables
for setting up interfaces.

```bash
# Note this may be different then the previous device you mounted on the 1.3 system
spit:~ # mount /dev/sdb4 /mnt
spit:~ # source /mnt/qnd-1.4.sh
spit:~ # env
```

> Note: you will need to fetch your external interface information from somewhere else.

## Setup the Site-link (worker nodes, or managers for v3 networking)

External, direct access.

```bash
# These may have already been defined if you made them as part of the previous doc
# Example below uses loki-ncn-m001.
/root/bin/sic-setup-lan0.sh $site_cidr $site_gw $site_dns $site_nic
```

Note: If you were on the Serial-over-LAN, now is a good time to log back in with SSH.
Setup the bond for talking to the full system, leverage link-resilience.

## Setup the Non-Compute Bond

Internal, access to the Cray High-Performance Computer.

Note, you must choose which interfaces to use for members in the
LACP Link Aggregation.


```bash
spit:~ # /root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0 $bond_member1
# If you have only one nic for the bond, then use this instead:
spit:~ # /root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0
```

## Setup the VLANS

#### Node management VLAN

This subnet handles discovering any trunked nodes (such as NCNs)
and devices on unconfigured switchports (new switches, or factory reset).

```bash
spit:~ # /root/bin/sic-setup-vlan002.sh $nmn_cidr
```

#### Hardware management VLAN

This subnet handles hardware control, and communication. It is the primary
network for talking to and powering on other nodes during bootstrap.

```bash
spit:~ # /root/bin/sic-setup-vlan004.sh $hmn_cidr
```

#### Customer Access VLAN

This subnet handles customer access to nodes and services as well as access to outside services from inside the cluster. It is the primary
network for talking to UANs and NCNs from outside the cluster and access services in the cluster.

```bash
spit:~ # /root/bin/sic-setup-vlan007.sh $can_cidr
```

## Manual Check 1 :: STOP :: Validate the LiveCD platform.

Check that IPs are set for each interface:

```bash
spit:~ # ip a show lan0
spit:~ # ip a show bond0
spit:~ # ip a show vlan002
spit:~ # ip a show vlan004
spit:~ # ip a show vlan007
```

# Manual Step 2: Services

Support netbooting for trunked devices (non-compute nodes and UANs):

> Note: If you made `qnd-1.4.sh` you can run that now to fill-in all of the required variables
> for setting up service, or they may have already been added in a previous step.

```bash
spit:~ # /root/bin/sic-pxe-bond0.sh $mtl_cidr $mtl_dhcp_start $mtl_dhcp_end $dhcp_ttl
```

Support node networking, serve DHCP/DNS/NTP over the NMN:

```bash
spit:~ # /root/bin/sic-pxe-vlan002.sh $nmn_cidr $nmn_dhcp_start $nmn_dhcp_end $dhcp_ttl
```

Support hardware controllers, serve DHCP/DNS/NTP over the HMN:

```bash
spit:~ # /root/bin/sic-pxe-vlan004.sh $hmn_cidr $hmn_dhcp_start $hmn_dhcp_end $dhcp_ttl
```

Support customer access network interfaces:

You may have already added this to `qnd-1.4.sh` from an earlier doc.
```bash
spit:~ # /root/bin/sic-pxe-vlan007.sh $can_cidr $can_dhcp_start $can_dhcp_end $dhcp_ttl
```

## STOP :: Validate the LiveCD platform.

Now verify service health:
- both dnsmasq and podman should report HEALTHY and running.
- No container(s) should be dead.

```bash
spit:~ # systemctl status basecamp dnsmasq nexus
spit:~ # podman container ls -a
```

> - If basecamp is dead, restart it with `systemctl restart basecamp`.
> - If dnsmasq is dead, restart it with `systemctl restart basecamp`.
> - If nexus is dead, restart it with `systemctl restart nexus`.

Now you can start **Booting NCNs** [007-LIVECD-NCN-BOOTS.md](007-LIVECD-NCN-BOOTS.md)
