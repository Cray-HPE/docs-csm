# Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

## Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the "SAT Authentication" section of the
HPE Cray EX System Admin Toolkit (SAT) product stream documentation (`S-8031`) for instructions on how to acquire a SAT authentication token.

## Procedure

1. Obtain the user ID and passwords for system components:

    1. Obtain user ID and passwords for all the system management network switches.

    1. If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, `cls01053n00`.

    1. If the Slingshot network includes edge switches, obtain the user ID and password for these switches.

1. Use `sat auth` to authenticate to the API gateway within SAT.

   If SAT has already been authenticated to the API gateway, this step may be skipped.

   See the "SAT Authentication" section in the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (`S-8031`) for instructions on how to acquire a SAT authentication token.

1. (`ncn-mw#`) Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs.

   There will be separate session templates for UANs and computes nodes.

    1. List all the session templates.

       If it is unclear what session template is in use, proceed to the next substep.

       ```bash
       cray bos v2 sessiontemplates list
       ```

    1. Find the xname with `sat status`.

       ```bash
       sat status | grep "Compute\|Application"
       ```

       Example output:

       ```text
       | x3000c0s19b1n0 | Node | 1        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b2n0 | Node | 2        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b3n0 | Node | 3        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b4n0 | Node | 4        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s27b0n0 | Node | 49169248 | On    | OK   | True    | X86  | River | Application | Sling    |
       ```

    1. Find the `bos_session` value via the Configuration Framework Service (CFS).

       ```bash
       cray cfs v3 components describe XNAME --format toml | grep bos_session
       ```

       Example output:

       ```toml
       bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
       ```

    1. Find the required `templateName` value with BOS.

       ```bash
       cray bos v2 sessions describe BOS_SESSION --format toml | grep templateName
       ```

       Example output:

       ```toml
       templateName = "compute-nid1-4-sessiontemplate"
       ```

    1. Determine the list of xnames associated with the desired boot session template.

       ```bash
       cray bos v2 sessiontemplates describe SESSION_TEMPLATE_NAME | egrep "node_list|node_roles_groups|node_groups"
       ```

       Example outputs:

       ```toml
       node_list = [ "x3000c0s19b1n0", "x3000c0s19b2n0", "x3000c0s19b3n0", "x3000c0s19b4n0",]
       ```

       ```toml
       node_roles_groups = [ "Compute",]
       ```

1. (`ncn-mw#`) Use SAT to capture state of the system before the shutdown.

    ```bash
    sat bootsys shutdown --stage capture-state
    ```

