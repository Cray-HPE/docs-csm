# Move Site Connections 

In 1.4, the site connections that were previously connection to ncn-w001 will be moved to ncn-m001.  This page will go over the process to make that change.
> Note: In shasta-1.4, any number of managers may have external connections, pre-1.4 was strictly w001(a.k.a. sms01).
1. Make request to DCHW to move the BMC/Host Connections and attach a USB to m001.

   Make sure ncn-w001 is up and accessible via the NMN from ncn-m001.

   Send a request to dchw@hpe.com to request the following changes.

   * Swap mn01 and wn01 cabling. mn01-j1 and mn01-j3 need the external/site-links and both wn01-j1 and wn01-j3 should be wired into the leaf switch.
   * Plug a USB stick (250GB or larger) into mn01. If one is already in wn01 please move it to mn01, otherwise new USBs should have been ordered.  
   * Create DNS records for m001 and its BMC. 
      - `<system-name>-ncn-m001`
      - `<system-name>-ncn-m001-mgmt`

     The old w001 DNS entries should remain/stay to prevent interruptions, if at all possible.

2. Set the new host IP and default route.

    After the above changes have been made, go to the console of ncn-m001 via the new BMC address given by DHCW.  

   ```bash
   username=''
   bmcaddr=''
   export IPMI_PASSWORD=''
   ipmitool -I lanplus -U $username -E -H $bmcaddr sol activate
   ``` 

   Set the new static em1 IP address in `/etc/sysconfig/network/ifcfg-em1`.  Replace `172.30.XX.XX` with the `em1` IP for your system.

   ```bash
   BOOTPROTO='static'
   STARTMODE='auto'
   ONBOOT='yes'
   IPADDR='172.30.XX.XX'
   NETMASK='255.255.240.0'
   ```
 
   Set the default route in `/etc/sysconfig/network/ifroute-em1`.
   ```bash
   default 172.30.48.1 255.255.240.0 em1
   ```
 
   Bring up em1.
   ```bash
   wicked ifdown em1
   wicked ifup em1
   ```

   Confirm that the IP address and default were set.

   ```bash
   ip addr show em1
   ip route | grep default
   ```

   Exit out of the sol console.

   
3. Set w001 BMC to dhcp
 
    DCHW may do this step for you.  If not, do the following after the above changes have been made

    a. SSH from your laptop to ncn-m001 via the new external connection.  

    b. SSH from ncn-m001 to ncn-w001 over the NMN. 

    c. Execute `ipmitool lan print 1` and check to see if `IP Address Source` is set to Static or DHCP.

    d. If it is set to Static, run the command `ipmitool lan set 1 ipsrc dhcp`

    e. Execute `ipmitool lan print 1` to verify that it is now set to DHCP and record if it has picked up an address.  (This will depend on if Kea is still running on the 1.3 system.  If it doesn't have an IP, we can get it later.)



4. Capture bond0 MACs and ncn-w001 BMC MAC

   For 1.4, we need to know the MAC address for the bond0 interface.  We also need to know the BMC and em1 MACs for w001 since that is not capture in ncn_metadata.csv.  You can capture all of this this from ncn-w001 by running the following commands.

   ```bash
   ansible ncn -m shell -a "ip addr show bond0 | grep ether" > /root/macs.txt
   ipmitool lan print 1 | grep "MAC Address" >> /root/macs.txt
   ```
   
    scp this file to ncn-m001.

    ```bash
    scp /root/macs.txt ncn-m001:/root
    ```


5. Log out of ncn-w001.   You should now be back on ncn-m001.


6. Shutdown all of the nodes except for ncn-m001 

    We want to make sure all of the NCNs are shutdown before starting the 1.4 installation to avoid having multiple DHCP servers running.   Because Kea is also serving the BMCs their addresses, we will want to do this all at approximately the same time before they lose their leases.

    Use ipmitool from ncn-m001 to shutdown all of the NCNs other than ncn-m001 and ncn-w001.

   ```bash
   username=root
   export IPMI_PASSWORD=
   grep -oE $stoken /etc/dnsmasq.d/statics.conf | xargs -i ipmitool -I lanplus -U $username -E -H {} power off
   ```

    If you found an IP in step 3e, use ipmitool from ncn-m001 to power off ncn-w001.  

    If you did not find an IP in step 3e or you cannot access that IP, then SSH to ncn-w001 from ncn-m001 and execute `shutdown -h now`.   Make sure you have moved anything you need from ncn-w001 because we will not have access to bring it back up until we bring up another DHCP server on the LiveCD.


You can now go back to [LiveCD Creation](002-CSM-INSTALL.md)
