# Kubernetes Master or Worker node's root filesystem is out of space

## Description

 There is a known bug in Kubernetes 1.19.9 where movement of a pod with an attached volume may not complete in time and cause the kubelet service to stream error messages to the /var/log/messages log file.  If this goes unchecked, it will fill up the root file system.

## Fix

1. Log into the node that has space issues.
1. Verify that you have a large messages file in `/var/log/`.

   ```bash
   ncn-m/w:/var/log # ls -lh messages-20211212
   -rw-r----- 1 root root 67G Dec 13 12:24 messages-20211212
   ```

1. Remove the file.
1. Restart kubelet to address the streaming log entries.

   ```bash
   ncn-m/w# systemctl restart kubelet.service
   ```

1. Restart the syslog service.

   ```bash
   ncn-m/w# systemctl restart rsyslog
   ```

1. Verify that the space issue is resolved

   ```bash
   ncn-m/w# df -h /
   Filesystem      Size  Used Avail Use% Mounted on
   LiveOS_rootfs   280G  933M  279G   1% /
   ```
