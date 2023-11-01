# `iuf activity` Examples

(`ncn-m001#`) list all activities.

```bash
iuf activity
```

Example output:

```text
admin.05-15
alanm
alt-310
alt-310-2
alt-96
analytics-1.4.21
anand-150523
atif-0331
atif-2300307
atif-230216-1109
atif-230217
atif-rc3
automate-109296
automate-109761
automate-109768
automate-109797
binguma-csm-diags
binguma-csm-diags-1
binguma-csm-diags-10
binguma-csm-diags-11
[...]
```

---

(`ncn-m001#`) Display activity `admin.05-15`.

```bash
iuf -a admin.05-15 activity
```

Example output:

```text
iuf -a admin.05-15 activity
+---------------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin.05-15                                                                                                                 |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| Start                      | Category      | Command / Argo Workflow                   | Status    | Duration | Comment               |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| session: admin-05-15-zjswc |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:22:48        | in_progress   | admin-05-15-zjswc-process-media-w92fb     | Succeeded | 0:01:29  | Run process-media     |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-a5osq |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:24:17        | in_progress   | admin-05-15-a5osq-pre-install-check-ghf4s | Succeeded | 0:00:54  | Run pre-install-check |
| 2023-05-15t22:25:11        | in_progress   | admin-05-15-a5osq-deliver-product-p7rt6   | Succeeded | 0:11:25  | Run deliver-product   |
| 2023-05-15t22:36:36        | in_progress   | admin-05-15-a5osq-update-vcs-config-b8lc6 | Succeeded | 0:01:26  | Run update-vcs-config |
| 2023-05-15t22:38:02        | in_progress   | admin-05-15-a5osq-update-cfs-config-f2kww | Succeeded | 0:01:51  | Run update-cfs-config |
| 2023-05-15t22:39:53        | waiting_admin | None                                      | None      | 17:00:20 | None                  |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-sp4kz |               | command: ./iuf -i input.yaml run -r \     |           |          |                       |
|                            |               | process-media                             |           |          |                       |
| 2023-05-16t15:40:13        | in_progress   | admin-05-15-sp4kz-process-media-7n92r     | Succeeded | 0:01:32  | Run process-media     |
| 2023-05-16t15:41:45        | waiting_admin | None                                      | None      | 0:00:00  | None                  |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
Summary:
  Start time: 2023-05-15t22:22:48
  End time:   2023-05-16t15:41:45

  Time spent in sessions:
    admin-05-15-zjswc: 0:01:29
    admin-05-15-a5osq: 0:15:36
    admin-05-15-sp4kz: 0:01:32

  Stage Durations:
        process-media: 0:01:23
    pre-install-check: 0:00:41
      deliver-product: 0:11:15
    update-vcs-config: 0:01:18
    update-cfs-config: 0:01:50

  Time spent in states:
  in_progress: 0:18:37
waiting_admin: 17:00:20

  Total time: 17:18:57
```

---

(`ncn-m001#`) Create a new `debug` entry and comment for activity `admin.05-15`.

```bash
iuf -a admin.05-15 activity --create --comment "testing debug feature" debug
```

Example output:

