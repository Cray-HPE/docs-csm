# Configure System Images

Dell switches support active and standby images.

## Configuration commands

Copy an image from a local server:

```text
image download ftp://admin@1.1.1.1:/image.bin
```

Install image:

```text
image install file-url
```

## Show commands to validate functionality

```text
show boot detail
```

## Expected results

1. Administrators can upload an image to the switch
1. Administrators can boot into the uploaded image
1. Administrators can see they are running the uploaded image

[Back to Index](../README.md)
