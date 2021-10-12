# Network time protocol (NTP) client 


“NTP is used to synchronize timekeeping among a set of distributed time servers and clients [...] It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date well into the next century.” –rfc1305 

Example Output 

```
switch# show ntp status
NTP is enabled.
NTP authentication is enabled.
NTP is using the default VRF for NTP server connections.
Wed Nov 23 23:29:10 PDT 2016
Uptime: 187 days, 1 hours, 37 minutes, 48 seconds
Synchronized to NTP Server 10.0.0.1 at stratum 2.
Poll interval = 1024 seconds.
Time accuracy is within 0.994 seconds
Reference time: Thu Jan 28 2016 0:57:06.647 (UTC)
```

Relevant Configuration 

Specify a remote NTP server to use for time synchronization 

```
switch(config)# ntp server <FQDN|IP-ADDR>
```

Force NTP to use a specific VRF for requests 

```
switch(config)# ntp vrf VRF
```

Configure the system timezone 

```
switch(config)# clock timezone TIMEZONE
```

Show Commands to Validate Functionality 

```
switch# show ntp status
```

Expected Results 

* Step 1: You can configure the NTP client
* Step 2: You can validate the functionality using the show command 
* Step 3: The system time of the switch matches the NTP server


[Back to Index](#/docs-csm/operations/network/network_management_install_guide/aruba/
index)

