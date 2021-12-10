#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

cephadm prepare-host
cephadm ls
ceph config assimilate-conf -i /etc/ceph/ceph.conf
ceph node ls

### Begin run on each mon/mgr

cephadm adopt --style legacy --name mon.ncn-s001 --skip-pull
cephadm adopt --style legacy --name mgr.ncn-s001 --skip-pull

### End run on each mon/mgr

ceph mgr module enable cephadm
ceph orch set backend cephadm

ceph -s

ceph cephadm generate-key
ceph cephadm get-pub-key > ~/ceph.pub

# IMPORTANT:  make sure to copy the key to all nodes including itself and distribute to each utility storage node

ssh-copy-id -f -i ~/ceph.pub root@<host>

ssh-copy-id -f -i ~/ceph.pub root@ncn-s002

# Manual Check
# Now try logging into the machine, with:   "ssh 'root@ncn-s002'"
# and check to make sure that only the key(s) you wanted were added.
# End Manual Check

ceph orch host add ncn-s001
ceph orch ps
ceph orch host ls


# Begin OSD conversion. Run on each node that has OSDs

cephadm adopt --style legacy --name osd.# --skip-pull

# End OSD conversion. Run on each node that has OSDs

ceph fs ls
ceph orch apply mds cephfs 3
ceph orch ps --daemon-type mds

# remove the legacy mds
systemctl stop ceph-mds.target
rm -rf /var/lib/ceph/mds/ceph-*

# stop the ceph-rgw daemon on all hosts as the command needs the cluster status to be in HEALTH_OK

systemctl stop ceph-radosgw.target # again for each host then:
ceph orch daemon add rgw site1 zone1 --placement="<host>"

# we may have to adjust this for fresh installs as per https://docs.ceph.com/en/latest/mgr/orchestrator/
