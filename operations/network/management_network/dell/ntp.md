# Network Time Protocol (NTP) Client

Summary of NTP from [RFC-1305 Network Time Protocol (Version 3)](https://tools.ietf.org/html/rfc1305):

> NTP is used to synchronize timekeeping among a set of distributed time servers and clients
> ...
> It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date
> well into the next century.

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system.
This document shows how to view NTP status and configure NTP on a Dell switch.

- [Show NTP status](#show-ntp-status)
- [Specify a remote NTP server](#specify-a-remote-ntp-server)
- [Configure source for NTP](#configure-source-for-ntp)
- [Expected results](#expected-results)

<a name="show-ntp-status"></a>

## Show NTP status

```console
OS10(config)# do show ntp status
```

Example output:

```text
system peer:          0.0.0.0
system peer mode:     unspec
leap indicator:       11
stratum:              16
precision:            -22
root distance:        0.00000 s
root dispersion:      1.28647 s
reference ID:         [73.78.73.84]
reference time:       00000000.00000000  Mon, Jan  1 1900  0:00:00.000
system flags:         monitor ntp kernel stats
jitter:               0.000000 s
stability:            0.000 ppm
broadcastdelay:       0.000000 s
authdelay:            0.000000 s
```

<a name="specify-a-remote-ntp-server"></a>

## Specify a remote NTP server

Specify a remote NTP server to use for time synchronization:

```console
switch(config)# ntp server <FQDN|IP-ADDR>
```

<a name="configure-source-for-ntp"></a>

## Configure source for NTP

```console
switch(config)# ntp source interface
```

<a name="expected-results"></a>

## Expected results

1. The NTP client can be configured.
1. The functionality can be validated using the `show` command.
1. The system time of the switch matches that of the NTP server.

[Back to index](index.md).
