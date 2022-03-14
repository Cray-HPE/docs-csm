# Backup a Switch Configuration

Copies the running configuration or the startup configuration to a remote location as a file. The configuration can be exported to a file of either type CLI or type JSON format. The <VRF-NAME> is used for the configuration of interfaces on a particular VRF.

## Procedure

Create a copy of a running configuration or the startup configuration using the following command:

```
copy {running-config | startup-config} <REMOTE-URL> {cli | json} [vrf <VRF-NAME>]
```

The parameters/syntax of the `copy` command are described below:

* ``` {running-config | startup-config}```
  
  Selects whether the running configuration or the startup configuration will be copied to a remote location as a file. 

* ```<REMOTE-URL>```
  
  Specifies the remote target for copying the file. 
  
* ```{tftp | sftp}://<IP-ADDRESS>[:<PORT-NUMBER>][;blocksize=<BLOCKSIZE-VALUE>]/<FILE-NAME>{cli | json}```
  
  Selects whether the export file is in CLI or JSON format. 

* ```vrf <VRF-NAME>```
  
  Specifies the VRF to receive the interface configuration. If a VRF is not specified, the default VRF is used.


The following is an example of copying a running configuration to remote file in the CLI format:

```
switch# copy running-config tftp://192.168.1.10/runcli cli vrf default

######################################################################### 100.0%Success
```

[Back to Index](index.md)