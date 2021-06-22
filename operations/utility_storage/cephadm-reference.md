# CEPHADM Reference Material

## CEPHADM

cephadm is a new function introduced in Ceph Octopus 15.  It allows for an easier method to install and manage Ceph nodes.

Common Examples:

## INVOKING SHELLS TO RUN TRADITIONAL CEPH COMMANDS

On ncn-s001/2/3:

```bash
ncn-s00[123]# cephadm shell  # creates a container with access to run ceph commands the traditional way
```

or optionally, you can execute your command

```bash
ncn-s00[123]# cephadm shell -- ceph -s
```

## CEPH-VOLUME

There are multiple ways to do ceph device operations now.

***via cephadm***

```bash
ncn-s# cephadm ceph-volume
```

***via cephadm shell***

 Optionally this can be done by invoking a cephadm shell, appending your ceph command to the cephadm command

```bash
ncn-s# cephadm shell -- ceph-volume  
```

***via ceph orch***

Optionally the below command will allow you to specify a single node name to just list that nodes drives.

```
ncn-s00[123]# ceph orch device ls 
```

```
ncn-s00[123]# ceph orch device ls <node name>
```