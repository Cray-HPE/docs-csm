# Perform an Upgrade on Dell Switches

How to perform an upgrade on the Dell switches.

## Configuration Commands

Download the new software image:

```text
image download file-url
```

View the current software download status:

```text
show image status
```

Install the software image:

```text
image install image-url
```

View the status of the current software install:

```text
show image status
```

Change the next boot partition to the standby partition:

```text
boot system standby
```

Reload the new software image:

```text
reload
```

[Back to Index](../README.md)
