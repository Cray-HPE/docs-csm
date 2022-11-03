# Ceph Deep Scrubs

During normal operation, the Ceph cluster performs deep scrubs of the placement groups (PGs) during
intervals of low I/O activity on the cluster. By default, these deep scrubs occur on a weekly
interval. Scheduling of deep scrubs is staggered across the PGs in the Ceph cluster, so that all PGs
are not deep-scrubbed at the same time.

## Ceph Deep Scrub Behavior During Outages

When one or more OSDs are down, the deep scrubbing of the PGs on those OSDs cannot be performed. If a
deep scrub of a PG is scheduled to occur while the OSD is down, the deep scrubbing will be delayed
until the OSDs are available. This commonly occurs when the storage nodes are powered down as part
of the [System Power Off Procedures](../power_management/System_Power_Off_Procedures.md).

After a prolonged power outage, for example after weekend power maintenance activities, some number
of PGs may begin a deep scrub after the system is powered on. An alert will be displayed in the Ceph
status while the deep scrub is occurring. Ceph is fully operational while that alert is present, and
the alert should clear when scrubbing is completed. The time to complete deep scrubbing depends on
the size of the cluster and the length of the outage. If the alert remains for more than a day,
contact support.

The following example output from `ceph -s` shows Ceph in a `HEALTH_WARN` state due to some deep
scrubs missed after the system was brought up after power down:

```text
  cluster:
    id:     e67366fb-7d13-4219-bdb4-44a5f7e06bf9
    health: HEALTH_WARN
            7 pgs not deep-scrubbed in time
  ...
```

Note the message accompanying the `HEALTH_WARN` state indicating `7 pgs not deep-scrubbed in time`.
This alert will clear when deep scrubbing completes.

## Viewing Ceph Deep Scrub Schedule

The `ceph pg dump` command shows information about the PGs in the Ceph cluster. This command can be
used to see the last time PGs were scrubbed and thus infer the next time they will be scrubbed. For
example, the following command will get the last deep scrub time for each PG, convert it to the day
of the week, and then count the number of PGs scheduled for deep scrub each day of the week:

```bash
ceph pg dump -f json | jq -r '.pg_map.pg_stats | .[].last_deep_scrub_stamp' | xargs -n 1 date +%A -d | sort | uniq -c
```

The output of this command will look something like the following:

```text
dumped all
     52 Friday
     89 Monday
     61 Saturday
     57 Sunday
     54 Thursday
    156 Tuesday
    116 Wednesday
```
