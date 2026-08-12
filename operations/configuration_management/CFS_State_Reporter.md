# CFS State Reporter

The CFS State Reporter is a `systemd` service installed on all nodes that allows them
to use [Automatic Configuration Management](Automatic_Configuration_Management.md).
This includes [application nodes](../../glossary.md#application-node-an),
[compute nodes](../../glossary.md#compute-node-cn),
[management nodes](../../glossary.md#management-nodes), and
[User Access Nodes](../../glossary.md#user-access-node-uan).

When a node boots, the CFS state reporter runs. It makes a CFS API call
to patch the node. This patch enables the node in CFS and clears its `state` field.

## Querying status

(`sles#`) The status of the CFS State Reporter on a node can be queried like any `systemd` service,
using `systemctl`:

```bash
systemctl status cfs-state-reporter --no-pager -l
```

Here is example output on a node where CFS State Reporter ran successfully:

```text
○ cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
     Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; preset: disabled)
     Active: inactive (dead) since Fri 2026-06-19 16:45:24 UTC; 1 month 21 days ago
   Main PID: 12443 (code=exited, status=0/SUCCESS)
        CPU: 2.382s

Jun 19 16:45:20 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:45:20 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
Jun 19 16:45:22 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:45:22 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
Jun 19 16:45:24 ncn-m001 python3[12443]: Starting new HTTPS connection (1): api-gw-service-nmn.local:443
Jun 19 16:45:24 ncn-m001 python3[12443]: https://api-gw-service-nmn.local:443 "PATCH /apis/cfs/v3/components/x3000c0s1b0n0 HTTP/1.1" 200 191
Jun 19 16:45:24 ncn-m001 python3[12443]: Zero'd configuration record for CFS component 'x3000c0s1b0n0'.
Jun 19 16:45:24 ncn-m001 systemd[1]: cfs-state-reporter.service: Deactivated successfully.
Jun 19 16:45:25 ncn-m001 systemd[1]: Finished cfs-state-reporter reports configuration level of the system.
Jun 19 16:45:25 ncn-m001 systemd[1]: cfs-state-reporter.service: Consumed 2.382s CPU time.
```

## Viewing log

(`sles#`) Like any `systemd` service, the `journalctl` command may be used to view its logs.

```bash
journalctl -u cfs-state-reporter -b
```

Here is example output from a system where CFS State Reporter ran successfully.

```text
Jun 19 16:38:47 ncn-m001 systemd[1]: Starting cfs-state-reporter reports configuration level of the system...
Jun 19 16:38:47 ncn-m001 python3[12443]: CFS Trust Bootstrapping Setup started.
Jun 19 16:38:47 ncn-m001 python3[12443]: CFS Trust Bootstrapping Setup started.
Jun 19 16:38:47 ncn-m001 python3[12443]: Starting new HTTP connection (1): api-gw-service-nmn.local:8888
Jun 19 16:38:47 ncn-m001 python3[12443]: Reattempting GET request for 'http://api-gw-service-nmn.local/meta-data?key=Global.cfs_public_key'
Jun 19 16:38:47 ncn-m001 python3[12443]: Incremented Retry for (url='/meta-data?key=Global.cfs_public_key'): RetryWithLogs(total=9, connect=9, read=10, redirect=None, status=None)
Jun 19 16:38:47 ncn-m001 python3[12443]: Retrying (RetryWithLogs(total=9, connect=9, read=10, redirect=None, status=None)) after connection broken by 'NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f346b725320>: Failed to establish a new connection: [Errno -3] Temporary failure in name resolution',)': /meta-data?key=Global.cfs_public_key
Jun 19 16:38:47 ncn-m001 python3[12443]: Starting new HTTP connection (2): api-gw-service-nmn.local:8888
Jun 19 16:38:47 ncn-m001 python3[12443]: Reattempting GET request for 'http://api-gw-service-nmn.local/meta-data?key=Global.cfs_public_key'
Jun 19 16:38:47 ncn-m001 python3[12443]: Incremented Retry for (url='/meta-data?key=Global.cfs_public_key'): RetryWithLogs(total=8, connect=8, read=10, redirect=None, status=None)
Jun 19 16:38:48 ncn-m001 python3[12443]: Retrying (RetryWithLogs(total=8, connect=8, read=10, redirect=None, status=None)) after connection broken by 'NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f346b725630>: Failed to establish a new connection: [Errno -3] Temporary failure in name resolution',)': /meta-data?key=Global.cfs_public_key
Jun 19 16:38:48 ncn-m001 python3[12443]: Starting new HTTP connection (3): api-gw-service-nmn.local:8888
Jun 19 16:38:48 ncn-m001 python3[12443]: http://api-gw-service-nmn.local:8888 "GET /meta-data?key=Global.cfs_public_key HTTP/1.1" 200 729
Jun 19 16:38:48 ncn-m001 python3[12443]: Obtained certificate from metadata service.
Jun 19 16:38:48 ncn-m001 python3[12443]: Obtained certificate from metadata service.
Jun 19 16:38:48 ncn-m001 python3[12443]: Wrote vault certificate to '/etc/ssh/trusted-user-ca-keys.pem'.
Jun 19 16:38:48 ncn-m001 python3[12443]: Wrote vault certificate to '/etc/ssh/trusted-user-ca-keys.pem'.
Jun 19 16:38:48 ncn-m001 python3[12443]: '/etc/ssh/trusted-user-ca-keys.pem' requires bootstrapping; injecting values.
Jun 19 16:38:48 ncn-m001 python3[12443]: '/etc/ssh/trusted-user-ca-keys.pem' requires bootstrapping; injecting values.
Jun 19 16:38:48 ncn-m001 python3[12443]: SSHD now trusts cfstrust certificates.
Jun 19 16:38:48 ncn-m001 python3[12443]: SSHD now trusts cfstrust certificates.
Jun 19 16:38:48 ncn-m001 python3[12443]: CFS Trust Bootstrapping Setup complete.
Jun 19 16:38:48 ncn-m001 python3[12443]: CFS Trust Bootstrapping Setup complete.
Jun 19 16:38:48 ncn-m001 python3[12443]: Attempting to set configuration status for 'x3000c0s1b0n0'
Jun 19 16:38:48 ncn-m001 python3[12443]: Attempt 1 of contacting CFS...
Jun 19 16:38:48 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:38:48 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
Jun 19 16:38:50 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:38:50 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
< 386 output lines omitted >
Jun 19 16:45:20 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:45:20 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
Jun 19 16:45:22 ncn-m001 python3[12443]: Auth returned 1:
Jun 19 16:45:22 ncn-m001 python3[12443]: Spire Token not yet available; retrying in a few seconds.
Jun 19 16:45:24 ncn-m001 python3[12443]: Starting new HTTPS connection (1): api-gw-service-nmn.local:443
Jun 19 16:45:24 ncn-m001 python3[12443]: https://api-gw-service-nmn.local:443 "PATCH /apis/cfs/v3/components/x3000c0s1b0n0 HTTP/1.1" 200 191
Jun 19 16:45:24 ncn-m001 python3[12443]: Zero'd configuration record for CFS component 'x3000c0s1b0n0'.
Jun 19 16:45:24 ncn-m001 systemd[1]: cfs-state-reporter.service: Deactivated successfully.
Jun 19 16:45:25 ncn-m001 systemd[1]: Finished cfs-state-reporter reports configuration level of the system.
Jun 19 16:45:25 ncn-m001 systemd[1]: cfs-state-reporter.service: Consumed 2.382s CPU time.
```

Note that in the above example, there are several minutes where the CFS State Reporter is looping
in an attempt to get a Spire Token. This is normal. The important thing is that it ultimately
successfully makes the patch request to CFS.

## More information

* [Automatic Configuration Management](Automatic_Configuration_Management.md)
* [Automated session flow](CFS_Flow_Diagrams.md#automated-session-flow)
* [CFS Components](CFS_Components.md)
* [Configure CSM packages with CFS](../CSM_product_management/Configure_CSM_Packages_with_CFS.md)

## Known issues

* [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md)
* [SSL Certificate Validation Issues](../../troubleshooting/known_issues/ssl_certificate_validation_issues.md)
* [Spire XName Validation Error](../../troubleshooting/known_issues/spire_xname_validation_error.md)
* [CFS Key Management and Ansible Permission Denied Errors](CFS_Key_Management.md)
* [Image boot issues](../boot_orchestration/Troubleshoot_UAN_Boot_Issues.md#image-boot-issues)
* [Known issues with NCN health checks](../../troubleshooting/known_issues/issues_with_ncn_health_checks.md)
    * [`Verify spire-agent is enabled and running`](../../troubleshooting/known_issues/issues_with_ncn_health_checks.md#verify-spire-agent-is-enabled-and-running)
    * [`cfs-state-reporter service ran successfully`](../../troubleshooting/known_issues/issues_with_ncn_health_checks.md#cfs-state-reporter-service-ran-successfully)
