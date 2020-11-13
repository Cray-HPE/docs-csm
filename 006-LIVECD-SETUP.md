# Manual Step 1: Interfaces

> Source qnd-1.4.sh to prepare the install env.

```bash
pit:~ # source /var/www/ephemeral/qnd-1.4.sh
pit:~ # env
```

> Note: you will need to fetch your external interface information from somewhere else.

## Setup the Site-link (worker nodes, or managers for v3 networking)

External, direct access.

```bash
# These may have already been defined if you made them as part of the previous doc
/root/bin/csi-setup-lan0.sh $site_cidr $site_gw $site_dns $site_nic
```

> Run `hostname`.   If you don't see the system name (e.g. fanta) in the hostname, run `csi-setup-lan0.sh` again.
This will be fixed in [CASMINST-111](https://connect.us.cray.com/jira/browse/CASMINST-111).

## Setup the Non-Compute Bond

Then continue running the scripts that follow to set up the rest of the networking.  Setup the bond for talking to the full system, leverage link-resilience.  

Internal, access to the Cray High-Performance Computer.

Note, you must choose which interfaces to use for members in the
LACP Link Aggregation.


```bash
pit:~ # /root/bin/csi-setup-bond0.sh $mtl_cidr $bond_member0 $bond_member1
# If you have only one nic for the bond, then use this instead:
pit:~ # /root/bin/csi-setup-bond0.sh $mtl_cidr $bond_member0
```

# Log in now with SSH

If you were on the Serial-over-LAN, now is a good time to log back in with SSH.  

> If you do log in with SSH, make you `source /var/www/ephemeral/qnd-1.4.sh` again since you're logged in in a new session now.

## Setup the VLANS

#### Node management VLAN

This subnet handles discovering any trunked nodes (such as NCNs)
and devices on unconfigured switchports (new switches, or factory reset).

```bash
pit:~ # /root/bin/csi-setup-vlan002.sh $nmn_cidr
```

#### Hardware management VLAN

This subnet handles hardware control, and communication. It is the primary
network for talking to and powering on other nodes during bootstrap.

```bash
pit:~ # /root/bin/csi-setup-vlan004.sh $hmn_cidr
```

#### Customer Access VLAN

This subnet handles customer access to nodes and services as well as access to outside services from inside the cluster. It is the primary
network for talking to NCNs from outside the cluster and access services in the cluster.

```bash
pit:~ # /root/bin/csi-setup-vlan007.sh $can_cidr
```

## Manual Check 1 :: STOP :: Validate the LiveCD platform.

Check that IPs are set for each interface:

```bash
csi pit validate --network true
```

# Manual Step 2: Services

Copy the config files generated earlier by `csi config init` into /etc/dnsmasq.d and /etc/conman.conf.
```bash
cp /var/www/ephemeral/${system-name}/dnsmasq.d/* /etc/dnsmasq.d
cp /var/www/ephemeral/${system-name}/conman.conf /etc/conman.conf
systemctl restart dnsmasq
systemctl restart conman
```

## Manual Check 2 :: STOP :: Validate the Services

Now verify service health:
- dnsmasq, basecamp, and nexus should report HEALTHY and running.
- No podman container(s) should be dead.

```bash
csi pit validate --services true
```

> - If basecamp is dead, restart it with `systemctl restart basecamp`.
> - If dnsmasq is dead, restart it with `systemctl restart dnsmasq`.
> - If nexus is dead, restart it with `systemctl restart nexus`.

You should see two containers: nexus and basecamp

```
CONTAINER ID  IMAGE                                         COMMAND               CREATED     STATUS         PORTS   NAMES
496a2ce806d8  dtr.dev.cray.com/metal/cloud-basecamp:latest                        4 days ago  Up 4 days ago          basecamp
6fcdf2bfb58f  docker.io/sonatype/nexus3:3.25.0              sh -c ${SONATYPE_...  4 days ago  Up 4 days ago          nexus
```

# Manual Step 3: Access to External Services

To access outside services like Stash or Artifactory, we need to set up /etc/resolv.conf.  Make sure the /etc/resolv.conf includes the site DNS servers at the end of the file.

```bash
nameserver 172.30.84.40
nameserver 172.31.84.40
```

# Manual Check 3: Verify Outside Name Resolution

You should be able to resolve outside services like arti.dev.cray.com.

```bash
ping arti.dev.cray.com
```

Now you can start **Booting NCNs** [007-LIVECD-NCN-BOOTS.md](007-LIVECD-NCN-BOOTS.md)
