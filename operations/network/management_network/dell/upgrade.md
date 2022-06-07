
# Perform an Upgrade on Dell Switches

How to perform an upgrade on the Dell switches.

## Configuration Commands

Download the new software image:

```text
switch# image download file-url
```

View the current software download status:

```text
switch# show image status
```

Install the software image:

```text
switch# image install image-url
```

View the status of the current software install:

```text
switch# show image status
```

Change the next boot partition to the standby partition:

```text
switch# boot system standby
```

Reload the new software image:

```text
switch# reload
```

[Back to Index](index.md)
