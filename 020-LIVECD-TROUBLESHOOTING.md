# LiveCD Recovery


### Root Account

The root password is preserved within the COW partition at `cow:rw/etc/shadow`. This is the
modified copy of the /etc/shadow file used by the operating system.

If a site/user needs to reset/clear the password for `root`, they can mount their USB on another
machine and remove this file from the COW partiion. When next booting from the USB it will
reinitialize to an empty password for `root`, and again at next login it will require the password
to be changed.

```bash
mypc:~ > mount -L cow /mnt
mypc:~ > sudo rm -f /mnt/rw/etc/shadow
mypc:~ > umount -L cow
```

### Basecamp

If the desire to reset basecamp to defaults comes up, you can do so by following these commands.

```bash
pit:~ # systemctl stop basecamp
pit:~ # podman rm basecamp
pit:~ # podman rmi basecamp
pit:~ # rm -f /var/www/ephemeral/configs/server.yaml
# Now basecamp will re-init.
pit:~ # systemctl start basecamp
```
