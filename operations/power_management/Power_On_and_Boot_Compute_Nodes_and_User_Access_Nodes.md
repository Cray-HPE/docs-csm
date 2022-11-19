# Power On and Boot Compute and User Access Nodes

Use Boot Orchestration Service \(BOS\) and choose the appropriate session template to power on and boot compute and UANs.

This procedure boots all compute nodes and user access nodes \(UANs\) in the context of a full system power-up.

## Prerequisites

* All compute cabinet PDUs, servers, and switches must be powered on.
* An authentication token is required to access the API gateway and to use the `sat` command. See the "SAT Authentication" section
  of the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (S-8031) for instructions on how to acquire a SAT authentication token.

## Procedure

1. Check whether CFS has run NCN personalization on the management nodes.

    If a node has its `Configuration Status` set to `configured`, then that node has completed all configuration layers for post-boot CFS.

    If any nodes have `Configuration Status` set to `pending`, then there should be a CFS session in progress which includes that node.

    If any nodes have `Configuration Status` set to `failed` with `Error Count` set to `3`, then the node was unable complete a layer of configuration.

    ```bash
    ncn-m001# sat status --filter role=management --filter enabled=true --fields \
                  xname,aliases,role,subrole,"desired config","configuration status","error count"
    ```

    Example output:

    ```text
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    | xname          | Aliases  | Role       | SubRole | Desired Config      | Configuration Status | Error Count |
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    | x3000c0s1b0n0  | ncn-m001 | Management | Master  | ncn-personalization | configured           | 0           |
    | x3000c0s3b0n0  | ncn-m002 | Management | Master  | ncn-personalization | configured           | 0           |
    | x3000c0s5b0n0  | ncn-m003 | Management | Master  | ncn-personalization | configured           | 0           |
    | x3000c0s7b0n0  | ncn-w001 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s9b0n0  | ncn-w002 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s11b0n0 | ncn-w003 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s13b0n0 | ncn-w004 | Management | Worker  | ncn-personalization | pending              | 2           |
    | x3000c0s17b0n0 | ncn-s001 | Management | Storage | ncn-personalization | configured           | 0           |
    | x3000c0s19b0n0 | ncn-s002 | Management | Storage | ncn-personalization | configured           | 0           |
    | x3000c0s21b0n0 | ncn-s003 | Management | Storage | ncn-personalization | configured           | 0           |
    | x3000c0s25b0n0 | ncn-w005 | Management | Worker  | ncn-personalization | pending              | 2           |
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    ```

    1. If some nodes are not fully configured, then find any CFS sessions in progress.

        ```bash
        ncn-m001# kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
        ```

        Example output:

        ```text
        cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk                    7/9     Error       0          21m
        cfs-157af6d5-b63d-48ba-9eb9-b33af9a8325d-tfj8x                    3/9     Not Ready   0          11m
        ```

        CFS sessions which are in `Not Ready` status are still in progress. CFS sessions with status `Error` had a failure in one of the layers.

    1. Inspect all layers of Ansible configuration to find a failed layer.

        ```bash
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-0
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-1
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-2
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-3
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-4
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-5
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-6
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-7
        ncn-m001# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-8
        ```

1. List detailed information about the available boot orchestration service \(BOS\) session template names.

    Identify the BOS session template names (such as `"cos-2.0.x"`, `slurm`, or `uan-slurm`), and choose the appropriate compute and UAN node templates for the power on and boot.

    ```bash
    cray bos sessiontemplate list
    ```

    Example output:

    ```text
    [[results]]
    name = "cos-2.0.x"
    description = "BOS session template for booting compute nodes, generated by the installation"
    . . .
    name = "slurm"
    description = "BOS session template for booting compute nodes, generated by the installation"
    . . .
    name = "uan-slurm"
    description = "Template for booting UANs with Slurm"
    ```

1. To display more information about a session template, for example `cos-2.0.0`, use the `describe` option.

    ```bash
    cray bos sessiontemplate describe cos-2.0.x
    ```

1. Use `sat bootsys boot` to power on and boot UANs and compute nodes.

    **Attention:** Specify the required session template name for `COS_SESSION_TEMPLATE` and `UAN_SESSION_TEMPLATE` in the following command line.

    Use `--loglevel debug` command line option to provide more information as the system boots.

    ```bash
    sat bootsys boot --stage bos-operations \
                --bos-templates COS_SESSION_TEMPLATE,UAN_SESSION_TEMPLATE
    ```

    Example output:

    ```text
    Started boot operation on BOS session templates: cos-2.0.x, uan.
    Waiting up to 900 seconds for sessions to complete.

    Waiting for BOA k8s job with id boa-a1a697fc-e040-4707-8a44-a6aef9e4d6ea to complete. Session template: uan.
    To monitor the progress of this job, run the following command in a separate window:
        'kubectl -n services logs -c boa -f --selector job-name=boa-a1a697fc-e040-4707-8a44-a6aef9e4d6ea'

    Waiting for BOA k8s job with id boa-79584ffe-104c-4766-b584-06c5a3a60996 to complete. Session template: cos-2.0.0.
    To monitor the progress of this job, run the following command in a separate window:
        'kubectl -n services logs -c boa -f --selector job-name=boa-79584ffe-104c-4766-b584-06c5a3a60996'

    [...]

    All BOS sessions completed.
    ```

    Note the returned job ID for each session; for example: `"boa-caa15959-2402-4190-9243-150d568942f6"`

1. Use the job ID strings to monitor the progress of the boot job.

    **Tip:** The commands needed to monitor the progress of the job are provided in the output of the `sat bootsys boot` command.

    ```bash
    kubectl -n services logs -c boa -f --selector job-name=boa-caa15959-2402-4190-9243-150d568942f6
    ```

1. In another shell window, use a similar command to monitor the UAN session.

    ```bash
    kubectl -n services logs -c boa -f --selector job-name=boa-a1a697fc-e040-4707-8a44-a6aef9e4d6ea
    ```

1. Wait for compute nodes and UANs to boot and check the Configuration Framework Service \(CFS\) log for errors.

1. Verify that nodes have booted and indicate `Ready`.

    ```bash
    sat status
    ```

    Example output:

    ```text
    +----------------+------+----------+-------+------+---------+------+----------+-------------+----------+
    | xname          | Type | NID      | State | Flag | Enabled | Arch | Class    | Role        | Net Type |
    +----------------+------+----------+-------+------+---------+------+----------+-------------+----------+
    | x1000c0s0b0n0  | Node | 1001     | Ready | OK   | True    | X86  | Mountain | Compute     | Sling    |
    | x1000c0s0b0n1  | Node | 1002     | Ready | OK   | True    | X86  | Mountain | Compute     | Sling    |
    | x1000c0s0b1n0  | Node | 1003     | Ready | OK   | True    | X86  | Mountain | Compute     | Sling    |
    | x1000c0s0b1n1  | Node | 1004     | Ready | OK   | True    | X86  | Mountain | Compute     | Sling    |
    | x1000c0s1b0n0  | Node | 1005     | Ready | OK   | True    | X86  | Mountain | Compute     | Sling    |
    [...]
    ```

1. Make nodes available to customers and refer to [Validate CSM Health](../validate_csm_health.md) to check system health and status.

## Next Step

Return to [System Power On Procedures](System_Power_On_Procedures.md) and continue with next step.
