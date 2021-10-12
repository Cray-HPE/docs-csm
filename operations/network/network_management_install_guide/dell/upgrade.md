
# Performing upgrade on Dell switches

How to perform an upgrade on the Dell switches.

Relevant configuration

Download the new software image

```
switch# image download file-url
```

View the current software download status

```
switch# show image status
```

Install the software image

```
switch# image install image-url
```

View the status of the current software install

```
switch# show image status
```

Change the next boot partition to the standby partition

```
switch# boot system standby
```

Reload the new software image

```
switch# reload
```

[Back to Index](./index.md)