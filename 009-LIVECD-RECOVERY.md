# LiveCD Recovery


### Root Account

The root password is preserved within the COW partition at `cow:rw/etc/shadow`. This is the
modified copy of the /etc/shadow file used by the operating system.

If a site/user needs to reset/clear the password for `root`, they can mount their USB on another
machine and remove this file from the COW partiion. When next booting from the USB it will 
reinitialize to an empty password for `root`, and again at next login it will require the password
to be changed.

```bash
mypc:~ > mount /dev/disk/by-label/cow /mnt
mypc:~ > sudo rm -f /mnt/rw/etc/shadow
mypc:~ > umount /dev/disk/by-label/cow
```

### Basecamp

If the desire to reset basecamp to defaults comes up, you can do so by following these commands.

```bash
spit:~ # systemctl stop basecamp
spit:~ # podman rm basecamp
spit:~ # podman rmi basecamp
spit:~ # rm -f /var/www/ephemeral/configs/server.yaml
# Now basecamp will re-init.
spit:~ # systemctl start basecamp
```
