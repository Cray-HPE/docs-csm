# `iuf activity` Examples

(`ncn-m001#`) Display an activity.

```bash
iuf -a joe-install-20230107-2 activity
+----------------------------------------------------------------------------------------------------------------------------------------+
| Activity: joe-install-20230107-2                                                                                                       |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
| start               | activity state | IUF sessionid                                       | Status | Duration | Comment               |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
| 2023-01-07t21:58:25 | in_progress    | joe-install-20230107-2u0sil-process-media-8lqms     | n/a    | 0:01:35  | Run process-media     |
| 2023-01-07t22:00:00 | waiting_admin  | None                                                | n/a    | 0:37:15  | None                  |
| 2023-01-07t22:37:15 | in_progress    | joe-install-20230107-2rr78c-pre-install-check-nn9hs | n/a    | 0:00:25  | Run pre-install-check |
| 2023-01-07t22:37:40 | waiting_admin  | None                                                | n/a    | 1:02:52  | None                  |
| 2023-01-07t23:40:32 | in_progress    | joe-install-20230107-2kq3cr-deliver-product-qfj9s   | n/a    | 0:07:16  | Run deliver-product   |
| 2023-01-07t23:47:48 | waiting_admin  | None                                                | n/a    | 22:12:43 | None                  |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
```

(`ncn-m001#`) Create a new activity state.

```bash
iuf -a joe-install-20230107-2 activity --create --comment "test 1" debug
+----------------------------------------------------------------------------------------------------------------------------------------+
| Activity: joe-install-20230107-2                                                                                                       |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
| start               | activity state | IUF sessionid                                       | Status | Duration | Comment               |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
| 2023-01-07t21:58:25 | in_progress    | joe-install-20230107-2u0sil-process-media-8lqms     | n/a    | 0:01:35  | Run process-media     |
| 2023-01-07t22:00:00 | waiting_admin  | None                                                | n/a    | 0:37:15  | None                  |
| 2023-01-07t22:37:15 | in_progress    | joe-install-20230107-2rr78c-pre-install-check-nn9hs | n/a    | 0:00:25  | Run pre-install-check |
| 2023-01-07t22:37:40 | waiting_admin  | None                                                | n/a    | 1:02:52  | None                  |
| 2023-01-07t23:40:32 | in_progress    | joe-install-20230107-2kq3cr-deliver-product-qfj9s   | n/a    | 0:07:16  | Run deliver-product   |
| 2023-01-07t23:47:48 | waiting_admin  | None                                                | n/a    | 22:26:27 | None                  |
| 2023-01-08t22:14:15 | debug          | None                                                | n/a    | 0:00:00  | test 1                |
+---------------------+----------------+-----------------------------------------------------+--------+----------+-----------------------+
```

(`ncn-m001#`) Edit the comment associated with an existing entry.

```bash
iuf -a joe-install-20230107-2 activity --time 2023-01-08t22:14:15 --comment "test 3" debug
+-----------------------------------------------------------------------------------------------------------------------------------------+
| Activity: joe-install-20230107-2                                                                                                        |
+---------------------+----------------+-----------------------------------------------------+---------+----------+-----------------------+
| start               | activity state | IUF sessionid                                       | Status  | Duration | Comment               |
+---------------------+----------------+-----------------------------------------------------+---------+----------+-----------------------+
| 2023-01-07t21:58:25 | in_progress    | joe-install-20230107-2u0sil-process-media-8lqms     | n/a     | 0:01:35  | Run process-media     |
| 2023-01-07t22:00:00 | waiting_admin  | None                                                | n/a     | 0:37:15  | None                  |
| 2023-01-07t22:37:15 | in_progress    | joe-install-20230107-2rr78c-pre-install-check-nn9hs | n/a     | 0:00:25  | Run pre-install-check |
| 2023-01-07t22:37:40 | waiting_admin  | None                                                | n/a     | 1:02:52  | None                  |
| 2023-01-07t23:40:32 | in_progress    | joe-install-20230107-2kq3cr-deliver-product-qfj9s   | n/a     | 0:07:16  | Run deliver-product   |
| 2023-01-07t23:47:48 | waiting_admin  | None                                                | n/a     | 22:26:27 | None                  |
| 2023-01-08t22:14:15 | debug          | None                                                | n/a     | 0:00:40  | test 3                |
+---------------------+----------------+-----------------------------------------------------+---------+----------+-----------------------+
```
