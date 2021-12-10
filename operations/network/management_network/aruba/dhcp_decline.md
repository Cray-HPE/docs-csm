
# Large Number of DHCP Declines During a Node Boot

If something similar to the following is in the logs, this indicates an issue that an IP address being allocated is already being used and is not able to get the IP assigned to the device as previously set. 

```
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.56
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.57
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.58
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.59
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.60
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.51
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.53
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.54
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.61
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.62
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.63
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.64
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.65
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.66
dracut-initqueue[1902]: wicked: eth0: Declining DHCPv4 lease with address 10.252.0.67
```

## Procedure

* Check by MAC address (no colons):
  
  ```
  curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces/18c04d13d73c
  ```

* Check by xname:
  
  ```
  curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces?ComponentID=x3000c0s25b0n0
  ```

[Back to Index](../index_aruba.md)