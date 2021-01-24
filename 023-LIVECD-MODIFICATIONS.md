# Making modifications to the NCNs

It may be desirable to change some settings after the system is up and running.  This doc outlines how this can be accomplished.  When NCNs are booted, the metadata they use is stored in `data.json` and pulled in via cloud-init.  If you make a change to `data.json`, (or need to use a new image) you need to reboot the machine so it picks up the changes.

## NTP

One example needing to change the config on the system is NTP.  Customers may want to add an upstream NTP server instead of simply have the NCNs peer with themselves.  Since we don't define an upstream NTP server by default, the change would be made in `data.json` and then when you reboot the nodes, they pick up the new changes.

> This is the expected behavior but additional testing will verify this is the case.

```
# Insert the upstream ntp server into data.json
sed -i 's/"upstream_ntp_server": "",/"upstream_ntp_server": "cfntp-4-1.us.cray.com",/' /var/www/ephemeral/configs/data.json
# Restart basecamp to pick up the changes
systemctl restart basecamp
# Reboot the nodes and verify server is in the config
```

Similarly, you could do the same to remove the upstream NTP server if you wanted.
