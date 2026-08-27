# Link Aggregation Group (LAG)

Link Aggregation allows administrators to assign multiple physical links to one logical link.
This logical link functions as a single, higher-speed link, providing dramatically increased bandwidth.

## Relevant configuration

(`switch (config) #`) Create and configure the LAG interface:

```console
interface port-channel 1
```

(`switch (config interface port-channel 1) #`) Exit `port-channel` context:

```console
exit
```

(`switch (config) #`) Associate member links with the LAG interface:

```console
interface IFACE
channel-group 1 mode on
```

(`switch (config interfaces ethernet 1/7)#`) Enable LACP in LAG:

```console
lacp rate fast
```

## Show commands to validate functionality

```console
show interface port-channel
```

## Expected results

* Administrators can create and configure a LAG
* Administrators can add ports to a LAG
* Administrators can configure a LAG interface

[Back to Index](../README.md)
