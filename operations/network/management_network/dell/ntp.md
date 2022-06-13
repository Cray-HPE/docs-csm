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
This document shows how to view NTP status and configure NTP on a Dell switch.

- [Show NTP status](#show-ntp-status)
- [Specify a remote NTP server](#specify-a-remote-ntp-server)
- [Configure source for NTP](#configure-source-for-ntp)
- [Expected results](#expected-results)

## Show NTP status

```console
do show ntp status
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

## Specify a remote NTP server

Specify a remote NTP server to use for time synchronization:

```console
ntp server <FQDN|IP-ADDR>
```

## Configure source for NTP

```console
ntp source interface
```

## Expected results

1. The NTP client can be configured.
1. The functionality can be validated using the `show` command.
1. The system time of the switch matches that of the NTP server.

[Back to Index](../README.md)
