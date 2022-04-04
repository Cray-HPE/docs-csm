# CFS Key Management and Permission Denied Errors

Configuration Framework Service \(CFS\) manages its own keys separate from keys for communication between CFS and the components or images that it is configuring. These are separate from the keys used by users and should not need to be managed.

### Permission Denied Errors

If Ansible is unable to connect with its target and fails with an `Unreachable - Permission denied` error, the first place to check is the `cfs-state-reporter` on the target node.

Every booted node should be running a copy of `cfs-state-reporter`. This service is responsible for pulling down the public key. To check the status of this service, ssh to the node that CFS cannot communicate with, and run `systemctl status cfs-state-reporter`.

```
ncn-m001# systemctl status cfs-state-reporter
```

`cfs-state-reporter` should be complete, but report success. Any other state
can be an indication of a problem.

```
● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
   Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Wed 2022-01-19 18:53:45 UTC; 1s ago
  Process: 678311 ExecStart=/usr/bin/python3 ${MODULEFLAG} ${MODULENAME} (code=exited, status=0/SUCCESS)
 Main PID: 678311 (code=exited, status=0/SUCCESS)
 ```

#### `cfs-state-reporter` failed

If `cfs-state-reporter` is complete but has failed, it can safely be restarted with `systemctl restart cfs-state-reporter`, although any log messages in the status should first be noted in case they are needed for later debugging.

```
● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
   Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Thu 2022-01-13 14:41:57 UTC; 6 days ago
  Process: 14849 ExecStart=/usr/bin/python3 ${MODULEFLAG} ${MODULENAME} (code=exited, status=1/FAILURE)
 Main PID: 14849 (code=exited, status=1/FAILURE)
 ```

#### `cfs-state-reporter` still running

`cfs-state-reporter` may also still be in a running state. In this case it is likely waiting either to authenticate or to pull down the SSH key. The service can safely be restarted as with the failure case, but this is less likely to be successful.

If the log messages indicate problems communicating with Spire, checking the health of the Spire service on the node is the next step. See [Troubleshoot Spire Failing to Start on NCNs](../spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md) for more information on troubleshooting Spire.

If there are errors indicating failure to communicate with the Boot Script Service (BSS) or the metadata service, check the health of BSS with `kubectl -n services logs deployment/cray-bss -c cray-bss` and the health of `cfs-trust` with `kubectl -n services logs deployment/cfs-trust -c cfs-trust`.
