# LiveCD Recovery


### Root Account

The root password is preserved within the COW partition at `cow:rw/etc/shadow`. This is the copy of 
the(the upper filesystem of the overlayfs) copy of the modified /etc/shadow file.

If a site/user needs to reset/clear the password for `root`, they can mount their USB on another
machine and remove this file from the COW partiion. When next booting from the USB it will 
reinitialize to an empty password for `root`, and again at next login it will require the password
to be changed.

```bash
mypc:~ > mount /dev/disk/by-label/cow /mnt
mypc:~ > sudo rm -f /mnt/rw/etc/shadow
mypc:~ > umount /dev/disk/by-label/cow
```