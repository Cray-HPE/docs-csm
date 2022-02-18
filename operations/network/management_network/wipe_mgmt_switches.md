# Wipe Switch Config

#### Prerequisites 
- Out of band access to the switches (console).
### Aruba

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

The next step is likely going to be [apply switch configs](apply_switch_configs.md).

### Dell

Save startup config to new xml config
```
sw-leaf-bmc-001# copy config://startup.xml config://csm1.2.xml
```
Erase the startup config and reboot
```
sw-leaf-bmc-001# delete startup-configuration
Proceed to delete startup-configuration [confirm yes/no(default)]:yes
sw-leaf-bmc-001# reload
System configuration has been modified. Save? [yes/no]:no
Continuing without saving system configuration
Proceed to reboot the system? [confirm yes/no]:yes
```
The default username and password are `admin`
This will boot the switch to factory defaults, The next step is likely going to be [apply switch configs](apply_switch_configs.md).

### Mellanox

Create a new config file, when a new config file is created no data is written to it. We will boot to this new config file which will be blank.
```
(config) # configuration new csm1.2
```
If that config exists you can either delete it with `configuration delete csm1.2` or reset to factor with `reset factory`

Check that the configuration files contain the new csm1.2 blank config we just created.
```
(config) # show configuration files
files
csm1.0 (active)
csm1.2
initial
initial.bak
Active configuration: csm1.0
Unsaved changes : no
```
- We will now switch to the new config, this requires a reboot
```
(config) # configuration switch-to csm1.2
This requires a reboot.
Type 'yes' to confirm: yes
```
- The default username and password are `admin`
- Follow the prompts as shown below.
```
NVIDIA Switch


Configuration wizard

Do you want to use the wizard for initial configuration? 
Please answer 'yes' or 'no'.
Do you want to use the wizard for initial configuration? no

Enable password hardening: [yes] no

New password for 'admin' account must be typed, please enter new password: 
Confirm: 
New password for 'monitor' account must be typed, please enter new password: 
Confirm: 
```

This will boot the switch to factory defaults, The next step is likely going to be [apply switch configs](apply_switch_configs.md).