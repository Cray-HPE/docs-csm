# Configure Hostnames

A hostname is a human-friendly name used to identify a device. An example of a hostname could be the name "Test."

## Configuration commands

(`switch(config)#`) Create a hostname:

```console
hostname <NAME>
```

(`switch#`) Show commands to validate functionality:

```console
show hostname
```

## Example output

```console
switch(config)# hostname switch-test
show hostname
switch-test
```

## Expected results

- Administrators can configure the hostname
- The output of all show commands is correct

[Back to Index](../README.md)
