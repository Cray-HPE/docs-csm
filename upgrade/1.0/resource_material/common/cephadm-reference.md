# CEPH Reference Material


## CEPHADM
cephadm is a new function introduced in Ceph Octopus 15.  It allows for an easier method to install and manager ceph nodes.

Common Examples:

**Invoking shells to run traditional ceph commands**

On ncn-s001/2/3:
```bash
ncn-s00[123]# cephadm shell  # creates a container with access to run ceph commands the traditional way
```

or optionally, you can execute your command
```bash
ncn-s00[123]# cephadm shell -- ceph -s
```

**CEPH-VOLUME**

There are multiple ways to do ceph device operations now.

***via cephadm***
```bash
ncn-s# cephadm ceph-volume
```
***via cephadm shell***
```bash
ncn-s# cephadm shell -- ceph-volume  # optionally you can do a cephadm shell, then run ceph-volume commands from there
```

***via ceph orch***
```
ncn-s00[123]# ceph orch device ls #  optionally you can specify a single node name to just list that nodes drives
```