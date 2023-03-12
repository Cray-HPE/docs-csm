# `iuf activity` Examples

(`ncn-m001#`) Display activity `admin-230126`.

```bash
iuf -a admin-230126 activity
```

Example output:

```text
+-----------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin-230126                                                                                                            |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| Start               | Category      | Argo Workflow                              | Status    | Duration | Comment                 |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| 2023-01-27t00:04:05 | in_progress   | admin-230126-ebjx3-process-media-cq89t     | Succeeded | 0:01:22  | Run process-media       |
| 2023-01-27t00:05:27 | in_progress   | admin-230126-cu8ei-pre-install-check-qllzx | Succeeded | 0:00:58  | Run pre-install-check   |
| 2023-01-27t00:06:25 | in_progress   | admin-230126-cu8ei-deliver-product-qd5hr   | Succeeded | 0:10:20  | Run deliver-product     |
| 2023-01-27t00:16:45 | waiting_admin | None                                       | n/a       | 0:41:15  | None                    |
| 2023-01-27t00:58:00 | paused        | None                                       | n/a       | 1:02:00  | went home to sleep      |
| 2023-01-27t02:00:00 | paused        | None                                       | n/a       | 15:05:58 | still sleeping          |
| 2023-01-27t17:05:58 | blocked       | None                                       | n/a       | 1:57:54  | waiting for new package |
| 2023-01-27t19:03:52 | in_progress   | admin-230126-7iz3n-process-media-f622g     | Succeeded | 0:01:23  | Run process-media       |
| 2023-01-27t19:05:15 | waiting_admin | None                                       | n/a       | 0:00:00  | None                    |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+

Summary:
  Start time: 2023-01-27t00:04:03
    End time: 2023-01-27t19:05:15

   in_progress: 0:14:03
 waiting_admin: 0:41:15
        paused: 16:07:58
         debug: 0:00:00
       blocked: 1:57:54

   Total time: 19:01:10
```

---

(`ncn-m001#`) Create a new `debug` entry and comment for activity `admin-230126`.

```bash
iuf -a admin-230126 activity --create --comment "testing debug feature" debug
```

Example output:

```text
+-----------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin-230126                                                                                                            |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| Start               | Category      | Argo Workflow                              | Status    | Duration | Comment                 |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| 2023-01-27t00:04:05 | in_progress   | admin-230126-ebjx3-process-media-cq89t     | Succeeded | 0:01:22  | Run process-media       |
| 2023-01-27t00:05:27 | in_progress   | admin-230126-cu8ei-pre-install-check-qllzx | Succeeded | 0:00:58  | Run pre-install-check   |
| 2023-01-27t00:06:25 | in_progress   | admin-230126-cu8ei-deliver-product-qd5hr   | Succeeded | 0:10:20  | Run deliver-product     |
| 2023-01-27t00:16:45 | waiting_admin | None                                       | n/a       | 0:41:15  | None                    |
| 2023-01-27t00:58:00 | paused        | None                                       | n/a       | 1:02:00  | went home to sleep      |
| 2023-01-27t02:00:00 | paused        | None                                       | n/a       | 15:05:58 | still sleeping          |
| 2023-01-27t17:05:58 | blocked       | None                                       | n/a       | 1:57:54  | waiting for new package |
| 2023-01-27t19:03:52 | in_progress   | admin-230126-7iz3n-process-media-f622g     | Succeeded | 0:01:23  | Run process-media       |
| 2023-01-27t19:05:15 | waiting_admin | None                                       | n/a       | 0:01:00  | None                    |
| 2023-01-27t19:06:15 | debug         | None                                       | n/a       | 0:00:00  | testing debug feature   |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+

Summary:
  Start time: 2023-01-27t00:04:03
    End time: 2023-01-27t19:06:15

   in_progress: 0:14:03
 waiting_admin: 0:42:15
        paused: 16:07:58
         debug: 0:00:00
       blocked: 1:57:54

   Total time: 19:02:10
```

---

(`ncn-m001#`) Edit the comment associated with the `2023-01-27t19:06:15` entry of activity `admin-230126`.

```bash
iuf -a admin-230126 activity --time 2023-01-27t19:06:15 --comment "comment updated" debug
```

Example output:

```text
+-----------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin-230126                                                                                                            |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| Start               | Category      | Argo Workflow                              | Status    | Duration | Comment                 |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+
| 2023-01-27t00:04:05 | in_progress   | admin-230126-ebjx3-process-media-cq89t     | Succeeded | 0:01:22  | Run process-media       |
| 2023-01-27t00:05:27 | in_progress   | admin-230126-cu8ei-pre-install-check-qllzx | Succeeded | 0:00:58  | Run pre-install-check   |
| 2023-01-27t00:06:25 | in_progress   | admin-230126-cu8ei-deliver-product-qd5hr   | Succeeded | 0:10:20  | Run deliver-product     |
| 2023-01-27t00:16:45 | waiting_admin | None                                       | n/a       | 0:41:15  | None                    |
| 2023-01-27t00:58:00 | paused        | None                                       | n/a       | 1:02:00  | went home to sleep      |
| 2023-01-27t02:00:00 | paused        | None                                       | n/a       | 15:05:58 | still sleeping          |
| 2023-01-27t17:05:58 | blocked       | None                                       | n/a       | 1:57:54  | waiting for new package |
| 2023-01-27t19:03:52 | in_progress   | admin-230126-7iz3n-process-media-f622g     | Succeeded | 0:01:23  | Run process-media       |
| 2023-01-27t19:05:15 | waiting_admin | None                                       | n/a       | 0:01:00  | None                    |
| 2023-01-27t19:06:15 | debug         | None                                       | n/a       | 0:00:00  | comment updated         |
+---------------------+---------------+--------------------------------------------+-----------+----------+-------------------------+

Summary:
  Start time: 2023-01-27t00:04:03
    End time: 2023-01-27t19:06:15

   in_progress: 0:14:03
 waiting_admin: 0:42:15
        paused: 16:07:58
         debug: 0:00:00
       blocked: 1:57:54

   Total time: 19:02:10
```
