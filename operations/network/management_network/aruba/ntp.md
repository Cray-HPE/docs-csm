# Network Time Protocol (NTP) Client

Summary of NTP from [RFC-1305 Network Time Protocol (Version 3)](https://tools.ietf.org/html/rfc1305):

> NTP is used to synchronize timekeeping among a set of distributed time servers and clients
> ...
> It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date
> well into the next century.

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system.
This document shows how to view NTP status and configure NTP on an Aruba switch.

- [Specify a remote NTP server](#specify-a-remote-ntp-server)
- [Force NTP to use a specific VRF for requests](#force-ntp-to-use-a-specific-vrf-for-requests)
- [Configure the system timezone](#configure-the-system-timezone)
- [Validate functionality](#validate-functionality)
- [Expected results](#expected-results)

<a name="specify-a-remote-ntp-server"></a>

## Specify a remote NTP server

Specify a remote NTP server to use for time synchronization:

```console
switch(config)# ntp server <FQDN|IP-ADDR>
```

<a name="force-ntp-to-use-a-specific-vrf-for-requests"></a>

## Force NTP to use a specific VRF for requests

```console
switch(config)# ntp vrf VRF
```

<a name="configure-the-system-timezone"></a>

## Configure the system timezone

```console
switch(config)# clock timezone TIMEZONE
```

<a name="validate-functionality"></a>

## Validate functionality

```console
switch# show ntp status
```

Example output:

```text
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

<a name="expected-results"></a>

## Expected results

1. The NTP client can be configured.
1. The functionality can be validated using the `show` command.
1. The system time of the switch matches that of the NTP server.

[Back to index](index.md).
