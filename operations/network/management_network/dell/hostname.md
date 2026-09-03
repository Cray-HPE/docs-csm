# Hostname

A hostname is a human-friendly name used to identify a device.
An example of a hostname could be the name `test`.

## Configuration commands

(`switch#`) Create a hostname:

```text
hostname NAME
```

## Show commands to validate functionality

(`switch#`)

```text
show hostname
```

(`switch#`)

```text
hostname switch-test
show hostname
```

## Expected results

* Administrators can configure the hostname.
* The output of all `show` commands is correct.

[Back to Index](../README.md)
