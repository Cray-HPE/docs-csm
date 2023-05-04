# Power On and Boot Compute and User Access Nodes

Use Boot Orchestration Service \(BOS\) and choose the appropriate session template to power on and boot compute and UANs.

This procedure boots all compute nodes and user access nodes \(UANs\) in the context of a full system power-up.

## Prerequisites

* All compute cabinet PDUs, servers, and switches must be powered on.
* An authentication token is required to access the API gateway and to use the `sat` command. See the "SAT Authentication" section
  of the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (`S-8031`) for instructions on how to acquire a SAT authentication token.

## Procedure

1. (`ncn-m001#`) Check whether CFS has run NCN personalization on the management nodes.

    If a node has its `Configuration Status` set to `configured`, then that node has completed all configuration layers for post-boot CFS.

    If any nodes have `Configuration Status` set to `pending`, then there should be a CFS session in progress which includes that node.

    If any nodes have `Configuration Status` set to `failed` with `Error Count` great than `0`, then the node was unable to complete a layer of configuration.

    ```bash
    sat status --filter role=management --filter enabled=true --fields \
                  xname,aliases,role,subrole,"desired config","configuration status","error count"
    ```

    Example output:

    ```text
    +----------------+----------+------------+---------+------------------+----------------------+-------------+
    | xname          | Aliases  | Role       | SubRole | Desired Config   | Configuration Status | Error Count |
    +----------------+----------+------------+---------+------------------+----------------------+-------------+
    | x3000c0s1b0n0  | ncn-m001 | Management | Master  | management-23.03 | configured           | 0           |
    | x3000c0s3b0n0  | ncn-m002 | Management | Master  | management-23.03 | configured           | 0           |
    | x3000c0s5b0n0  | ncn-m003 | Management | Master  | management-23.03 | configured           | 0           |
    | x3000c0s7b0n0  | ncn-w001 | Management | Worker  | management-23.03 | failed               | 3           |
    | x3000c0s9b0n0  | ncn-w002 | Management | Worker  | management-23.03 | failed               | 3           |
    | x3000c0s11b0n0 | ncn-w003 | Management | Worker  | management-23.03 | failed               | 3           |
    | x3000c0s13b0n0 | ncn-w004 | Management | Worker  | management-23.03 | pending              | 2           |
    | x3000c0s17b0n0 | ncn-s001 | Management | Storage | management-23.03 | configured           | 0           |
    | x3000c0s19b0n0 | ncn-s002 | Management | Storage | management-23.03 | configured           | 0           |
    | x3000c0s21b0n0 | ncn-s003 | Management | Storage | management-23.03 | configured           | 0           |
    | x3000c0s25b0n0 | ncn-w005 | Management | Worker  | management-23.03 | pending              | 2           |
    +----------------+----------+------------+---------+------------------+----------------------+-------------+
    ```

    1. If some nodes are not fully configured, then find any CFS sessions in progress.

        ```bash
        kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
        ```

        Example output:

        ```text
        cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk                    7/9     Error       0          21m
        cfs-157af6d5-b63d-48ba-9eb9-b33af9a8325d-tfj8x                    3/9     Not Ready   0          11m
        ```

        CFS sessions which are in `Not Ready` status are still in progress. CFS sessions with status `Error` had a failure in one of the layers.

    1. Inspect the Ansible logs to find a failed layer.

        ```bash
        kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible
        ```

1. (`ncn-m001#`) Check that the slingshot switches are all online.

    If BOS will be used to boot computes and if DVS is configured to use HSN, then check the fabric manager switches to ensure the switches are all online
    before attempting to boot computes.

    ```bash
    kubectl exec -it -n services "$(kubectl get pod -l app.kubernetes.io/name=slingshot-fabric-manager -n services --no-headers | head -1 | awk '{print $1}')" \
            -c slingshot-fabric-manager -- fmn_status -q
    ```

    Example output:

    ```text
    ------------------------------------------
    Topology Status
    Active: template-policy
    Health
    ------
    Runtime:HEALTHY
    Configuration:HEALTHY
    Traffic:HEALTHY
    Security:HEALTHY
    For more detailed Health - run 'fmctl get health-engines/template-policy'


    ============================
    Edge Total: 17 Online: 13, Offline: 4
    Fabric Total: 0 Online: 0, Offline: 0
    Ports Reported: 17 / 17
    ============================
    Offline Switches:
    ```

1. (`ncn-m001#`) List detailed information about the available boot orchestration service \(BOS\) session template names.

    Identify the BOS session template names (such as `"cos-2.0.x"`, `slurm`, or `uan-slurm`), and choose the appropriate compute and UAN node templates for the power on and boot.

    ```bash
    cray bos v1 sessiontemplate list
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

1. (`ncn-m001#`) To display more information about a session template, for example `cos-2.0.0`, use the `describe` option.

    ```bash
    cray bos v1 sessiontemplate describe cos-2.0.x
    ```

1. (`ncn-m001#`) Use `sat bootsys boot` to power on and boot UANs and compute nodes.

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

    Note the returned job ID for each session, for example: `"boa-79584ffe-104c-4766-b584-06c5a3a60996"`.

    **Note:** In certain cases, the command may display an error similar to the following:

    ```text
    ERROR: Failed to get state of nodes in session template 'UAN_SESSION_TEMPLATE': Failed to get state of nodes with role=['Application', 'Application_UAN'] for boot set 'BOOT_SET' of session template 'UAN_SESSION_TEMPLATE': GET request to URL 'https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components' failed with status code 400: Bad Request. Bad Request Detail: bad query param: Argument was not a valid HMS Role
    ```

    This is a non-fatal error and does not affect the `bos-operations` stage of `sat bootsys`.

    **Note:** In certain cases, the command may fail before reaching the displayed timeout
    and show warnings similar to the following:

    ```text
    WARNING: The 'kubectl wait' command failed instead of timing out. stderr: error: condition not met for jobs/boa-79584ffe-104c-4766-b584-06c5a3a60996
    ```

    The BOS operation can still proceed even with these warnings. However, the warnings
    may result in the `bos-operations` stage of the `sat bootsys` command exiting before the BOS
    operation is complete. Because of this, it is important to view the logs in order to monitor the
    boot and to verify that the nodes reached the expected state. Both of these recommendations are shown
    in the remaining steps.

1. (`ncn-m001#`) Use the job ID strings to monitor the progress of the boot job.

    **Tip:** The commands needed to monitor the progress of the job are provided in the output of the `sat bootsys boot` command.

    ```bash
    kubectl -n services logs -c boa -f --selector job-name=boa-79584ffe-104c-4766-b584-06c5a3a60996
    ```

1. (`ncn-m001#`) In another shell window, use a similar command to monitor the UAN session.

    ```bash
    kubectl -n services logs -c boa -f --selector job-name=boa-a1a697fc-e040-4707-8a44-a6aef9e4d6ea
    ```

1. Wait for compute nodes and UANs to boot and check the Configuration Framework Service \(CFS\) log for errors.

1. (`ncn-m001#`) Verify that nodes have booted and indicate `Ready`.

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

## Next step

Return to [System Power On Procedures](System_Power_On_Procedures.md) and continue with next step.
