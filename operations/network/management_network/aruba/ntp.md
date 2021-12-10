
# Network Time Protocol (NTP) Client 

“NTP is used to synchronize timekeeping among a set of distributed time servers and clients [...] It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date well into the next century.” –rfc1305 

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

1. You can configure the NTP client
2. You can validate the functionality using the `show` command
3. The system time of the switch matches the NTP server


[Back to Index](../index.md)
