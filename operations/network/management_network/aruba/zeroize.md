# Erase All zeroize

Erases customer data on the management modules in a secure manner. The command prompts for confirmation of zeroization.

## Syntax

```
erase all zeroize
```

## Example Erasing Customer Data on the Management Modules in a Secure Manner

```text
switch# erase all zeroize

This will securely erase all customer data and reset the switch to factory defaults. This will initiate a reboot and render the. switch unavailable until the   zeroization is complete.This should take several minutes to one hour to complete.

Continue (y/n)?

ServiceOS Information: Version: GT.01.01.0007
Build Date: 2017-12-07 11:48:44 PST
Build ID:  ServiceOS:GT.01.01.0007:42c7d15cf7e5:201712071148 SHA: 42c7d15cf7e5af5bf1c7d8764ff673471084c2a4

######### Preparing for zeroization ################
######### Storage zeroization ######################
######### WARNING: DO NOT POWER OFF UNTIL ##########
######### ZEROIZATION IS COMPLETE ##################
######### This should take several minutes #########
######### to one hour to complete ##################
######### Restoring files ##########################

Boot Profiles:0.
Service OS Console1.
Primary Software Image [XL.10.00.0006]2.
Secondary Software Image [XL.10.00.0006]
Select profile(primary):
```

[Back to Index](../index.md)
