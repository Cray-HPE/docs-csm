# Saving Configuration

## Write Memory

To keep track of what version of config is running on the switch create a new configuration file using the `csm version` and the `CANU version` from `motd banner` from the running config.

### Mellanox

1. Get the CSM and CANU version from the motd banner.

```
sw-spine-001 [mlag-domain: master] (config) # show banner 

Banners:
  Message of the Day (MOTD):
    
    ###############################################################################
    # CSM version:  1.0
    # CANU version: 1.1.11
    ###############################################################################
```

2. Save a configuration file with the CSM and CANU versions.

```
sw-spine-001 [mlag-domain: master] (config) # configuration write to csm1.0-canu1.1.11
```

### Dell

1. Get the csm and CANU version from the motd banner.

```
sw-leaf-bmc-001# show running-configuration | grep motd
banner motd ^C
 ###############################################################################
 # CSM version:  1.0
 # CANU version: 1.1.11
 ###############################################################################
 ```

2. Create a config file with the CSM/CANU versions.

 ```
sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0-canu1.1.11
Copy completed
 ```

### Aruba

1. Get the csm and canu version from the motd banner.

 ```
sw-leaf-bmc-001(config)# show banner motd 
###############################################################################
# CSM version:  1.2
# CANU version: 1.1.11
###############################################################################
 ```

2. Create a checkpoint with the csm/canu versions.

 ```
sw-leaf-bmc-001(config)# copy running-config checkpoint CSM1_2_CANU_1_1_11
 ```
