# Test TFTP traffic (Aruba Only)

* You can test the TFTP traffic by trying to download the ipxe.efi binary.
* Log into the leaf switch and try to download the iPXE binary.
* This requires that the leaf switch can talk to the TFTP server "10.92.100.60"

```
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

You can see here that the ipxe.efi binary is downloaded three times in a row. 

[Back to Index](../index.md)