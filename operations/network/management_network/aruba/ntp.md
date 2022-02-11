# Network Time Protocol (NTP) Client 

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system. The following commands show how to configure NTP.

## Configuration Commands

Specify a remote NTP server to use for time synchronization: 

```bash
switch(config)# ntp server <FQDN|IP-ADDR>
```

Force NTP to use a specific VRF for requests: 

```bash
switch(config)# ntp vrf VRF
```

Configure the system timezone: 

```bash
switch(config)# clock timezone TIMEZONE
```

Show commands to validate functionality:  

```bash
switch# show ntp status
```

## Example Output 

```bash
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

## Expected Results 

1. Administrators can configure the NTP client
2. Administrators can validate the functionality using the `show` command
3. The system time of the switch matches the NTP server

[Back to Index](../index.md)