```text
+---------------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin.05-15                                                                                                                 |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| Start                      | Category      | Command / Argo Workflow                   | Status    | Duration | Comment               |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| session: admin-05-15-zjswc |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:22:48        | in_progress   | admin-05-15-zjswc-process-media-w92fb     | Succeeded | 0:01:29  | Run process-media     |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-a5osq |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:24:17        | in_progress   | admin-05-15-a5osq-pre-install-check-ghf4s | Succeeded | 0:00:54  | Run pre-install-check |
| 2023-05-15t22:25:11        | in_progress   | admin-05-15-a5osq-deliver-product-p7rt6   | Succeeded | 0:11:25  | Run deliver-product   |
| 2023-05-15t22:36:36        | in_progress   | admin-05-15-a5osq-update-vcs-config-b8lc6 | Succeeded | 0:01:26  | Run update-vcs-config |
| 2023-05-15t22:38:02        | in_progress   | admin-05-15-a5osq-update-cfs-config-f2kww | Succeeded | 0:01:51  | Run update-cfs-config |
| 2023-05-15t22:39:53        | waiting_admin | None                                      | None      | 17:00:20 | None                  |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-sp4kz |               | command: ./iuf -i input.yaml run -r \     |           |          |                       |
|                            |               | process-media                             |           |          |                       |
| 2023-05-16t15:40:13        | in_progress   | admin-05-15-sp4kz-process-media-7n92r     | Succeeded | 0:01:32  | Run process-media     |
| 2023-05-16t15:41:45        | waiting_admin | None                                      | None      | 0:09:56  | None                  |
| 2023-05-16t15:51:41        | debug         | None                                      | n/a       | 0:00:00  | testing debug feature |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
Summary:
  Start time: 2023-05-15t22:22:48
  End time:   2023-05-16t15:51:41

  Time spent in sessions:
    admin-05-15-zjswc: 0:01:29
    admin-05-15-a5osq: 0:15:36
    admin-05-15-sp4kz: 0:11:28

  Stage Durations:
        process-media: 0:01:23
    pre-install-check: 0:00:41
      deliver-product: 0:11:15
    update-vcs-config: 0:01:18
    update-cfs-config: 0:01:50

  Time spent in states:
  in_progress: 0:18:37
waiting_admin: 17:10:16
        debug: 0:00:00

  Total time: 17:28:53
```

---

(`ncn-m001#`) Edit the comment associated with the `2023-05-16t15:51:41` entry of activity `admin.05-15`.

```bash
iuf -a admin.05-15 activity --time 2023-05-16t15:51:41 --comment "comment updated" debug
```

Example output:

```text
+---------------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin.05-15                                                                                                                 |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| Start                      | Category      | Command / Argo Workflow                   | Status    | Duration | Comment               |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
| session: admin-05-15-zjswc |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:22:48        | in_progress   | admin-05-15-zjswc-process-media-w92fb     | Succeeded | 0:01:29  | Run process-media     |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-a5osq |               | command: ./iuf -i input.yaml run -b \     |           |          |                       |
|                            |               | process-media -e update-cfs-config        |           |          |                       |
| 2023-05-15t22:24:17        | in_progress   | admin-05-15-a5osq-pre-install-check-ghf4s | Succeeded | 0:00:54  | Run pre-install-check |
| 2023-05-15t22:25:11        | in_progress   | admin-05-15-a5osq-deliver-product-p7rt6   | Succeeded | 0:11:25  | Run deliver-product   |
| 2023-05-15t22:36:36        | in_progress   | admin-05-15-a5osq-update-vcs-config-b8lc6 | Succeeded | 0:01:26  | Run update-vcs-config |
| 2023-05-15t22:38:02        | in_progress   | admin-05-15-a5osq-update-cfs-config-f2kww | Succeeded | 0:01:51  | Run update-cfs-config |
| 2023-05-15t22:39:53        | waiting_admin | None                                      | None      | 17:00:20 | None                  |
| -------------------        | -----         | -----                                     | -----     | -----    | -----                 |
| session: admin-05-15-sp4kz |               | command: ./iuf -i input.yaml run -r \     |           |          |                       |
|                            |               | process-media                             |           |          |                       |
| 2023-05-16t15:40:13        | in_progress   | admin-05-15-sp4kz-process-media-7n92r     | Succeeded | 0:01:32  | Run process-media     |
| 2023-05-16t15:41:45        | waiting_admin | None                                      | None      | 0:09:56  | None                  |
| 2023-05-16t15:51:41        | debug         | None                                      | n/a       | 0:00:00  | comment updated       |
+----------------------------+---------------+-------------------------------------------+-----------+----------+-----------------------+
Summary:
  Start time: 2023-05-15t22:22:48
  End time:   2023-05-16t15:51:41

  Time spent in sessions:
    admin-05-15-zjswc: 0:01:29
    admin-05-15-a5osq: 0:15:36
    admin-05-15-sp4kz: 0:11:28

  Stage Durations:
        process-media: 0:01:23
    pre-install-check: 0:00:41
      deliver-product: 0:11:15
    update-vcs-config: 0:01:18
    update-cfs-config: 0:01:50

  Time spent in states:
  in_progress: 0:18:37
waiting_admin: 17:10:16
        debug: 0:00:00

  Total time: 17:28:53
```
