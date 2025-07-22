# Managing selective node personalization

Example command(s) to manage selective worker node personalization for iSCSI SBPS:

(`ncn-m001#`) Create HSM group:

```bash
cray hsm groups create --label iscsi_worker --description "iscsi node personalization" --members-ids x3000c0s5b0n0
```

Example output:

```text
[[results]]
URI = "/hsm/v2/groups/iscsi_worker"
```

HSM group `iscsi_worker` created with xname `x3000c0s5b0n0` added.
(`ncn-m001#`) Adding one more xname of worker node is as below:

```bash
cray hsm groups members create --id x3000c0s18b0n0 iscsi_worker
```

Example output:

```text
[[results]]
URI = "/hsm/v2/groups/iscsi_worker/members/x3000c0s18b0n0"
```

(`ncn-m001#`) The group members of `iscsi_worker` can be listed as below:

```bash
cray hsm groups members list iscsi_worker
```

Example output:

```text
ids = [ "x3000c0s5b0n0", "x3000c0s18b0n0",]
```

(`ncn-m001#`) Deleting the worker node from `iscsi_worker` group:

```bash
cray hsm groups members delete x3000c0s18b0n0 iscsi_worker
```

Example output:

```text
code = 0
message = "deleted 1 entry"
```

(`ncn-m001#`) Checking the group after node deletion which shows empty list as below:

```bash
cray hsm groups members list iscsi_worker
ids = []
```

(`ncn-m001#`) Deleting the `iscsi_worker` group:

```bash
cray hsm groups delete iscsi_worker
```

Example output:

```text
code = 0
message = "deleted 1 entry"
```

Note: Re-run the iSCSI CFS layer on worker nodes using below script if `iscsi_worker`
group is created/modified post CSM install/upgrade:

```bash
/usr/share/doc/csm/scripts/operations/configuration/refresh_worker_iscsi_config.py
```

Also, the latest CSM documentation RPM must be installed on the node where the procedure
is being performed. See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation)
