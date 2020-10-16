# Manual Step 1: Interfaces

> If you made `qnd-1.4.sh` you can invoke it in the 1.4 context to prepare the install env.

```bash
spit:~ # source /var/www/ephemeral/qnd-1.4.sh
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

> Run `hostname`.   If you don't see the system name (e.g. fanta) in the hostname, run `sic-setup-lan0.sh` again.
This will be fixed in [MTL-1200](https://connect.us.cray.com/jira/browse/MTL-1200).

## Setup the Non-Compute Bond

Then continue running the scripts that follow to set up the rest of the networking.  Setup the bond for talking to the full system, leverage link-resilience.  

Internal, access to the Cray High-Performance Computer.

Note, you must choose which interfaces to use for members in the
LACP Link Aggregation.


```bash
spit:~ # /root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0 $bond_member1
# If you have only one nic for the bond, then use this instead:
spit:~ # /root/bin/sic-setup-bond0.sh $mtl_cidr $bond_member0
```

# Log in now with SSH

If you were on the Serial-over-LAN, now is a good time to log back in with SSH.  

> If you do log in with SSH, make you `source /var/www/ephemeral/qnd-1.4.sh` again since you're logged in in a new session now.

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
spit:~ # /root/bin/sic-pxe-vlan007.sh $can_gw $can_dhcp_start $can_dhcp_end $dhcp_ttl
```

and netbooting...the example values are for EXAMPLE
only.

> NOTE: The NCN hosts added to /etc/hosts is only necessary to workaround MTL-1199 until that is fixed.

```bash
cp /var/www/ephemeral/statics.conf /etc/dnsmasq.d/
systemctl restart dnsmasq
cat /var/www/ephemeral/ncn-hosts >> /etc/hosts
```

## STOP :: Validate the LiveCD platform.

Now verify service health:
- dnsmasq, basecamp, and nexus should report HEALTHY and running.
- No podman container(s) should be dead.

```bash
spit:~ # systemctl status basecamp dnsmasq nexus
spit:~ # podman container ls -a
```

> - If basecamp is dead, restart it with `systemctl restart basecamp`.
> - If dnsmasq is dead, restart it with `systemctl restart basecamp`.
> - If nexus is dead, restart it with `systemctl restart nexus`.

Now you can start **Booting NCNs** [007-LIVECD-NCN-BOOTS.md](007-LIVECD-NCN-BOOTS.md)
