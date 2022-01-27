# Wipe switch config

#### Aruba

It is recommended to create a checkpoint before erasing the switch config.

More information related to backing up configuration can be found on the [config management](config_management.md) page.

```
sw-spine-001# copy running-config checkpoint CSM1_0
```
Make sure the checkpoint was created.
```
sw-spine-001# show checkpoint 
NAME                                                TYPE        WRITER  DATE(YYYY/MM/DD)      IMAGE VERSION
CSM1_0                                              latest      User    2022-01-27T18:52:31Z  GL.10.08.1021
```

Erase Startup config
```
sw-spine-002# erase startup-config 
Erase checkpoint startup-config ? (y/n): y
```
Reboot 
```
sw-spine-001# boot system                                      
Checking if the configuration needs to be saved...

Do you want to save the current configuration (y/n)? n
```

The switch will reboot without any config.
The default user is `admin` without any password.

The next step is likely. [apply switch configs](apply_switch_configs.md).