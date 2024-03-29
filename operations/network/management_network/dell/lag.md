# Configure Link Aggregation Group (LAG)

Link aggregation allows administrators to assign multiple physical links to one logical link that
functions as a single, higher-speed link providing dramatically increased bandwidth.

## Configuration Commands

Create and configure the LAG interface:

```text
interface port-channel 10
no shutdown
```

Associate member links with the LAG interface:

interface IFACE`

```text
interface ethernet 1/1/1
channel-group 10
```

To enable LACP on the LAG:

```text
interface ethernet 1/1/1
switch(conf-if-eth1/1/1)#channel-group 10 mode active
```

Show commands to validate functionality:

```text
show interface port-channel
```

## Expected Results

1. Administrators can create and configure a LAG
2. Administrators can add ports to a LAG
3. Administrators can configure a LAG interface

[Back to Index](../README.md)
