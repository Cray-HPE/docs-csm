# System images

Dell switches support active and standby images.

Relevant Configuration

Copy an image from a local server

```
Switch(config)# image download ftp://admin@1.1.1.1:/image.bin
```

Install image

```
Switch(config)# image install file-url
```

Show Commands to Validate Functionality

```
Switch(config)# show boot detail
```

Expected Results

* Step 1: You can upload an image to the switch
* Step 2: You can boot into the uploaded image
* Step 3: You can see you are running the uploaded image

[Back to Index](./index.md)

