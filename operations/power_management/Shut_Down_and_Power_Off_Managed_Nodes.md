# Shut Down and Power Off Managed Nodes

Shut down and power off all managed nodes in the system. This includes compute nodes, User Access
Nodes (UANs), and any other type of managed nodes on the system. It does not include the management
nodes, which are powered off later.

## Prerequisites

The `cray` and `sat` commands must be initialized and authenticated with valid credentials for Keycloak. If these have not been prepared, then see
[Configure the Cray Command Line Interface (`cray` CLI)](../configure_cray_cli.md) and refer to the "SAT Authentication" section of the *HPE Cray EX
System Admin Toolkit (SAT) (S-8031)* product stream documentation for instructions on how to acquire a SAT authentication token.
The BOS session templates to use for shutting down all managed nodes in the system have been identified as described in [Identify BOS session templates for managed nodes](./Prepare_the_System_for_Power_Off.md#identify-bos-session-templates-for-managed-nodes).

## Procedure

1. (`ncn-m001#`) Set a variable to contain a comma-separated list of the BOS session templates to
   use to shut down managed nodes. For example:

   ```bash
   SESSION_TEMPLATES="compute-23.7.0,uan-23.7.0"
   ```

   See [Identify BOS Session Templates for Managed Nodes](Prepare_the_System_for_Power_Off.md#identify-bos-session-templates-for-managed-nodes)
   for instructions on obtaining the appropriate BOS session templates.

1. (`ncn-mw#`) Use `sat bootsys shutdown` to shut down and power off UANs and compute nodes.

   An optional `--loglevel debug` can be used to provide more information as the system shuts down. If used, it must be added after `sat` but before `bootsys`.

   **Important:** No default timeout is set for `sat bootsys shutdown --stage bos-operations`. It is infinite.
   However, if a specific timeout is required, a user can still set a custom value using the
   `--bos-shutdown-timeout BOS_SHUTDOWN_TIMEOUT` option. If a custom timeout is set, `sat` will no longer watch the
   BOS sessions once the timeout has been exceeded even if the sessions are still in progress.

   ```bash
   sat bootsys shutdown --stage bos-operations --bos-shutdown-timeout BOS_SHUTDOWN_TIMEOUT \
            --bos-templates $SESSION_TEMPLATES
   ```

   Example output:

   ```text
   Proceed with shutdown of compute nodes and UANs using BOS? [yes,no] yes
   Proceeding with shutdown of compute nodes and UANs using BOS.
   INFO: Using session templates provided by --bos-templates/bos_templates option: ['uan-23.7.0', 'compute-23.7.0']
   INFO: Started shutdown operation on BOS session templates: compute-23.7.0, uan-23.7.0.
   INFO: Waiting up to 600 seconds for sessions to complete.
   INFO: Waiting for BOS session f657296c-762e-42ce-9388-d79a723d42a1 to reach target state complete. Session template: uan-23.7.0
   INFO: Waiting for BOS session e477aeb4-0038-4a11-ac55-1e359e2e243c to reach target state complete. Session template: compute-23.7.0

   [...]

   All BOS sessions completed.
   ```

   **Note:** In certain cases, the command may display an error similar to the following:

   ```text
   ERROR: Failed to get state of nodes in session template 'UAN_SESSION_TEMPLATE': Failed to get state of nodes with role=['Application', 'Application_UAN'] for boot set 'BOOT_SET' of session template 'UAN_SESSION_TEMPLATE': GET request to URL 'https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components' failed with status code 400: Bad Request. Bad Request Detail: bad query param: Argument was not a valid HMS Role
   ```

   This is a non-fatal error and does not affect the `bos-operations` stage of `sat bootsys`.

   **Note:** In certain cases, the command may fail before reaching the displayed timeout
   and show warnings similar to the following:

   ```text
   ERROR: BOS boot timed out after 900 seconds for session templates: compute-23.7.0, uan-23.7.0.
   ERROR: Boot failed or timed out for session templates: compute-23.7.0, uan-23.7.0
   ```

    The BOS operation can still proceed even with these errors. However, the warnings
    may result in the `bos-operations` stage of the `sat bootsys` command exiting before the BOS
    operation is complete. Because of this, it is important to check the status reported by BOS in order to monitor the
    shutdown and to verify that the nodes reached the expected state. Both of these recommendations are shown
    in the remaining steps.

1. If desired, monitor status of the booting process for each BOS session.

   1. (`ncn-m001#`) Use the BOS session ID to monitor the progress of each shutdown session.

      For example, to monitor the compute node shutdown session from the previous example use the
      session ID `e477aeb4-0038-4a11-ac55-1e359e2e243c`.

      ```bash
      cray bos sessions status list --format json e477aeb4-0038-4a11-ac55-1e359e2e243c
      ```

      Example output:

      ```text
      {
        "error_summary": {},
        "managed_components_count": 12,
        "percent_failed": 0.0,
        "percent_staged": 0.0,
        "percent_successful": 0.0,
        "phases": {
          "percent_complete": 0.0,
          "percent_configuring": 0,
          "percent_powering_off": 100.0,
          "percent_powering_on": 0
        },
        "status": "running",
        "timing": {
          "duration": "0:01:37.131708",
          "start_time": "2024-01-29T00:21:30"
        }
      }
      ```

   1. (`ncn-m001#`) Check the HSM state from `sat status` of the non-management nodes.

      A node will progress through HSM states in this order: `Ready`, `Standby`, `Off`.

      ```bash
      sat status --filter role!=management --hsm-fields
      ```

      Example output:

      ```text
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      | xname          | Type | NID      | State | Flag | Enabled | Arch | Class | Role        | SubRole   | Net Type |
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      | x3209c0s13b0n0 | Node | 52593056 | Off   | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s15b0n0 | Node | 52593120 | Off   | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s17b0n0 | Node | 52593184 | Off   | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s19b0n0 | Node | 52593248 | Off   | OK   | True    | X86  | River | Application | UAN       | Sling    |
      | x3209c0s22b0n0 | Node | 52593344 | Off   | OK   | True    | X86  | River | Application | Gateway   | Sling    |
      | x3209c0s23b0n0 | Node | 52593376 | Off   | OK   | True    | X86  | River | Application | Gateway   | Sling    |
      | x9002c1s0b0n0  | Node | 1000     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b0n1  | Node | 1001     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b1n0  | Node | 1002     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s0b1n1  | Node | 1003     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b0n0  | Node | 1004     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b0n1  | Node | 1005     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b1n0  | Node | 1006     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s1b1n1  | Node | 1007     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b0n0  | Node | 1008     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b0n1  | Node | 1009     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b1n0  | Node | 1010     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      | x9002c1s2b1n1  | Node | 1011     | Off   | OK   | True    | X86  | Hill  | Compute     | Compute   | Sling    |
      +----------------+------+----------+-------+------+---------+------+-------+-------------+-----------+----------+
      ```

## Next Steps

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