1. (`ncn-mw#`) Optional system health checks.

    1. Use the System Diagnostic Utility (SDU) to capture current state of system before the shutdown.

        **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

        ```bash
        sdu --scenario triage --start_time '-4 hours' \
                 --reason "saving state before powerdown"
        ```

    1. Capture the state of all nodes.

        ```bash
        sat status | tee -a sat.status
        ```

    1. Capture the list of disabled nodes.

        ```bash
        sat status --filter Enabled=false | tee -a sat.status.disabled
        ```

    1. Capture the list of nodes that are `off`.

        ```bash
        sat status --filter State=Off | tee -a sat.status.off
        ```

    1. Capture the state of nodes in the workload manager. For example, if the system uses Slurm:

        ```bash
        ssh uan01 sinfo | tee -a uan01.sinfo
        ```

    1. Capture the list of down nodes in the workload manager and the reason.

        ```bash
        ssh uan01 sinfo --list-reasons | tee -a sinfo.reasons
        ```

    1. Check Ceph status.

        ```bash
        ceph -s | tee -a ceph.status
        ```

    1. Check Kubernetes pod status for all pods.

        ```bash
        kubectl get pods -o wide -A | tee -a k8s.pods
        ```

        Additional Kubernetes status check examples:

        ```bash
        kubectl get pods -o wide -A | egrep  "CrashLoopBackOff" > k8s.pods.CLBO
        kubectl get pods -o wide -A | egrep  "ContainerCreating" > k8s.pods.CC
        kubectl get pods -o wide -A | egrep -v "Run|Completed" > k8s.pods.errors
        ```

    1. Check HSN status.

        Determine the name of the `slingshot-fabric-manager` pod:

        ```bash
        kubectl get pods -l app.kubernetes.io/name=slingshot-fabric-manager -n services
        ```

        Example output:

        ```text
        NAME                                        READY   STATUS    RESTARTS   AGE
        slingshot-fabric-manager-5dc448779c-d8n6q   2/2     Running   0          4d21h
        ```

        Run `fmn_status` in the `slingshot-fabric-manager` pod and save the output to a file:

        ```bash
        kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \
                     -c slingshot-fabric-manager -- fmn_status --details | tee -a fabric.status
        ```

    1. Check management switches to verify they are reachable.

        > *Note:* The switch host names depend on the system configuration.

        1. Use CANU to confirm that all switches are reachable. Reachable switches will have their
           version information populated in the network version report.

           ```bash
           canu report network version
           ```

           Example output:

           ```text
           SWITCH            CANU VERSION      CSM VERSION
           sw-spine-001      1.7.1.post1       1.5
           sw-spine-002      1.7.1.post1       1.5
           sw-leaf-bmc-001   1.7.1.post1       1.5
           sw-leaf-bmc-002   1.7.1.post1       1.5
           sw-cdu-001        1.7.1.post1       1.5
           sw-cdu-002        1.7.1.post1       1.5
           ```

        1. (Optional) If CANU is not available, look in `/etc/hosts` for the management network
           switches on this system. The names of all spine switches, leaf switches, leaf BMC
           switches, and CDU switches need to be used in the next step.

           ```bash
           grep 'sw-' /etc/hosts
           ```

           Example output:

           ```text
           10.254.0.2      sw-spine-001
           10.254.0.3      sw-spine-002
           10.254.0.4      sw-leaf-bmc-001
           10.254.0.5      sw-leaf-bmc-002
           10.100.0.2      sw-cdu-001
           10.100.0.3      sw-cdu-002
           ```

        1. Ping the switches obtained in the previous step to determine if they are reachable.

           ```bash
           for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do
               echo -n "switch ${switch} is "
               ping -c 1 -W 10 $switch > /dev/null && echo "up" || echo "not up"
           done | tee -a switches
           ```

    1. Check Lustre server health.

        ```bash
        ssh admin@cls01234n00.us.cray.com
        admin@cscli show_nodes
        ```

    1. From a node which has the Lustre file system mounted.

        ```bash
        lfs check servers
        lfs df
        ```

1. (`ncn-mw#`) Check for running sessions.

   > *Note:* This step may take a longer time if there are many BOS sessions. Recommend to keep the sessions count Minimal to save overall time taken.

    ```bash
    sat bootsys shutdown --stage session-checks 2>&1 | tee -a sat.session-checks
    ```

    Example output:

    ```text
    Checking for active BOS sessions.
    Found no active BOS sessions.
    Checking for active CFS sessions.
    Found no active CFS sessions.
    Checking for active FAS actions.
    Found no active FAS actions.
    Checking for active NMD dumps.
    Found no active NMD dumps.
    Checking for active SDU sessions.
    Found no active SDU sessions.
    No active sessions exist. It is safe to proceed with the shutdown procedure.
    ```

    If active sessions are running, either wait for them to complete or cancel the session. See the following step.

1. (`ncn-mw#`) Cancel the running BOS sessions.

    1. Identify the BOS sessions to delete.

        ```bash
        cray bos v2 sessions list --format json
        ```

    1. Delete each running BOS session.

        ```bash
        cray bos v2 sessions delete <session ID>
        ```

        Example:

        ```bash
        cray bos v2 sessions delete 0216d2d9-b2bc-41b0-960d-165d2af7a742
        ```

1. Coordinate with the site to prevent new sessions from starting in the services listed.

    There is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1. Follow the vendor workload manager documentation to drain processes running on compute nodes. For Slurm, see the `scontrol` man page. For PBS Professional, see the `pbsnodes` man page.

    Below are examples of how to drain nodes using `slurm`. The list of nodes can be copy/pasted from the `sinfo` command for nodes in an `idle` state:

    ```bash
    scontrol update NodeName=nid[001001-001003,001005] State=DRAIN Reason="Shutdown"
    ```

    ```bash
    scontrol update NodeName=ALL State=DRAIN Reason="Shutdown"
    ```

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
