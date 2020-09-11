# Interfaces

Setting up the NICS requires two things:
1. Network information (manual now, automated by 1.4)
2. A terminal to the system (ncn-w001, or ncn-m001)

Follow this process to setup external access and netbooting...the example values are for EXAMPLE
only.

```bash
# Setup external access:
cidr=172.30.53.68/20 
gw=172.30.48.1
dns='172.30.84.40 172.31.84.40'
nic=eth0
/root/bin/sic-setup-lan0.sh $cidr $gw $dns $nic

# If you were on the Serial-over-LAN, now is a good time to log back in with SSH.
# Setup the bond for talking to the full system, leverage link-resilience.
cidr=10.1.1.1/16
mem1=eth4
mem2=eth1
/root/bin/sic-setup-bond0.sh $cidr $mem1 $mem2
# If you have only one nic for the bond, then use this instead:
/root/bin/sic-setup-bond0.sh $cidr $mem1
# Setup the NMN:
cidr=10.252.1.1/17
/root/bin/sic-setup-vlan002.sh $cidr
# Setup the HMN:
cidr=10.254.1.1/17
/root/bin/sic-setup-vlan004.sh $cidr
```

Now Setup services:
```bash
cidr=10.1.1.1/16
dhcp_start=10.1.2.1
dhcp_end=10.1.255.254
dhcp_ttl=10m
/root/bin/sic-pxe-bond0.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
cidr=10.252.1.1/16
dhcp_start=10.252.2.1
dhcp_end=10.252.127.254
dhcp_ttl=10m
/root/bin/sic-pxe-vlan002.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
cidr=10.254.1.1/16
dhcp_start=10.254.2.1
dhcp_end=10.254.127.254
dhcp_ttl=10m
/root/bin/sic-pxe-vlan004.sh $cidr $dhcp_start $dhcp_end $dhcp_ttl
```

Now verify service health:
```bash
# both dnsmasq and podman should report HEALTHY and running.
systemctl status dnsmasq
systemctl status podman
# No containers should be dead.
podman container ls -a
```
