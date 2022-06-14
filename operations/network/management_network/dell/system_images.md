# Configure System Images

Dell switches support active and standby images.

## Configuration Commands

Copy an image from a local server:

```text
Switch(config)# image download ftp://admin@1.1.1.1:/image.bin
```

Install image:

```text
Switch(config)# image install file-url
```

Show commands to validate functionality:

```text
Switch(config)# show boot detail
```

## Expected Results

1. Administrators can upload an image to the switch
2. Administrators can boot into the uploaded image
3. Administrators can see they are running the uploaded image

[Back to Index](index.md)
