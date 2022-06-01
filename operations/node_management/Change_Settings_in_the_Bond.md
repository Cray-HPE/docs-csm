# Change Settings in the Bond

iPXE is used to setup `udev` rules for interface names and bond members. The configuration of these are dynamic on boot until node customization runs (`cloud-init`) and sets up the
conventional `/etc/sysconfig/network/ifcfg-bond0` and other neighboring files.

The initial settings of the bonds can be changed directly in the LiveCD or with the Boot Script Service (BSS). When cabling is different than normal, there is flexibility for
customizing bond links.

Customize the settings of the bonds.

For more information, refer to the following lines of the `script.ipxe` file:

```bash
# Assign bonds.
iseq ${dual-bond} 1 && set net-udev-params ${net-udev-params} ${net-hsn-udev-params} ${net-lan-udev-params} ${net-mgmt-udev-params} ${net-sun-udev-params} || set net-udev-params ${net-udev-params} ${net-hsn-udev-params} ${net-lan-udev-params} ${net-mgmt-udev-params} ${net-mgmt-single-bond-udev-params}
iseq ${dual-bond} 1 && echo Dual-Bond mode: Enabled (mgmt and sun NICs) || echo Dual-Bond mode: Disabled (mgmt NICs only)
```

These are available on the PIT node at `/var/www/ncn-*/script.ipxe`, and the master script is available
at `/var/www/boot/script.ipxe`. Administrators may apply this to each NCN or the master script. If applied to the master script, then the following
procedure will apply that master script to all NCNs:

> `read -s` is used to prevent the password from being written to the screen or the shell history.

```bash
pit# read -s IPMI_PASSWORD
pit# export IPMI_PASSWORD
pit# /root/bin/set-sqfs-links.sh
```

Use one of the following options depending on the number of bonds formed:

* When one bond is formed:

   ```bash
   bond=bond0:mgmt0,mgmt2:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000 || set net-bond-params bond=bond0:mgmt0,mgmt1:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000 hwprobe=+200:*:*:bond0
   ```

* When two bonds are formed:

   ```bash
   bond=bond0:mgmt0,mgmt2:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000 hwprobe=+200:*:*:bond0 bond=bond1:mgmt1,mgmt3:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000 hwprobe=+200:*:*:bond1 ip=bond1:auto6
   ```
