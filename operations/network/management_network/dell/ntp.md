# Configure the Network Time Protocol (NTP) Client

The Network Time Protocol (NTP) client is essential for syncing time on various clients in the system. The following commands show how to configure NTP.

## Relevant Configuration

Specify a remote NTP server to use for time synchronization:

```
switch(config)# ntp server <FQDN|IP-ADDR>
```

Configure source for NTP:

```
switch(config)# ntp source interface
```

Show NTP status:

```
switch# show ntp status
```

## Example Output

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

## Expected Results

1. Administrators can configure the NTP client
2. Administrators can validate the functionality using the `show` command
3. The system time of the switch matches the NTP server

[Back to Index](index.md)

