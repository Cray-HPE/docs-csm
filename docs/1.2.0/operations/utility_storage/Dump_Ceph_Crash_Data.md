# Dump Ceph Crash Data

Ceph includes an option to dump crash data. Retrieve this data to get more information on a Ceph cluster that has crashed.

## Prerequisites

Ceph is reporting the cluster \[WRN\] overall HEALTH\_WARN 1 daemons have recently crashed error in the output of the `ceph -s` or `ceph health detail` commands.

## Procedure

1. Get the Ceph crash listing and the corresponding IDs.

    ```bash
    ncn-m001# ceph crash ls
    ```

    Example output:

    ```
    ID                                                               ENTITY       NEW
    2021-02-02_13:45:18.543633Z_a31173f7-44c8-45b1-a253-80efa25b45f1 mon.ncn-s003  *
    ```

1. Get information about the crash to include in a support ticket.

    Replace the CRASH\_ID value with the ID returned in the previous step.

    ```bash
    ncn-m001# ceph crash info CRASH_ID
    ```

    Example output:

    ```
    {
        "crash_id": "2021-02-02_13:45:18.543633Z_a31173f7-44c8-45b1-a253-80efa25b45f1",
        "timestamp": "2021-02-02 13:45:18.543633Z",
        "process_name": "ceph-mon",
        "entity_name": "mon.ncn-s003",
        "ceph_version": "14.2.11-394-g9cbbc473c0",
        "utsname_hostname": "ncn-s003",
        "utsname_sysname": "Linux",
        "utsname_release": "5.3.18-24.46-default",
        "utsname_version": "#1 SMP Tue Jan 5 16:11:50 UTC 2021 (4ff469b)",
        "utsname_machine": "x86_64",
        "os_name": "SLE_HPC",
        "os_id": "15.2",
        "os_version_id": "15.2",
        "os_version": "15-SP2",
        "assert_condition": "session_map.sessions.empty()",
        "assert_func": "virtual Monitor::~Monitor()",
        "assert_file": "/home/abuild/rpmbuild/BUILD/ceph-14.2.11-394-g9cbbc473c0/src/mon/Monitor.cc",
        "assert_line": 267,
        "assert_thread_name": "ceph-mon",
        "assert_msg": "/home/abuild/rpmbuild/BUILD/ceph-14.2.11-394-g9cbbc473c0/src/mon/Monitor.cc: In function 'virtual Monitor::~Monitor()' thread
         7f6f68869480 time 2021-02-02 13:45:18.538782\n/home/abuild/rpmbuild/BUILD/ceph-14.2.11-394-g9cbbc473c0/src/mon/Monitor.cc: 267: FAILED ceph_assert(session_map.sessions.empty())\n",
        "backtrace": [
            "(()+0x132d0) [0x7f6f5e9322d0]",
            "(gsignal()+0x110) [0x7f6f5da6e520]",
            "(abort()+0x151) [0x7f6f5da6fb01]",
            "(ceph::__ceph_assert_fail(char const*, char const*, int, char const*)+0x1a3) [0x7f6f5fac99f7]",
            "(ceph::__ceph_assertf_fail(char const*, char const*, int, char const*, char const*, ...)+0) [0x7f6f5fac9b81]",
            "(Monitor::~Monitor()+0x962) [0x5602667940f2]",
            "(Monitor::~Monitor()+0x9) [0x560266794169]",
            "(main()+0x289b) [0x5602667231cb]",
            "(__libc_start_main()+0xea) [0x7f6f5da5934a]",
            "(_start()+0x2a) [0x5602667526da]"
        ]
    }
    ```

1. Archive the crash data for further triage.

    This command can be used to archive all crash data, or just the data for a specific Ceph entity.

    ```bash
    ncn-m001# ceph crash archive ALL/CRASH_ID
    ```
