# Network time protocol (NTP) client


"NTP is used to synchronize timekeeping among a set of distributed time servers and clients [...] It provides the protocol mechanisms to synchronize time in principle to precisions in the order of nanoseconds while preserving a non-ambiguous date well into the next century." –rfc1305

Example Output

```
OS10(config)# do show ntp status
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

Relevant Configuration

Specify a remote NTP server to use for time synchronization

```
switch(config)# ntp server <FQDN|IP-ADDR>
```

Configure source for NTP

```
switch(config)# ntp source interface
```

Show NTP status

```
switch# show ntp status
```

Expected Results

* Step 1: You can configure the NTP client
* Step 2: You can validate the functionality using the show command
* Step 3: The system time of the switch matches the NTP server

[Back to Index](index.md)

