# Image projection inconsistent across nodes

- [Introduction](#introduction)
- [Example Error](#example-of-error)
- [Examining the problem](#cause-of-the-error)
- [Resolution](#resolution)

## Introduction

This issue described is for content projection not working consistently across nodes.
This has been observed with iSCSI SBPS but it is also possible that this could happen when using DVS.

## Example of Error

There are multiple errors that can be observed because of this problem. The following are example errors:

- Doing an `md5sum` on `/opt/cray/pe` files on a compute node results in IO errors.

    ```text
    md5sum: /opt/cray/pe/cce/17.0.0/cce-clang/x86_64/lib/libLLVMAArch64CodeGen.a: Input/output error
    md5sum: /opt/cray/pe/cce/17.0.0/cce-clang/x86_64/lib/libLLVMAArch64Desc.a: Input/output error
    a764bc1859748fb1abf2548a5c1bbaae  /opt/cray/pe/cce/17.0.0/cce-clang/x86_64/lib/libLLVMAArch64Disassembler.a
    209e22ec797a5f2fdea81c8bb70c1d2e  /opt/cray/pe/cce/17.0.0/cce-clang/x86_64/lib/libLLVMAArch64Info.a
    ```

- `dmesg -TW` run upon a client shows decompression failed and read block errors

    ```bash
    uan01:~ # dmesg -TW
    [Wed Nov  6 15:40:26 2024] SQUASHFS error: xz decompression failed, data probably corrupt
    [Wed Nov  6 15:40:26 2024] SQUASHFS error: Failed to read block 0x544109af: -5
    [Wed Nov  6 15:40:26 2024] SQUASHFS error: xz decompression failed, data probably corrupt
    [Wed Nov  6 15:40:26 2024] SQUASHFS error: Failed to read block 0x542feacb: -5
    ```

- Different `md5sum`s exist for the same file on different worker nodes.

    ```bash
    ncn-w001:~ # md5sum /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs
    829199014137a7e25b3c149f9239f372  /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs

    ncn-w002:~ # md5sum /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs
    6e6e10dfa89942ce17db40f9c0ab26d4  /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs

    ncn-w003:~ # md5sum /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs
    f13369e126f45f0cca83e45988d1c5ef  /var/lib/cps-local/boot-images/PE/CPE-base.x86_64-25.03.squashfs
    ```

## Cause of the Error

Image projection inconsistency is caused when an existing image in S3 `boot-images` is overwritten.
This could occur when a product provides a static SquashFS and is uploaded to S3 a second time.
This is most likely to happen when a CPE image is uploaded to `boot-images` with the same name as an existing image.
Generally, images uploaded to `boot-images` will have a unique UUID as their key so this issue will not be hit.
However, CPE creates images which use names as their key.
Because of this, their keys may be identical and this inconsistent projection may be seen.

## Resolution

There are two ways to resolve this problem.

1. The existing image ID that was duplicated can be changed to a unique image ID and this new unique image ID can be referenced.
This would likely mean restarting the product installation from an early IUF stage.

1. If the image is being exported by SBPS, do a rolling reboot of worker nodes to ensure all worker nodes have the correct image information.
Follow the [NCN rolling reboot documentation](../operations/node_management/Reboot_NCNs.md#ncn-rolling-reboot).

1. If compute nodes are still experiencing issues after worker nodes have been rebooted, compute nodes will also need to be rebooted to cleanly remount the image.
