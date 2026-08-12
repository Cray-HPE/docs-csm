# CFS Batcher Crashes And Does Not Restart

Kubernetes can fail to detect that the main [CFS Batcher](../../operations/configuration_management/CFS_Batcher.md)
process has crashed. This means that Kubernetes does not restart the pod, causing Batcher to not
work until an administrator notices this and manually restarts it. In the meantime,
[CFS](../../glossary.md#configuration-framework-service-cfs)
[Automatic Configuration Management](../../operations/configuration_management/Automatic_Configuration_Management.md)
will not be operational.

## Description

There are two issues with CFS Batcher that lead to this problem:

* If Batcher is unable to get a list of [sessions](../../operations/configuration_management/CFS_Sessions.md)
  from CFS, then it crashes without retrying.
* The Batcher liveness checker does not notice if the main process has crashed.

## Symptoms

At a high level, an administrator will first notice that no CFS sessions are being created by Batcher.

(`ncn-mw#`) Looking at the Kubernetes pod log can confirm that the main process has hit a fatal exception.

```bash
kubectl logs -n services -l app.kubernetes.io/instance=cray-cfs-batcher
```

Any fatal exception will cause the main problem (batcher being crashed and not restarting). The specific
known exception above (when it fails to get a list of sessions from CFS) results in log messages
like the following:

```text
2023-09-19 06:44:29,956 - INFO - batcher.batch - Waiting for CFS to become available
2023-09-19 06:44:31,176 - ERROR - batcher.cfs.sessions - Unexpected response from CFS: 404 Client Error: Not Found for url: 
http://cray-cfs-api/v3/sessions
Traceback (most recent call last):
File "/usr/lib/python3.9/runpy.py", line 197, in _run_module_as_main
return _run_code(code, main_globals, None,
File "/usr/lib/python3.9/runpy.py", line 87, in _run_code
exec(code, run_globals)
File "/app/lib/batcher/_main_.py", line 99, in <module>
main()
File "/app/lib/batcher/_main_.py", line 82, in main
manager = BatchManager()
File "/app/lib/batcher/batch.py", line 72, in _init_
self._rebuild_state()
File "/app/lib/batcher/batch.py", line 176, in _rebuild_state
for session in sessions.iter_sessions():
File "/app/lib/batcher/cfs/sessions.py", line 63, in iter_sessions
for session in data["sessions"]:
TypeError: 'NoneType' object is not subscriptable
```

## Workaround

(`ncn-mw#`) If this issue is encountered, then batcher can be brought back to life by killing the current pod.

```bash
kubectl delete pod -n services -l app.kubernetes.io/instance=cray-cfs-batcher
```

## Fix

* This issue only exists in CSM 1.5.0, CSM 1.5.1, and CSM 1.5.2.
* The issue does not exist prior to CSM 1.5
* The issue is fixed in all CSM versions beginning with CSM 1.5.3

The fix addresses both the known crash, and the failure of the liveness checker to detect when the main process has crashed.
