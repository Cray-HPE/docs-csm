# Test TFTP traffic (Aruba Only)

* TFTP traffic can be tested by trying to download the `ipxe.efi` binary.
* Log into the leaf switch and try to download the iPXE binary.
* This requires that the leaf switch can talk to the TFTP server (`10.92.100.60`)

```console
start-shell
sw-leaf-001:~$ sudo su
sw-leaf-001:/home/tftp 10.92.100.60
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
```

In the above example, the `ipxe.efi` binary is successfully downloaded three times in a row.

[Back to Index](../README.md)
