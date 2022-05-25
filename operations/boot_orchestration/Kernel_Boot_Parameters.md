# Kernel Boot Parameters

The Image Management Service (IMS) extracts kernel boot parameters from the /boot/kernel-parameters file in the image, if that file exists, and stores them in S3. IMS already stores the other boot artifacts (kernel, initrd, and rootfs) in S3. When told to boot an image, the Boot Orchestration Service (BOS) will extract these parameters and deliver them to the Boot Script Service (BSS) so they can be used during the next boot of a node.

There are two benefits to having kernel boot parameters extracted from the image. First, these parameters can be tightly coupled to the image. Second, these parameters do not need to be specified in the BOS session template, making the template shorter, cleaner, and less error prone.

The kernel boot parameters obtained from the image can be overridden by specifying the same parameters in the BOS session template. BOS supplies these parameters to the kernel in a deliberate order that causes the parameters obtained from the image to be overridden by those obtained from the session template.

The following is a simplified kernel boot parameter ordering:

```
<Image parameters> <Session template parameters>
```

If there are competing values, the ones earlier in the boot string are superseded by the ones appearing later in the string.

The actual contents of the boot parameters are not as simple as previously described. For completeness, the following is the entire kernel boot parameter ordering:

```
<Image parameters> <Session template parameters> <rootfs parameters> <rootfs passthrough parameters> <BOS session id>
```
