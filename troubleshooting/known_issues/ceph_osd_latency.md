# Known Issue: Ceph OSD latency

On some systems, Ceph can begin to exhibit latency over time, and if this occurs it can eventually cause services like `slurm` and services that are backed by `etcd` clusters to exhibit slowness and possible timeouts.
In order to determine if this is occurring, run the `ceph osd perf` command on a master node over a period of about ten seconds, and if an OSD consistently shows latency of above `100ms` (as follows), the OSDs exhibiting this latency should be restarted:

(`ncn-m#`) Run the following command:

```bash
ceph osd perf
```

Example output:

```text
osd  commit_latency(ms)  apply_latency(ms)
 16                   3                  3
 29                   3                  3
 28                 178                178
 27                   6                  6
 26                   3                  3
 25                 151                151
 24                   3                  3
 23                   3                  3
 22                 146                146
 21                   6                  6
 20                 145                145
 19                 171                171
 18                   4                  4
 17                   4                  4
  5                 161                161
  4                   3                  3
  3                  18                 18
  2                   3                  3
  0                   5                  5
  1                   5                  5
  6                   3                  3
  7                 176                176
  8                   3                  3
  9                  11                 11
 10                   3                  3
 11                   4                  4
 12                   6                  6
 13                   4                  4
 14                 178                178
 15                 132                132
```

## Fix

Run the following command from a master node. It is recommended to run this command in a screen session, as this can take hours to complete depending on the state of the OSDs and how many will be restarted by the script:

(`ncn-m#`) Run the following script:

```bash
/usr/share/doc/csm/scripts/repair-ceph-latency.sh
```

Example output:

```text
INFO: no latency detected for osd.0
INFO: no latency detected for osd.1
WARNING: osd.2 average latency exceeds 100ms over 10 seconds
INFO: no latency detected for osd.3
INFO: no latency detected for osd.4
INFO: no latency detected for osd.5
INFO: no latency detected for osd.6
INFO: no latency detected for osd.7
INFO: no latency detected for osd.8
INFO: no latency detected for osd.9
INFO: no latency detected for osd.10
INFO: no latency detected for osd.11
INFO: no latency detected for osd.12
WARNING: osd.13 average latency exceeds 100ms over 10 seconds
WARNING: found at least 2 osds with latency, proceeding with restarts..
noout is set
norecover is set
nobackfill is set
Daemons for Ceph cluster fb32426e-129d-11ed-8292-1402ece3d2b8 stopped on host ncn-s001. Host ncn-s001 moved to maintenance mode
All daemons stopped, continuing...
Ceph cluster fb32426e-129d-11ed-8292-1402ece3d2b8 on ncn-s001 has exited maintenance mode
Sleeping for sixty seconds waiting for osds to be up (be patient)...
All osds up, continuing...
noout is unset
norecover is unset
nobackfill is unset
Sleeping for five seconds waiting ceph to be healthy...
Sleeping for five seconds waiting ceph to be healthy...
Ceph is healthy -- continuing...
.
.
.
SUCCESS: all restarts complete.
```

While the script is running, Ceph will be operational, but will be in a `HEALTH_WARN` state (as reported by `ceph -s`):

```text
    health: HEALTH_WARN
            1 host is in maintenance mode
            1/3 mons down, quorum ncn-s002,ncn-s003
            noout,nobackfill,norecover flag(s) set
            8 osds down
            1 OSDs or CRUSH {nodes, device-classes} have {NOUP,NODOWN,NOIN,NOOUT} fl
ags set
            1 host (8 osds) down
            Degraded data redundancy: 699417/3601342 objects degraded (19.421%), 472
 pgs degraded
```

Once the script is complete, `ceph osd perf` should no longer report higher sustained latency numbers.
