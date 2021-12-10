
# Test TFTP Traffic (Aruba Only)

TFTP traffic can be tested by attempting to download the ipxe.efi binary.

Log into the leaf switch and try to download the iPXE binary.

This requires that the leaf switch can talk to the TFTP server "10.92.100.60".

```bash
sw-leaf-001# start-shell
sw-leaf-001:~$ sudo su
sw-leaf-001:/home/admin# tftp 10.92.100.60
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
```

The ipxe.efi binary is downloaded three times in a row in this example. 

[Back to Index](../index_aruba.md)