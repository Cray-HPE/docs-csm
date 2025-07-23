# Managing Selective Node Personalization

Selective iSCSI worker node personalization uses an HSM group named `iscsi_worker` as the mechanism for an administrator
to specify which workers should be enabled as iSCSI targets. If this group does not exist, then all worker nodes will be
enabled as iSCSI targets. While it is technically possible to create this group and leave it empty, this will mean that
no worker nodes will be enabled as iSCSI targets, which in turn will mean that no managed nodes will be able to boot.
Therefore CSM generally treats it as an error if the HSM group exists but it contains no worker nodes.

Example commands to manage selective worker node personalization for iSCSI SBPS:

(`ncn-mw#`) Create HSM group:

```bash
cray hsm groups create --label iscsi_worker --description "iscsi node personalization" --members-ids x3000c0s5b0n0
```

Example output:

```json
[[results]]
URI = "/hsm/v2/groups/iscsi_worker"
```

HSM group `iscsi_worker` created with xname `x3000c0s5b0n0` added.

(`ncn-mw#`) Adding one more xname of worker node is as below:

```bash
cray hsm groups members create --id x3000c0s18b0n0 iscsi_worker
```

Example output:

```json
[[results]]
URI = "/hsm/v2/groups/iscsi_worker/members/x3000c0s18b0n0"
```

(`ncn-mw#`) The group members of `iscsi_worker` can be listed as below:

```bash
cray hsm groups members list iscsi_worker
```

Example output:

```json
ids = [ "x3000c0s5b0n0", "x3000c0s18b0n0",]
```

(`ncn-mw#`) Deleting the worker node from `iscsi_worker` group:

```bash
cray hsm groups members delete x3000c0s18b0n0 iscsi_worker
```

Example output:

```json
code = 0
message = "deleted 1 entry"
```

(`ncn-mw#`) Checking the group after node deletion which shows empty list as below:

```bash
cray hsm groups members list iscsi_worker
ids = []
```

(`ncn-mw#`) Deleting the `iscsi_worker` group:

```bash
cray hsm groups delete iscsi_worker
```

Example output:

```json
code = 0
message = "deleted 1 entry"
```

## Procedures

To avail selective worker node personalization, the procedure with `iscsi_worker` group creating differs based on the 
scenario when this is happening.

### CSM install

`iscsi_worker` HSM group needs to be created just before the `configure administrative access` [configure administrative access](../install/configure_administrative_access.md). This will take into effect when SAT bootprep creates the CFS configurations and run NCN personalization.

If creating `iscsi_worker` group is skipped and if admin wants to create post CSM install, then it requires additional
things to be taken care like updating DNS SRV and A records manually. 

### CSM Upgrade from 1.6 to 1.7

`iscsi_worker` HSM group needs to be created just before the `Management node rollout` mentioned in [upgrade CSM and additional products with IUF](../iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) 

In this case, the DNS information will have been added for all of the worker nodes back when the system was running 
CSM 1.6. So if selective worker node personalization feature is to be used, DNS SRV and A records have to be updated
manually.

### After initial CSM 1.7 install or upgrade

In the scenario where adding or removing worker NCNs, then `iscsi_worker` HSM group needs to be created before the worker nodes are added or removed.

In the scenario where `iscsi_worker` group is not created during CSM install/upgrade, then it can be created post CSM install/upgrade and also in the scenario where any modifications to the group is to be done post install/upgrade, like 
adding/removing worker nodes to/from the group, then it is required to re-run the iSCSI CFS layer on worker nodes and
update DNS SRV and A records manually.

Re-running the iSCSI CFS layer can be done using the below script:

```bash
/usr/share/doc/csm/scripts/operations/configuration/refresh_worker_iscsi_config.py
```

Also, The latest CSM documentation RPM must be installed on the node where the procedure is being performed.
See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation)
