# `managed-nodes-rollout`

The `managed-nodes-rollout` stage performs a reboot of the managed compute and application nodes in order to reboot them
to a new image and configuration. [BOS][bos] v2 is used to perform the reboot.
The reboot operations use the [BOS session templates](../../boot_orchestration/Session_Templates.md) created during
the `prepare-images` stage. The `-mrs stage` argument is only valid for compute nodes, since application nodes are not
controlled
by workload manager software. The `-mrs reboot` argument will reboot all compute and application nodes immediately if
the `--limit-managed-rollout` argument is not specified.

`managed-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `managed-nodes-rollout` stage changes the running state of the system.
It uses [Boot Orchestration Service (BOS)][bos] v2
[session templates](../../boot_orchestration/Session_Templates.md) to reboot
the specified [compute][cn]/[application nodes][an].

## Input

The following arguments are most often used with the `managed-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for
additional arguments.

| Input                      | `iuf` argument                                  | Description                                                                                   |
|----------------------------|-------------------------------------------------|-----------------------------------------------------------------------------------------------|
| Activity                   | `-a ACTIVITY`                                   | Activity created for the install or upgrade operations                                        |
| Managed rollout strategy   | `-mrs {reboot,stage}`                           | Reboot the managed nodes immediately or stage the new image for the WLM to reboot             |
| Limit managed rollout list | `--limit-managed-rollout LIMIT_MANAGED_ROLLOUT` | List of managed nodes to be rolled out, specified by [xnames][xname] or [HSM][hsm] node group |

## Execution details

The code executed by this stage exists within IUF. See the `managed-nodes-rollout` entry
in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files
in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

The `managed-nodes-rollout` IUF operation is deemed successful if all the initiated [BOS][bos] v2
[sessions](../../boot_orchestration/Sessions.md) are started and
completed. This operation is only deemed a failure if any of the BOS v2 sessions fail to start. Completion of this
operation does NOT mean that the nodes were able to successfully reboot or be configured via [CFS][cfs]. It simply means the
BOS v2 sessions completed. It is important to carefully read the IUF standard output (`stdout`) during this operation as a
scenario where the reboot or configuration failed on some nodes is possible.

Output like this appears at the end of the `managed-nodes-rollout` operation:

```text
INFO Session 9769d735-4037-4500-b008-00067b4822ad: 0% components succeeded, 100% components failed
ERROR cfs configuration failed: {'count': 8, 'list': 'x3000c0s29b2n0,x3000c0s29b4n0,x3000c0s31b2n0,x3000c0s29b3n0,x3000c0s31b4n0,x3000c0s31b3n0,x3000c0s31b1n0,x3000c0s29b1n0'}
```

From the perspective of `managed-nodes-rollout` this operation succeeded because the BOS v2 sessions completed, and IUF
will report it as such. However, as can be seen in the output, all eight nodes failed to configure.

Debugging resources:
To further debug why the configuration failed on the specified
nodes see [Configuration Sessions](../../configuration_management/Configuration_Sessions.md)

There are multiple resources to further [troubleshoot booting](../../../troubleshooting/README.md#booting).

See [Rolling Upgrades Using BOS](../../boot_orchestration/Rolling_Upgrades.md) for details on rebooting managed compute
and application nodes with BOS v2.

## Example

(`ncn-m001#`) Execute the `managed-nodes-rollout` stage for activity `admin-230127` using the default `stage` rollout
strategy and limiting the operation to the [HSM][hsm] node group `compute-partition-1`.

```bash
iuf -a admin-230127 run --limit-managed-rollout compute-partition-1 -r managed-nodes-rollout
```

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cmn]: ../../../glossary.md#customer-management-network-cmn
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[nc]: ../../../glossary.md#node-controller-nc
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmd]: ../../../glossary.md#node-memory-dump-nmd
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[sdu]: ../../../glossary.md#system-diagnostic-utility-sdu
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
