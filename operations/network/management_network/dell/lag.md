# Link Aggregation Group (LAG)

Link Aggregation allows administrators to assign multiple physical links to one logical link.
This logical link functions as a single, higher-speed link, providing dramatically increased bandwidth.

## Configuration commands

(`switch#`) Create and configure the LAG interface:

```text
interface port-channel 10
no shutdown
```

(`switch#`) Associate member links with the LAG interface:

```text
interface ethernet 1/1/1
channel-group 10
```

(`switch#`) Enable LACP on the LAG:

```text
interface ethernet 1/1/1
channel-group 10 mode active
```

## Show commands to validate functionality

(`switch#`)

```text
show interface port-channel
```

## Expected results

* Administrators can create and configure a LAG.
* Administrators can add ports to a LAG.
* Administrators can configure a LAG interface.

[Back to Index](../README.md)
