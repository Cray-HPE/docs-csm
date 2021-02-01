# CSM Install Reboot - Final NCN Install

This page describes rebooting and deploying the non-compute node that is currently hosting the LiveCD.

**This is the final step in the Cray System Management (CSM) installer**. The customer or administrator may 
choose to install additional products following the completion of the CSM installer.

Additional products include, but are not limited to:

- Compute Nodes
- High-Speed Network
- Program Environment (PE)
- User Access Nodes
- Work-Load Managers / SLURM

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.

Required Platform Services:
- cray-dhcp-kea
- cray-dns-unbound
- cray-bss
- cray-sls
- cray-s3
- cray-ipxe
- cray-tftp

Steps:
1. Upload sls file
2. Upload BSS data
3. Upload NCN artifacts
4. Set efibootmgr for bootnext
5. Optionally backup data to another NCN if not already (for remote and USB)
6. Optionally setup conman or serial console if not already on one
7. Reboot mn001
8. Connect to cluster
