# Using CANU to generate full network configuration

CANU can also generate switch config for all the switches on a network.

In order to generate network config, a valid SHCD must be passed in and system variables must be read in from either CSI output or the SLS API. 

The instructions are exactly the same as the above except there will not be a hostname and a folder must be specified for config output using the `--folder FOLDERNAME` flag.

To generate switch config run: 


```
canu -s 1.5 network config -a full --shcd FILENAME.xlsx --tabs 'INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES' --corners 'J14,T44,J14,T48,J14,T24,J14,T23' --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --folder FOLDERNAME
```


```
canu -s 1.3 network config -a full --shcd FILENAME.xlsx --tabs INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES --corners J14,T44,J14,T48,J14,T24,J14,T23 --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --folder switch_config
```

### Expected results: 

	sw-spine-001 Config Generated
	sw-spine-002 Config Generated
	sw-leaf-001 Config Generated
	sw-leaf-002 Config Generated
	sw-leaf-003 Config Generated
	sw-leaf-004 Config Generated
	sw-cdu-001 Config Generated
	sw-cdu-002 Config Generated
	sw-leaf-bmc-001 Config Generated


[Back to Index](../index.md)
