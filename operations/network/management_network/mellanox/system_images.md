# System images

Mellanox switches can hold two firmware images. These images, once uploaded, are called the Running and Image available for install.

Relevant Configuration

Copy an image from a local server using sftp

```
switch (config)#image delete XXX // --> delete old images, if exist
switch (config)#image fetch scp://root:password@server/path-to-image/image-X86_64-3.4.2002.img
switch (config)#image install image-X86_64-3.4.2002.img
```

Boot the switch into the new firmware

```
switch (config)#image boot next
switch (config)#configuration write
switch (config)#reload
```

Show Commands to Validate Functionality

```
switch# show version
```

Expected Results

* Step 1: You can upload an image to the switch
* Step 2: You can see the versions of code for the primary and secondary images
* Step 3: You can boot into the uploaded image
* Step 4: You can see you are running the uploaded image


[Back to Index](../index.md)

