# Power On and Boot Managed Nodes

Use the Boot Orchestration Service (BOS) and choose the appropriate session template to power on and
boot managed nodes, e.g. compute nodes and User Access Nodes (UANs).

This procedure boots all managed nodes in the context of a full system power-up.

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

1. (`ncn-m001#`) Set a variable to contain a comma-separated list of the BOS session templates to
   use to boot managed nodes. For example:

   ```bash
   SESSION_TEMPLATES="compute-23.7.0,uan-23.7.0"
   ```

   See [Identify BOS Session Templates for Managed Nodes](Prepare_the_System_for_Power_Off.md#identify-bos-session-templates-for-managed-nodes)
   for instructions on obtaining the appropriate BOS session templates.

1. (`ncn-m001#`) Use `sat bootsys boot` to power on and boot the managed nodes.

    **Important:** The default timeout for the `sat bootsys boot --stage bos-operations` command is 900 seconds.
    If it is known that the nodes take longer than this amount of time to boot, then a different value
    can be set using `--bos-boot-timeout BOS_BOOT_TIMEOUT` with a value larger than 900 for `BOS_BOOT_TIMEOUT`. Once
    this timeout has been exceeded, `sat` will no longer watch the BOS sessions even if they are still in progress.

    After this step there are several commands that can be used in other windows from where the `sat bootsys boot --stage bos-operations`
    command has been run to monitor the status of the booting process as nodes move through the phases of powering on, booting Linux,
    and applying post-boot configuration with CFS.

    Use `--loglevel debug` command line option to provide more information as the system boots.

    ```bash
    sat bootsys boot --stage bos-operations --bos-boot-timeout BOS_BOOT_TIMEOUT \
                --bos-templates $SESSION_TEMPLATES
    ```

    Example output:

    ```text
    INFO: Using session templates provided by --bos-templates/bos_templates option: ['compute-23.7.0', 'uan-23.7.0']
    INFO: Started boot operation on BOS session templates: compute-23.7.0, uan-23.7.0.
    INFO: Waiting up to 900 seconds for sessions to complete.
    INFO: Waiting for BOS session 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 to reach target state complete. Session template: compute-23.7.0
    INFO: Waiting for BOS session dacad888-e077-41f3-9ab0-65a5a45c64e5 to reach target state complete. Session template: uan-23.7.0

    [...]

    All BOS sessions completed.
    ```

    Note the BOS session ID for each session, for example: `76d4d98e-814d-4235-b756-4bdfaf3a2cb3"`.

    **Note:** In certain cases, the command may display an error similar to the following:

    ```text
    ERROR: Failed to get state of nodes in session template 'UAN_SESSION_TEMPLATE': Failed to get state of nodes with role=['Application', 'Application_UAN'] for boot set 'BOOT_SET' of session template 'UAN_SESSION_TEMPLATE': GET request to URL 'https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components' failed with status code 400: Bad Request. Bad Request Detail: bad query param: Argument was not a valid HMS Role
    ```

    This is a non-fatal error and does not affect the `bos-operations` stage of `sat bootsys`.

    **Note:** If the `BOS_BOOT_TIMEOUT` is too short for the nodes to boot, the command may timeout and show an error similar to the following:

    ```text
    ERROR: BOS boot timed out after 900 seconds for session templates: compute-23.7.0, uan-23.7.0.
    ERROR: Boot failed or timed out for session templates: compute-23.7.0, uan-23.7.0
    ```

    The BOS operation can still proceed even with these errors. However, the warnings
    may result in the `bos-operations` stage of the `sat bootsys` command exiting before the BOS
    operation is complete. Because of this, it is important to check the status reported by BOS in order to monitor the
    boot and to verify that the nodes reached the expected state using `sat status` commands. Both of these recommendations are shown
    in the remaining steps.

1. If desired, monitor status of the booting process for each BOS session.

   1. (`ncn-m001#`) Use the BOS session ID to monitor the progress of each boot session.

      For example, to monitor the compute node boot session from the previous example use the
      session ID `76d4d98e-814d-4235-b756-4bdfaf3a2cb3`.

      ```bash
      cray bos sessions status list --format json 76d4d98e-814d-4235-b756-4bdfaf3a2cb3
      ```

      The following example output shows a session in which all nodes successfully booted:

      ```json
      {
        "error_summary": {},
        "managed_components_count": 12,
        "percent_failed": 0.0,
        "percent_staged": 0.0,
        "percent_successful": 100.0,
        "phases": {
          "percent_complete": 100.0,
          "percent_configuring": 0,
          "percent_powering_off": 0,
          "percent_powering_on": 0
        },
        "status": "complete",
        "timing": {
          "duration": "0:39:07",
          "end_time": "2024-01-30T01:03:56",
          "start_time": "2024-01-30T00:24:49"
        }
      }
      ```

      In the following example, 33% of the 6 nodes had an issue and stayed in the powering_off phase
      of the boot. See below for another way to determine which nodes had this issue.

      ```json
      {
        "error_summary": {
          "The retry limit has been hit for this component, but no services have reported specific errors": {
            "count": 2,
            "list": "x3209c0s23b0n0,x3209c0s22b0n0"
          }
        },
        "managed_components_count": 6,
        "percent_failed": 33.33333333333333,
        "percent_staged": 0.0,
        "percent_successful": 66.66666666666666,
        "phases": {
          "percent_complete": 99.99999999999999,
          "percent_configuring": 0,
          "percent_powering_off": 33.33333333333333,
          "percent_powering_on": 0
        },
        "status": "complete",
        "timing": {
          "duration": "0:38:07",
          "end_time": "2024-01-30T01:02:56",
          "start_time": "2024-01-30T00:24:49"
        }
      }
      ```

   1. (`ncn-m001#`) Check the HSM state from `sat status` of the non-management nodes.

      A node will progress through HSM states in this order: `Off`, `On`, `Ready`. If a node fails to leave `Off` state or
      moves from `On` to `Off` state, it needs to be investigated. If nodes are in `Standby`, that means they had been in `Ready`,
      but stopped sending a heartbeat to HSM so transitioned to `Standby` and may need to be investigated.

      ```bash
      sat status --filter role!=management --hsm-fields
      ```

      Example output:

      ```text
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      | xname          | Type | NID      | State | Flag | Enabled | Arch | Class | Role        | SubRole   | Net Type |
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      | x3209c0s13b0n0 | Node | 52593056 | Ready | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s15b0n0 | Node | 52593120 | Ready | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s17b0n0 | Node | 52593184 | Ready | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s22b0n0 | Node | 52593344 | Off   | OK   | True    | X86  | River | Application | Gateway   | Sling    |
      | x3209c0s23b0n0 | Node | 52593376 | Off   | OK   | True    | X86  | River | Application | Gateway   | Sling    |
      | x9002c1s0b0n0  | Node | 1000     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b0n1  | Node | 1001     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b1n0  | Node | 1002     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b1n1  | Node | 1003     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b0n0  | Node | 1004     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b0n1  | Node | 1005     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b1n0  | Node | 1006     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b1n1  | Node | 1007     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b0n0  | Node | 1008     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b0n1  | Node | 1009     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b1n0  | Node | 1010     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b1n1  | Node | 1011     | Ready | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      ```

      In this example, two of the application Gateway nodes have a `State` of `Off` which means that they did not power on.

   1. (`ncn-m001#`) Check the BOS fields from `sat status`, but exclude the management nodes which are never booted with BOS.

      ```bash
      sat status --bos-fields --filter '"Most Recent BOS Session"!=MISSING'
      ```

      Example output:

      ```text
      +----------------+-------------+--------------------------------------+------------------------------+--------------------------------------------+
      | xname          | Boot Status | Most Recent BOS Session              | Most Recent Session Template | Most Recent Image                          |
      +----------------+-------------+--------------------------------------+------------------------------+--------------------------------------------+
      | x3209c0s13b0n0 | stable      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | uan-cos-2.5.120-sles15sp4.x86_64           |
      | x3209c0s15b0n0 | stable      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | uan-cos-2.5.120-sles15sp4.x86_64           |
      | x3209c0s17b0n0 | stable      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | uan-cos-2.5.120-sles15sp4.x86_64           |
      | x3209c0s19b0n0 | stable      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | uan-cos-2.5.120-sles15sp4.x86_64           |
      | x3209c0s22b0n0 | failed      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | MISSING                                    |
      | x3209c0s23b0n0 | failed      | dacad888-e077-41f3-9ab0-65a5a45c64e5 | uan-23.7.0                   | MISSING                                    |
      | x9002c1s0b0n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s0b0n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s0b1n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s0b1n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s1b0n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s1b0n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s1b1n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s1b1n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s2b0n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s2b0n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s2b1n0  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      | x9002c1s2b1n1  | stable      | 76d4d98e-814d-4235-b756-4bdfaf3a2cb3 | compute-23.7.0               | compute-cos-2.5.120-sles15sp4.x86_64       |
      +----------------+-------------+--------------------------------------+------------------------------+--------------------------------------------+
      ```

      In this example, two of the application nodes have a `Most Recent Image` of `MISSING` which means that they did not boot Linux.

   1. (`ncn-m001#`) Check the CFS fields from `sat status`, but exclude the management nodes which have CFS configurations assigned which include the string `management`.

      ```bash
      sat status --cfs-fields --filter '"Desired Config"!=*management*'
      ```

      Example output:

      ```text
      +----------------+----------------------+----------------------+-------------+
      | xname          | Desired Config       | Configuration Status | Error Count |
      +----------------+----------------------+----------------------+-------------+
      | x3209c0s13b0n0 | uan-23.7.0           | configured           | 0           |
      | x3209c0s15b0n0 | uan-23.7.0           | configured           | 0           |
      | x3209c0s17b0n0 | uan-23.7.0           | configured           | 0           |
      | x3209c0s19b0n0 | uan-23.7.0           | configured           | 0           |
      | x3209c0s22b0n0 | uan-22.11.0          | pending              | 0           |
      | x3209c0s23b0n0 | uan-22.11.0          | pending              | 0           |
      | x9002c1s0b0n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s0b0n1  | compute-23.7.0       | configured           | 0           |
      | x9002c1s0b1n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s0b1n1  | compute-23.7.0       | configured           | 0           |
      | x9002c1s1b0n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s1b0n1  | compute-23.7.0       | configured           | 0           |
      | x9002c1s1b1n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s1b1n1  | compute-23.7.0       | configured           | 0           |
      | x9002c1s2b0n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s2b0n1  | compute-23.7.0       | configured           | 0           |
      | x9002c1s2b1n0  | compute-23.7.0       | configured           | 0           |
      | x9002c1s2b1n1  | compute-23.7.0       | configured           | 0           |
      +----------------+----------------------+----------------------+-------------+
      ```

      In this example, two of the application nodes have an older `Desired Config` version than the other UANs and have a last reported `Configuration Status` of pending, meaning they have not begun their CFS configuration.

   1. (`ncn-m001#`) For any managed nodes which booted but failed the CFS configuration, check the CFS Ansible log for errors.

      ```bash
      kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
      ```

      Example output:

      ```text
      cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk                    7/9     Error       0          21m
      cfs-157af6d5-b63d-48ba-9eb9-b33af9a8325d-tfj8x                    3/9     Not Ready   0          11m
      ```

      CFS sessions which are in `Not Ready` status are still in progress. CFS sessions with status `Error` had a failure in one of the layers.

   1. (`ncn-m001#`) Inspect the Ansible logs to find a failed layer. The following example follows the logs for the session from the previous step which was in an error state.

      ```bash
      kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible
      ```

## Next step

Return to [System Power On Procedures](System_Power_On_Procedures.md) and continue with next step.
