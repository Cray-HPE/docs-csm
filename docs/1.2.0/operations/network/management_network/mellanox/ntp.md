# Network Time Protocol (NTP) Client

Summary of NTP from [RFC-1305 Network Time Protocol (Version 3)](https://tools.ietf.org/html/rfc1305):

> NTP is used to synchronize timekeeping among a set of distributed time servers and clients
> ...
> It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date
> well into the next century.

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system.
This document shows how to view NTP status and configure NTP on a Mellanox switch.

- [Enable NTP](#enable-ntp)
- [Test the NTP server](#test-the-ntp-server)
- [Specify a remote NTP server](#specify-a-remote-ntp-server)
- [Configure the system timezone](#configure-the-system-timezone)
- [Validate functionality](#validate-functionality)
- [Expected results](#expected-results)

<a name="enable-ntp"></a>

## Enable NTP

```console
switch (config) # ntp enable
```

<a name="test-the-ntp-server"></a>

## Test the NTP server

Test the NTP server by querying the current time:

```console
switch (config) # ntpdate 10.4.0.134
```

<a name="specify-a-remote-ntp-server"></a>

## Specify a remote NTP server

Specify a remote NTP server to use for time synchronization:

```console
switch(config)# ntp server <FQDN|IP-ADDR>
```

<a name="configure-the-system-timezone"></a>

## Configure the system timezone

```console
switch (config) # clock timezone UTC-offset UTC-7
```

<a name="validate-functionality"></a>

## Validate functionality

```console
switch (config)# show ntp
```

<a name="expected-results"></a>

## Expected results

1. The NTP client can be configured.
1. The functionality can be validated using the `show` command.
1. The system time of the switch matches that of the NTP server.

[Back to index](index.md).
