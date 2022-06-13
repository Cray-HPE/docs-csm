# Network Time Protocol (NTP) Client

<<<<<<< HEAD
Summary of NTP from [RFC-1305 Network Time Protocol (Version 3)](https://tools.ietf.org/html/rfc1305):

> NTP is used to synchronize timekeeping among a set of distributed time servers and clients
> ...
> It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date
> well into the next century.
=======
"NTP is used to synchronize timekeeping among a set of distributed time servers and clients [...] It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date well into the next century." –rfc1305
>>>>>>> MTL-1695

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system.
This document shows how to view NTP status and configure NTP on a Mellanox switch.

- [Enable NTP](#enable-ntp)
- [Test the NTP server](#test-the-ntp-server)
- [Specify a remote NTP server](#specify-a-remote-ntp-server)
- [Configure the system timezone](#configure-the-system-timezone)
- [Validate functionality](#validate-functionality)
- [Expected results](#expected-results)

## Enable NTP

```console
(`switch (config) # `)
```
ntp enable
```

## Test the NTP server

Test the NTP server by querying the current time:

```console
(`switch (config) # `)
```
ntpdate 10.4.0.134
```

## Specify a remote NTP server

Specify a remote NTP server to use for time synchronization:

(`switch(config)# `)
```
ntp server <FQDN|IP-ADDR>
```

## Configure the system timezone

```console
(`switch (config) # `)
```
clock timezone UTC-offset UTC-7
```

## Validate functionality

```console
switch (config)# show ntp
```

(`switch (config)# `)
```
show ntp
```

## Expected results

1. The NTP client can be configured.
1. The functionality can be validated using the `show` command.
1. The system time of the switch matches that of the NTP server.

[Back to Index](../README.md)
