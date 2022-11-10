# Known issue: `kubectl logs -f` returns no space left on device

On some systems, running `kubectl logs -n <NAMESPACE> <PODNAME> -f` returns `no space left on device`.
This can be caused by a lower limit for the `sysctl` setting `fs.inotify.max_user_watches` (defaults to `65536`) in some kernel releases.
This can be fixed by increasing this setting. Note that later versions of the kernel increase this setting by default.

## Fix

Run the following command from a master node. Be sure to change the `-w ncn-w[001-0..]` argument to reflect all of the worker nodes for the system:

```bash
pdsh -w ncn-w[001-0..] 'sysctl -w fs.inotify.max_user_watches=524288'
```

Once the `sysctl` command is complete, the `kubectl logs` command should again follow the log for that pod.
