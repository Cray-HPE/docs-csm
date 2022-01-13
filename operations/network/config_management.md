# Configuration Management


This page is designed for:
- Showing users how initially save switch configs so they can be used again.
- Loading previously saved switch configs from a certain CSM version/desired version.

<span style="color:red">All of these steps should be done using an out of band connection.</span>
## Mellanox

Docs for config mgmt https://docs.nvidia.com/networking/display/Onyxv391014/Configuration+Management
This is also included in the User Manual which is included in these docs.

##### Saving configuration file from running system. (going from one CSM release to the
other for the first time.)

This should only need to be done once (Unless hardware is added or PoR config has changed) Once this configuration file has been saved you
should be able to switch between the two configuration files.

This example is a 1.0 system that's going to 1.2

-  Write current configuration to file, this copies the current running config to a binary config file.
```
(config) # configuration write to csm1.0
```
- This should create a new configuration file, you can check that this was created.
```
(config) # show configuration
files
csm1.0 (active)
initial
initial.bak
Active configuration: csm1.0
Unsaved changes : no
```
- Create a new config file for csm 1.2, when a new config file is created no data is written to it. We will boot to this new config file and
paste the CANU generated config to it.
```
(config) # configuration new csm1.2
```
- check that the configuration files contain the new csm1.2 blank config we just created.
```
(config) # show configuration
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
- Once the switch is rebooted verify the config file is correct.  It should reboot without any configuration.
```
switch-cc30b4 [standalone: master] # show configuration files
csm1.0
csm1.2 (active)
initial
initial.bak
Active configuration: csm1.2
Unsaved changes : yes
```
- Now is when we paste in the new CANU generated 1.2 config.
- Once that's completed you can save the config.
```
(config) # write memory
```
##### Reloading switch to a different CSM version config.

This process should be used when config files for the desired CSM version are currently on the switch.
In this example we will be going from CSM 1.2 to CSM 1.0 switch config
- Verify that the correct configuration file exists on the switch.
```
sw-spine-001 [mlag-domain: master] (config) # show configuration files
csm1.0
csm1.2 (active)
csm1.2.bak
initial
initial.bak
Active configuration: csm1.2
Unsaved changes : no
```
- Switch to desired config version.
```
(config) # configuration switch-to csm1.0
This requires a reboot.
Type 'yes' to confirm: yes
```
-The switch should boot to the config version typed in the previous command. You can verify that by running the following command after
the switch is booted.
```
show configuration files
csm1.0 (active)
csm1.2
csm1.2.bak
initial
initial.bak
Active configuration: csm1.0
Unsaved changes : yes
```

## Dell
All of this info can be found in the the User Guide.

##### Saving configuration file from running system. (going from one CSM release to the
other for the first time.)

This should only need to be done once (Unless hardware is added or PoR config has changed) Once this configuration file has been saved you
should be able to switch between the two configuration files.
This example is a 1.0 system that's going to 1.2
- save startup config to new xml config
```
sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0.xml
```
- Erase the startup config and reboot
```
sw-leaf-bmc-001# delete startup-configuration
Proceed to delete startup-configuration [confirm yes/no(default)]:yes
sw-leaf-bmc-001# reload
System configuration has been modified. Save? [yes/no]:no
Continuing without saving system configuration
Proceed to reboot the system? [confirm yes/no]:yes
```
- This will boot the switch to factory defaults, this is when you will paste in the new CANU generated config.
- Once that's complete you'll want to save the config and verify that both configs exist.
```
sw-cdu-001(config)# do write memory
sw-cdu-001(config)# copy config://startup.xml config://csm1.2.xml
Copy completed
sw-cdu-001(config)# dir config
Directory contents for folder: config
Date (modified) Size (bytes) Name
--------------------- ------------
------------------------------------------
2022-01-12T22:21:35Z 53441 csm1.0.xml
2022-01-12T22:34:03Z 97654 csm1.2.xml
2022-01-12T22:33:47Z 97654 startup.xml
```
#####  Reloading switch to a different CSM version config.
This process should be used when config files for the desired CSM version are currently on the switch.
In this example we will be going from CSM 1.2 to CSM 1.0 switch config
- View the current switch config files.
```
OS10(config)# dir config
Directory contents for folder: config
Date (modified) Size (bytes) Name
--------------------- ------------
------------------------------------------
2022-01-12T22:21:35Z 53441 csm1.0.xml
2022-01-12T22:34:03Z 97654 csm1.2.xml
2022-01-12T22:40:58Z 53441 startup.xml
```
- Copy the desired switch config to the startup config and reload.
```
(config)# copy config://csm1.0.xml config://startup.xml
(config)# reload
System configuration has been modified. Save? [yes/no]:no
```
- The switch will then boot to the desired config.

## Aruba

The information for config file management via checkpoints can be found from the fundamentals guide.

Maximum number of checkpoints
1. Maximum checkpoints: 64 (including the startup configuration)
1. Maximum user checkpoints: 32
1. Maximum system checkpoints: 32

##### Saving the current configuration into a checkpoint (needs be done when in both CSM1.0 and CSM1.2 configuration to save the configs in checkpoint).

- Saving configuration to a checkpoint:
```
sw-spine-001(config)# copy running-config checkpoint CSM1_0
Note: checkpoint name with special characters not allowed (only
alphanumerical, hyphen and underscore are allowed)
```
- Checking on your saved checkpoints:
```
sw-spine-001(config)# show checkpoint
NAME TYPE WRITER DATE(YYYY/MM/DD) IMAGE VERSION
CSM1_0 latest User 2022-01-13T16:51:37Z GL.10.08.1021
CSM1_2 latest User 2022-01-13T16:51:48Z GL.10.08.1021
startup-config startup User 2021-12-20T17:35:58Z GL.10.08.1021
```
Copying the existing checkpoint point to your startup config to switch between CSM 1.0 and CSM 1.2 configuration
- Copying the checkpoint to startup:
```
sw-spine-001(config)# copy checkpoint CSM1_2 startup-config
```
- Booting the system to start with configuration from different CSM version
```
sw-spine-001(config)# boot system
```
- Switch will now boot to the desired configuration.