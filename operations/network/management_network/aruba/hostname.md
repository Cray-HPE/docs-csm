# Hostname

A hostname is a human-friendly name used to identify a device.
An example of a hostname could be the name `test`.

## Configuration commands

(`switch(config)#`) Create a hostname:

```console
hostname <NAME>
```

## Show commands to validate functionality

(`switch#`)

```console
show hostname
```

(`switch(config)#`)

```console
hostname switch-test
show hostname
```

Example output:

```text
switch-test
```

## Expected results

* Administrators can configure the hostname.
* The output of all `show` commands is correct.

[Back to Index](../README.md)
