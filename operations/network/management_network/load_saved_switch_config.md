# Load Saved Switch Configuration

This page will show you how to switch between already saved switch configurations.
To save switch configurations see the [config management](config_management.md) page.

### Aruba

View the checkpoints.  Make sure that `CSM1_0` and `CSM1_2` exist.  If they do you can proceed.
```
sw-spine-001# show checkpoint
NAME TYPE WRITER DATE(YYYY/MM/DD) IMAGE VERSION
CSM1_0 latest User 2022-01-13T16:51:37Z GL.10.08.1021
CSM1_2 latest User 2022-01-13T16:51:48Z GL.10.08.1021
startup-config startup User 2021-12-20T17:35:58Z GL.10.08.1021
```
Rollback to desired checkpoint.
```
sw-spine-001# checkpoint rollback CSM1_0
```

### Dell

### Mellanox

View the configuration files.  Make sure that `csm1.0` and `csm1.2` exist.  If they do you can proceed.
```
sw-spine-001 [standalone: master] (config) # show configuration files

csm1.0 (active)
csm1.0.bak
csm1.2
csm1.2.bak
initial
initial.bak

Active configuration: csm1.0
Unsaved changes     : yes
```
switch to desired configuration.
```
sw-spine-001 [standalone: master] (config) # configuration switch-to csm1.0 no-reboot
```