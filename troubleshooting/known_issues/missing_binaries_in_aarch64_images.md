# Missing binaries in aarch64 Images

Due to a bug in the QEMU emulation software, there are times that dependencies are missed
for packages that are being installed on `aarch64` images when run in emulation on `x86_64`
hardware. This will usually manifest when the image is being booted or running processes
where an error about missing shared libraries is encountered.

## Root Cause

This is due to a bug in the QEMU software when the `ld` search crashes while attempting to
follow binary dependencies for packages being installed. There are details on the bug here:

* [QEMU Issue 1763](https://gitlab.com/qemu-project/qemu/-/issues/1763)
* [qemu-user-static Issue 172](https://github.com/multiarch/qemu-user-static/issues/172)

## Identifying the Issue

There have been a couple of cases where this error was observed. Here are some examples of
what was seen to help identify if it happens again.

1. Missing dependency on `libfuse.so.2`.

    Initially the observed symptom was that `cxi_rh` failed to start during the dracut boot.

    ```text
    lnetctl net add --if cxi0 --net kfi
    [ 3893.359185][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.369468][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.379657][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.389844][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.400013][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.410163][ T5428] kfi_cxi - kcxi_dev_ready:93: kCXI Device Index (0) Fabric (1): Retry handler not running
    [ 3893.420335][ T5428] LNetError: 5428:0:(kfilnd_dev.c:160:kfilnd_dev_alloc()) Failed to get KFI LND domain: rc=-61
    [ 3893.430877][ T5428] LNetError: 5428:0:(kfilnd.c:389:kfilnd_startup()) Failed to allocate KFILND device for cxi0: rc=-61
    [ 3893.442049][ T5428] LNetError: 105-4: Error -61 starting up LNI kfi
    ```

    Attempting to start the retry handler gave the real issue.

    ```text
    sh-4.4# systemctl start cxi_rh@cxi0
    [FAILED] Failed to start CXI Retry Handler on cxi0.
    Job for cxi_rh@cxi0.service failed because the control process exited with error code.
    See "systemctl status cxi_rh@cxi0.service" and "journalctl -xeu cxi_rh@cxi0.service" for details.
    sh-4.4# journalctl -xeu cxi_rh@cxi0.service | cat
    Aug 16 12:00:23 nid001048 systemd[1]: Starting CXI Retry Handler on cxi0...
    Aug 16 12:00:23 nid001048 (serm[2953]: cxi_rh@cxi0.service: Executable /usr/bin/fusermount missing, skipping: No such file or directory
    Aug 16 12:00:23 nid001048 cxi_rh[2974]: /usr/bin/cxi_rh: error while loading shared libraries: libfuse.so.2: cannot open shared object file: No such file or directory
    Aug 16 12:00:23 nid001048 systemd[1]: cxi_rh@cxi0.service: Main process exited, code=exited, status=127/n/a
    Aug 16 12:00:23 nid001048 systemd[1]: cxi_rh@cxi0.service: Failed with result 'exit-code'.
    Aug 16 12:00:23 nid001048 systemd[1]: Failed to start CXI Retry Handler on cxi0.
    Oct 19 20:09:03 nid001048 systemd[1]: Starting CXI Retry Handler on cxi0...
    Oct 19 20:09:03 nid001048 (serm[5475]: cxi_rh@cxi0.service: Executable /usr/bin/fusermount missing, skipping: No such file or directory
    Oct 19 20:09:03 nid001048 cxi_rh[5477]: /usr/bin/cxi_rh: error while loading shared libraries: libfuse.so.2: cannot open shared object file: No such file or directory
    Oct 19 20:09:03 nid001048 systemd[1]: cxi_rh@cxi0.service: Main process exited, code=exited, status=127/n/a
    Oct 19 20:09:03 nid001048 systemd[1]: cxi_rh@cxi0.service: Failed with result 'exit-code'.
    Oct 19 20:09:03 nid001048 systemd[1]: Failed to start CXI Retry Handler on cxi0.
    ```

    From this it was observed that the `libfuse.so.2` library was missing. To resolve this, the missing libraries
    were added explicitly to the ansible playbook where the package was installed.

1. Missing dependency on `liblnetconfig.so.4`.

    In this case the missing shared object file was reported directly during the dracut phase of the boot:

    ```text
    131.772352] dracut-initqueue[3952]: cps: All requested interfaces are UP, proceeding.
    [  131.958603] dracut-initqueue[4013]: 4 blocks
    [  132.803820] dracut-pre-mount[4067]: LNet: loaded lnet module.
    [  132.840080] dracut-pre-mount[4077]: lnetctl: error while loading shared libraries: liblnetconfig.so.4: cannot open shared object file: No such file or directory
    [  132.840141] dracut-pre-mount[4067]: LNet: Error calling 'lnetctl lnet configure'.
    [  132.840181] dracut-pre-mount[4065]: DVS: ERROR: lnet-load.sh failed.
    [  132.840195] dracut-pre-mount[4063]: Warning: ERROR: dvs-setup.sh failed; dropping to debug.
    [  132.840210] dracut-pre-mount[4058]: Warning: Unable to prepare squashfs file /tmp/cps/rootfs, dropping to debug.

    Generating "/run/initramfs/rdsosreport.txt"

    Press Enter for maintenance
    (or press Control-D to continue): 
    ```

    This case directly reported the missing `liblnetconfig.so.4` file, so any of the below workaround steps
    could be taken to resolve the issue.

## Workarounds

There are a couple of ways to work around this issue once it has been identified.

### Build or Customize the Image on a Remote Node (Only in CSM 1.5.2 or later)

This issue only applies to the emulation of `aarch64` images on `x86_64` hardware. If there is
an `aarch64` compute node that is available to be used for remote builds, the jobs may be run
on a remote node without needing to use the emulation software. That avoids this issue as well
as being much more performant than builds done under emulation.

To run remote build jobs, follow the documentation here:
[Configure a Remote Build Node](../../operations/image_management/Configure_a_Remote_Build_Node.md)

### Add the missing binary explicitly

The missing binary may be added in any of the following ways:

1. Add the package to the recipe.

    If the image is built via a recipe, the package that contains the missing binary
    may be added to the recipe. Rebuild the image with the updated recipe and the
    missing binary file should then be included.

1. Add the package to an Ansible play.

    If the image is being customized via Ansible plays, the package that contains the
    missing binary may be added to an Ansible play. Rerun the image customization and
    the missing should then be included.

1. Manually add to the complete image.

    The image that is missing the binary file may be manually customized to include the
    missing files. Follow the directions here for how to manually customize an image:
    [Customize an Image Root Using IMS](../../operations/image_management/Customize_an_Image_Root_Using_IMS.md)
