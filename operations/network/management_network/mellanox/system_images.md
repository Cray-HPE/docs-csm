# System Images

Mellanox switches can hold two firmware images. These images, once uploaded, are called the "Running" and "Image available for install".

## Relevant configuration

(`switch (config)#`) Delete old images, if any exist

```console
image delete XXX
```

(`switch (config)#`) Copy an image from a local server using `sftp`.

```console
image fetch scp://root:password@server/path-to-image/image-X86_64-3.4.2002.img
image install image-X86_64-3.4.2002.img
```

(`switch (config)#`) Boot the switch into the new firmware.

```console
image boot next
configuration write
reload
```

## Show commands to validate functionality

(`switch#`)

```console
show version
```

## Expected results

* Administrators can upload an image to the switch
* Administrators can see the versions of code for the primary and secondary images
* Administrators can boot into the uploaded image
* Administrators can confirm the switch is running the uploaded image

[Back to Index](../README.md)
