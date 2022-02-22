# Switch replacement in the VSX Cluster

To replace the VSX primary or the VSX secondary, follow this steps: 

* Make sure all cables are labelled with clear identification 
* Unplug power and all fibers, copper cables 
* Un-rack the failing unit and rack the replacement unit. 
* Power-up the unit. 
* Restore switch firmware (see note below) and configuration. 
* SSH/Console to the replacement switch and shutdown all ports: 

For example: 8320, 8325: 

> Switch# config
> 
> Switch(config)# interface 1/1/1-1/1/52 shutdown 

NOTE: Restoring firmware is required only if replacing the primary VSX member. Otherwise you can just restore configuration as VSX sync would force automatic software upgrade on secondary member: 

* Re-cable
* SSH/Console to the replacement switch and re-enable all ports: 

For example: 8320, 8325:

> Switch# config
> 
> Switch(config)# no interface 1/1/1-1/1/52 shutdown

* The switch should now enable the VSX ports, once VSX sync is completed all ports should get enabled after hold-down timer has expired. 

NOTE: If you were replacing the secondary member and did not do software upgrade prior to enabling the ports, you would experience a reboot on the secondary unit after it has detected the primary VSX member and gotten new software from it before normal ports would come up.

[Back to Index](../index.md)

