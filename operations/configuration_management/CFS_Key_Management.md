# CFS Key Management and Permission Denied Errors

The Configuration Framework Service \(CFS\) manages its own keys separate from keys for
communication between CFS and the components or images that it is configuring.
These are separate from the keys used by users and should not need to be managed.

* [`cfs-state-reporter` service]
* [Check `cfs-state-reporter` health](#check-cfs-state-reporter-health)
* [`cfs-state-reporter` problem scenarios](#cfs-state-reporter-problem-scenarios)
  * [`cfs-state-reporter` failed](#cfs-state-reporter-failed)
  * [`cfs-state-reporter` still running](#cfs-state-reporter-still-running)

## `cfs-state-reporter` service

If Ansible is unable to connect with its target and fails with an
`Unreachable - Permission denied` error, the first place to check is the
`cfs-state-reporter` service on the target node.

Every booted node should be running a copy of `cfs-state-reporter`.
One of the things this service is responsible for is pulling down the public key.

## Check `cfs-state-reporter` health

1. Log into the node that CFS cannot communicate with.

1. Check the status of `cfs-state-reporter`.

    ```console
    linux# systemctl status cfs-state-reporter
    ```

1. Check if `cfs-state-reporter` is in a good state.

    If everything is working correctly, then `cfs-state-reporter` should be complete
    (i.e. `inactive`, `dead`, and `exited`), but it should report a status of `SUCCESS`.
    Any deviation from this can be an indication of a problem. In this case, continue
    with the procedure documented on this page.

    If `cfs-state-reporter` is in a good state, then it is unlikely to be the cause
    of the permission error. In this case, the rest of this procedure is not relevant.

    Example of the first lines of `systemctl status` output on a system without a problem:

    ```text
    ● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
       Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: disabled)
       Active: inactive (dead) since Wed 2022-01-19 18:53:45 UTC; 1s ago
      Process: 678311 ExecStart=/usr/bin/python3 ${MODULEFLAG} ${MODULENAME} (code=exited, status=0/SUCCESS)
     Main PID: 678311 (code=exited, status=0/SUCCESS)
    ```

1. Capture any log messages included in the `systemctl status` command output, in case they
   are needed for later debugging.

1. Take appropriate action based on the current state of the service.

    Check each of the [`cfs-state-reporter` problem scenarios](#cfs-state-reporter-problem-scenarios) to
    determine the appropriate course of action.

## `cfs-state-reporter` problem scenarios

* [`cfs-state-reporter` failed](#cfs-state-reporter-failed)
* [`cfs-state-reporter` still running](#cfs-state-reporter-still-running)

### `cfs-state-reporter` failed

`cfs-state-reporter` may have exited in error (i.e. the status field reports `FAILURE`).

Example of the first lines of `systemctl status` output on a system where [`cfs-state-reporter` failed]:

```text
● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
   Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Thu 2022-01-13 14:41:57 UTC; 6 days ago
  Process: 14849 ExecStart=/usr/bin/python3 ${MODULEFLAG} ${MODULENAME} (code=exited, status=1/FAILURE)
 Main PID: 14849 (code=exited, status=1/FAILURE)
 ```

In this case, try restarting the service, to see if it resolves the problem.

```console
linux# systemctl restart cfs-state-reporter
```

After running the command, return to the beginning of the
[Check `cfs-state-reporter` health](#check-cfs-state-reporter-health)
procedure, to determine if the problem has been resolved.

### `cfs-state-reporter` still running

`cfs-state-reporter` may still be running. In this case it will show as `active` instead of
`inactive`, and `running` instead of `dead`. It will also not report any exit status
details.

In this case it is likely waiting either to authenticate or to pull down the SSH key. The service
can safely be restarted as with the [`cfs-state-reporter` failed](#cfs-state-reporter-failed)
case, but this is less likely to be successful.

* If the log messages indicate problems communicating with Spire, checking the health of the Spire
  service on the node is the next step. For more information, see
  [Troubleshooting Spire](../../troubleshooting/index.md#spire) and
  [Spire operational information](../index.md#spire).

* If there are errors indicating failure to communicate with the
  [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss)
  or the metadata service, then check the following things:

  > These commands are to be run on a master or worker NCN.

  * Check the health of BSS.

      ```console
      ncn-mw# kubectl -n services logs deployment/cray-bss -c cray-bss
      ```

  * Check the health of `cfs-trust`.

      ```console
      ncn-mw# kubectl -n services logs deployment/cfs-trust -c cfs-trust
      ```
