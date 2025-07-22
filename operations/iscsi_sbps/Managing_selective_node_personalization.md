# Managing_selective_node_personalization

Example command(s) to manage selective worker node personalization for iSCSI SBPS:

Create HSM group:

```bash
cray hsm groups create --label iscsi_worker --description "iscsi node personalization" --members-ids x3000c0s5b0n0
```

Example output:

```text
[[results]]
URI = "/hsm/v2/groups/iscsi_worker"
```

HSM group `iscsi_worker` created with xname `x3000c0s5b0n0` added. Adding one more xname of worker node is as below:

```bash
cray hsm groups members create --id x3000c0s18b0n0 iscsi_worker
```

Example output:

```text
[[results]]
URI = "/hsm/v2/groups/iscsi_worker/members/x3000c0s18b0n0"
```

The group members of `iscsi_worker` can be listed as below:

```bash
cray hsm groups members list iscsi_worker
```

Example output:

```text
ids = [ "x3000c0s5b0n0", "x3000c0s18b0n0",]
```

Deleting the worker node from `iscsi_worker` group:

```bash
cray hsm groups members delete x3000c0s18b0n0 iscsi_worker
```

Example output:

```text
code = 0
message = "deleted 1 entry"
```

Checking the group after node deletion which shows empty list as below:


```text
# cray hsm groups members list iscsi_worker
ids = []
```

Deleting the `iscsi_worker` group:

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
`/usr/share/doc/csm/scripts/operations/configuration/refresh_worker_iscsi_config.py`
