# Cephadm Reference Material

`cephadm` is a new function introduced in Ceph Octopus 15. It allows for an easier method to install and manage Ceph nodes.

The following sections include common examples:

## Invoke Shells to Run Traditional Ceph Commands

On ncn-s001/2/3:

```bash
ncn-s00[123]# cephadm shell  # creates a container with access to run ceph commands the traditional way
```

Optionally, execute the following command:

```bash
ncn-s00[123]# cephadm shell -- ceph -s
```

## Ceph-Volume

There are multiple ways to do Ceph device operations now.

### Use `cephadm`

```bash
cephadm ceph-volume
```

### Use `cephadm shell`

Optionally, this can be done by invoking a `cephadm` shell by appending a `ceph` command to the `cephadm` command.

```bash
cephadm shell -- ceph-volume
```

### Use `ceph orch`

Optionally, the following command will allow users to specify a single node name to just list that nodes drives.

```
ncn-s00[123]# ceph orch device ls
```

```
ncn-s00[123]# ceph orch device ls <node name>
```
