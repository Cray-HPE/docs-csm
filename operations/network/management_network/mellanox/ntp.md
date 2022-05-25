# Network time protocol (NTP) client


"NTP is used to synchronize timekeeping among a set of distributed time servers and clients [...] It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date well into the next century." –rfc1305

Relevant Configuration

Enable NTP

```
switch (config) # ntp enable
```

Test the NTP server by querying the current time.

```
switch (config) # ntpdate 10.4.0.134
```

Specify a remote NTP server to use for time synchronization

```
switch(config)# ntp server <FQDN|IP-ADDR>
```

Configure the system timezone

```
switch (config) # clock timezone UTC-offset UTC-7
```

Show Commands to Validate Functionality

```
switch (config)# show ntp

Expected Results

* Step 1: You can configure the NTP client
* Step 2: You can validate the functionality using the show command
* Step 3: The system time of the switch matches the NTP server

[Back to Index](../index.md)
