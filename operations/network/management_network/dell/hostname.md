
# Configure Hostnames

A hostname is a human-friendly name used to identify a device. An example of a hostname could be the name "Test."

## Configuration Commands

Create a hostname:

```text
switch(config)# hostname NAME
```

Show commands to validate functionality:

```text
switch# show hostname
```

## Example Output

```text
switch(config)# hostname switch-test
switch-test# show hostname
switch-test
```

## Expected Results

1. Administrators can configure the hostname
2. The output of all `show` commands is correct

[Back to Index](index.md)
