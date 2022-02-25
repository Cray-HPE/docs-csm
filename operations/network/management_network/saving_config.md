# Saving Configuration

### Write memory

To keep track of what version of config is running on the switch create a new configuration file using the `csm version` and the `CANU version` from `motd banner` from the running config.

##### Mellanox
```
sw-spine-001 [mlag-domain: master] (config) # show banner 

Banners:
  Message of the Day (MOTD):
    
    ###############################################################################
    # CSM version:  1.0
    # CANU version: 1.1.11
    ###############################################################################
```
save a configuration file with the correct csm/canu versions.
```
sw-spine-001 [mlag-domain: master] (config) # configuration write to csm1.0-canu1.1.11
```
##### Dell
get the csm and canu version.
```
sw-leaf-bmc-001# show running-configuration | grep motd
banner motd ^C
 ###############################################################################
 # CSM version:  1.0
 # CANU version: 1.1.11
 ###############################################################################
 ```

Create a config file with the correct csm/canu versions.

 ```
sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0-canu1.1.11
Copy completed
 ```
##### Aruba

