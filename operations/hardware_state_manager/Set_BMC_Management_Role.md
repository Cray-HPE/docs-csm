# Set BMC Management Roles

The ability to ignore non-compute nodes (NCNs) is turned off by default. Management nodes and NCNs are also not locked by
default. The administrator must lock the NCNs and their BMCs to prevent unwanted actions from affecting these nodes. To more
easily identify the BMCs that are associated with the management nodes, they need to be marked with the `Management` role in
the Hardware State Manager (HSM), just like their associated nodes.

This section only covers marking BMCs of management nodes with the `Management` role using HSM.
For more information on locking or ignoring nodes, refer to the following sections:

* Hardware State Manager (HSM)
  * See [Lock and Unlock Nodes](Lock_and_Unlock_Management_Nodes.md).
* Firmware Action Service (FAS)
  * See [Ignore Node within FAS](../firmware/FAS_Admin_Procedures.md#ignore-management-nodes-within-fas).
* Cray Advanced Platform Monitoring and Control (CAPMC)
  * See [Ignore Nodes with CAPMC](../power_management/Ignore_Nodes_with_CAPMC.md).

## Topics

* [Prerequisites](#prerequisites)
* [When to set BMC management role](#when-to-set-bmc-management-role)
* [How to set BMC management role](#how-to-set-bmc-management-role)

## Prerequisites

The Cray Command Line Interface must be configured on the NCN where this procedure is being performed.
See [Configure the Cray CLI](../configure_cray_cli.md).

## When to set BMC management role

The BMCs of NCNs should be marked with the `Management` role as early as possible in the install/upgrade cycle to prevent unintentionally taking down a critical node.
The `Management` role on the BMCs cannot be set until after Kubernetes is running and the HSM service is operational.

(`ncn-mw#`) Check whether HSM is running with the following command:

```bash
kubectl -n services get pods | grep smd
```

Example output:

```text
cray-smd-848bcc875c-6wqsh           2/2     Running    0          9d
cray-smd-848bcc875c-hznqj           2/2     Running    0          9d
cray-smd-848bcc875c-tp6gf           2/2     Running    0          6d22h
cray-smd-init-2tnnq                 0/2     Completed  0          9d
cray-smd-postgres-0                 2/2     Running    0          19d
cray-smd-postgres-1                 2/2     Running    0          6d21h
cray-smd-postgres-2                 2/2     Running    0          19d
cray-smd-wait-for-postgres-4-7c78j  0/3     Completed  0          9d
```

The `cray-smd` pods need to be in the `Running` state, except for `cray-smd-init` and
`cray-smd-wait-for-postgres` which should be in `Completed` state.

## How to set BMC management role

Use the `cray hsm state components bulkRole update` command to perform setting roles on the BMC.

### How to set BMC management roles on all BMCs of management nodes

1. (`ncn-mw#`) Get the list of BMCs of management nodes.

   ```bash
   BMCList=$(cray hsm state components list --role Management --type Node --format json | jq -r .Components[].ID | \
                sed 's/n[0-9]*//' | tr '\n' ',' | sed 's/.$//')
   echo ${BMCList}
   ```

   Example output:

   ```text
   x3000c0s1b0,x3000c0s2b0,x3000c0s3b0,x3000c0s6b0,x3000c0s5b0,x3000c0s4b0,x3000c0s7b0,x3000c0s8b0,x3000c0s9b0
   ```

1. (`ncn-mw#`) Set the `Management` role for those BMCs.

   ```bash
   cray hsm state components bulkRole update --role Management --component-ids "${BMCList}"
   ```

   This command gives no output when it completes successfully.

### How to set BMC management roles on specific BMCs of management nodes

1. (`ncn-mw#`) Set the `Management` role for specific BMCs.

   ```bash
   cray hsm state components bulkRole update --role Management --component-ids x3000c0s8b0
   ```

   This command gives no output when it completes successfully.
