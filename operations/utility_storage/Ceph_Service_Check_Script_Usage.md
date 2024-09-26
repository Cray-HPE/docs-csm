# Ceph Service Check Script Usage

A new Ceph service script that will check the status of Ceph and then verify that status against the individual Ceph storage nodes.

## Location

`/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh`

## Usage

```text
usage:  ceph-service-status.sh # runs a simple Ceph health check
        ceph-service-status.sh -n <node> -s <service> # checks a single service on a single node
        ceph-service-status.sh -n <node> -a true # checks all Ceph services on a node
        ceph-service-status.sh -A true # checks all Ceph services on all nodes in a rolling fashion
        ceph-service-status.sh -s <service name> # will find the where the service is running and report its status
```

> **Important:** By default, the output of this command will not be verbose. This is to accommodate goss testing. For manual runs, please use the `-v true` flag.

**Troubleshooting** If the message `parse error: Invalid numeric literal at line 1, column 5` is displayed, it is indicating that the cached SSH keys in known_hosts are no longer valid. The simple fix is `> ~/.ssh/known_hosts` and re-run the script.
It will update the keys.

## Examples

### Simple Ceph Health Check

```bash
/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh -v true
```

Example output:

```bash
FSID: c84ecf41-c535-4588-96c3-f6892bbd81ce  FSID_STR: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce
Ceph is reporting a status of HEALTH_OK
Updating SSH keys..
Tests run: 1  Tests Passed: 1
```

### Service Check for a Single Service on a Single Node

```bash
/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh -n ncn-s001 -v true -s mon.ncn-s001
```

Example output:

```bash
FSID: c84ecf41-c535-4588-96c3-f6892bbd81ce  FSID_STR: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce
Ceph is reporting a status of HEALTH_OK
Updating SSH keys..

HOST: ncn-s001#######################
Service mon.ncn-s001 on ncn-s001 has been restarted and up for 9280 seconds
mon.ncn-s001's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mon.ncn-s001
Status: running
Tests run: 2  Tests Passed: 2
```

### Service Check for All Services on a Single Node

```bash
/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh -n ncn-s001 -a true -v true
```

Example output:

```bash
FSID: c84ecf41-c535-4588-96c3-f6892bbd81ce  FSID_STR: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce
Ceph is reporting a status of HEALTH_OK
Updating SSH keys..

HOST: ncn-s001#######################
Service mds.cephfs.ncn-s001.rmisfx on ncn-s001 has been restarted and up for 9206 seconds
mds.cephfs.ncn-s001.rmisfx's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mds.cephfs.ncn-s001.rmisfx
Status: running
Service mgr.ncn-s001 on ncn-s001 has been restarted and up for 9201 seconds
mgr.ncn-s001's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mgr.ncn-s001
Status: running
Service mon.ncn-s001 on ncn-s001 has been restarted and up for 9228 seconds
mon.ncn-s001's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mon.ncn-s001
Status: running
Service node-exporter.ncn-s001 on ncn-s001 has been restarted and up for 1231 seconds
node-exporter.ncn-s001's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-node-exporter.ncn-s001
Status: running
Service  on ncn-s001 is reporting up for 9209 seconds
osd.0's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.0
Status: running
Service  on ncn-s001 is reporting up for 9200 seconds
osd.11's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.11
Status: running
Service  on ncn-s001 is reporting up for 9208 seconds
osd.14's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.14
Status: running
Service  on ncn-s001 is reporting up for 9206 seconds
osd.17's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.17
Status: running
Service  on ncn-s001 is reporting up for 9213 seconds
osd.5's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.5
Status: running
Service  on ncn-s001 is reporting up for 9207 seconds
osd.8's status is reporting up: 1  in: 1
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-osd.8
Status: running
Service rgw.site1.ncn-s001.kvxhwi on ncn-s001 has been restarted and up for 9210 seconds
rgw.site1.ncn-s001.kvxhwi's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-rgw.site1.ncn-s001.kvxhwi
Status: running
Tests run: 12  Tests Passed: 12
```

### Service Check for a Service Type

```bash
/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh  -v true -s mon
```

Example output:

```bash
FSID: c84ecf41-c535-4588-96c3-f6892bbd81ce  FSID_STR: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce
Ceph is reporting a status of HEALTH_OK
Updating SSH keys..

HOST: ncn-s001#######################
Service mon on ncn-s001 has been restarted and up for 9547 seconds
mon's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mon.ncn-s001
Status: running

HOST: ncn-s002#######################
Service mon on ncn-s002 has been restarted and up for 5643 seconds
mon's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mon.ncn-s002
Status: running

HOST: ncn-s003#######################
Service mon on ncn-s003 has been restarted and up for 2588 seconds
mon's status is: running
Service unit name: ceph-c84ecf41-c535-4588-96c3-f6892bbd81ce-mon.ncn-s003
Status: running
Tests run: 4  Tests Passed: 4
```

### Service Check for All Services and All Nodes

The output of the following command is similar to the above output, except it shows all services on all nodes.
It is excluded in this case for brevity.

```bash
/opt/cray/tests/install/ncn/scripts/ceph-service-status.sh  -v true -A true
```

> **IMPORTANT:** This script can be run without the verbose flag and with an echo for the return code `echo $?`.
A return code of `0` means the check was clean. A return code of `1` or greater means that there was an issue. In the latter case, re-run the command with the `-v true` flag.
