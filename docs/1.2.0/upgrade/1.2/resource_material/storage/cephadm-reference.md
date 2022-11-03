# CEPHADM
`cephadm` is a new function introduced in Ceph Octopus 15. It allows for an easier method to install and manage Ceph nodes.

## Traditional Ceph commands

On `ncn-s001`, `ncn-s002`, or `ncn-s003`:
```bash
ncn-s# cephadm shell
```

The previous command creates a container and opens an interactive shell with access to run Ceph commands the traditional way.

Or optionally, you can execute your command as follos:
```bash
ncn-s# cephadm shell -- ceph -s
```

## Ceph Device Operations

There are multiple ways to do Ceph device operations now.

### Using `cephadm`

```bash
ncn-s# cephadm ceph-volume
```

### Using `cephadm shell`

```bash
ncn-s# cephadm shell -- ceph-volume
```

Optionally you can start a `cephadm shell`, then run `ceph-volume` commands from there. The following example shows doing this on `ncn-s002`:

```bash
ncn-s002# cephadm shell
Inferring fsid 503633ce-a0ac-11ec-b2ae-b8599ff91d22
Inferring config /var/lib/ceph/503633ce-a0ac-11ec-b2ae-b8599ff91d22/mon.ncn-s002/config
Using recent ceph image registry.local/ceph/ceph@sha256:4506cf7b74fd97978cb130cb7a390a9a06d6d68d48c84aa41eb516507b66009c
[ceph: root@ncn-s002 /]# ceph-volume
```

### Using `ceph orch`

```bash
ncn-s# ceph orch device ls
```

Optionally you can specify a single node name to just list that node's drives:

```bash
ncn-s# ceph orch device ls ncn-s002
```

