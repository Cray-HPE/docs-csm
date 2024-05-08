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

1. Ensure `/root/.bashrc` has proper handling of `kubectl` commands on all master and worker nodes.

   **Important:** During the process of shutting down the system, there will be a point when `kubelet` will be stopped on all the master and worker
   nodes. Once `kubelet` has been stopped, any `kubectl` command on any master or worker node may not work as expected and may have a long timeout before
   failing.

   This issue can cause a slowdown for these `sat` commands which `ssh` from the `sat` pod to `ncn-m001` and the
   other nodes because the `ssh` will execute commands from `/root/.bashrc`.

      * Commands affected during the power down
         * `sat bootsys shutdown --stage platform-services`
         * `sat bootsys shutdown --stage ncn-power`

      * Commands affected during the power up
         * `sat bootsys boot --stage ncn-power`
         * `sat bootsys boot --stage platform-services`

      1. Here is a sample command in `/root/.bashrc` which sets an environment variable using the output from `kubectl` which has the problem.

         ```bash
         export DOMAIN=$(kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}'|base64 -d | grep "external:")
         ```

      1. This shows one way to correct that sample command so the environment variable will be set when `kubelet` is available and will skip setting the variable when `kubelet` is not available.

         ```bash
         if systemctl is-active -q kubelet ; then
                 export DOMAIN=$(kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}'|base64 -d | grep "external:")
         fi
         ```

1. Ensure `/root/.ssh/known_hosts` does not have `ssh` stale host key entries for any of the management nodes.

   **Important:** Many of the `sat` commands use `ssh` from a `sat` Kubernetes pod to execute commands on the management nodes. This `sat` pod
   uses the `paramiko` Python library for `ssh` and it will access `/root/.ssh/known_hosts`. If `/root/.ssh/config` or `/etc/ssh/config` has
   been configured to set `UserKnownHostsfile` to `/dev/null` or some other file and there are `ssh` host key mismatches in `/root/.ssh/known_hosts`, then
   when a `sat` command tries to use `ssh` with `paramiko`, it will fail even though an interactive `ssh` command by the root user might succeed.

   For example, the `sat bootsys shutdown --stage platform-services` command would show this type of error and fail.

   ```text
   INFO: Executing step: Stop and disable kubelet on all Kubernetes NCNs.
   ERROR: Host key for server 'ncn-w003' does not match: got 'AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCGNgIUTU7+o/+c5bD84u7/1S3xNNOd5+c/0l4vpVEehWGrjuC6IRC/KAImozzznXHhdBL7yQF2Dnh3FHGQDyko=', expected 'AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL9bwo5gmW/vX3kUQyXIDgJa4EVtCYDyntmNt43BHTM7YKn6yFe1dV59Ervi13V20OxdVECxg2hTyeTueVKvwj4='
   ERROR: Fatal error in step "Stop and disable kubelet on all Kubernetes NCNs." of platform services stop: Failed to ensure kubelet is inactive and disabled on all hosts.
   ```

   To prevent this issue from happening, remove stale `ssh` host keys from `/root/.ssh/known_hosts` before running the `sat` command.

1. (`ncn-mw#`) Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs.

   There will be separate session templates for UANs and computes nodes.

    1. List all the BOS session templates.

       If it is unclear what BOS session template is in use, proceed to the next substep.

       ```bash
       cray bos sessiontemplates list --format json | jq -r '.[].name' | sort
       ```

    1. Find the BOS session templates used most recently to boot nodes.

       ```bash
       sat status --filter role!=management --fields xname,role,subrole,"most recent session template"
       ```

       Example output:

       ```text
       +----------------+-------------+-----------+------------------------------+
       | xname          | Role        | SubRole   | Most Recent Session Template |
       +----------------+-------------+-----------+------------------------------+
       | x3209c0s13b0n0 | Application | UAN       | uan-23.7.0                   |
       | x3209c0s15b0n0 | Application | UAN       | uan-23.7.0                   |
       | x3209c0s17b0n0 | Application | UAN       | uan-23.7.0                   |
       | x3209c0s19b0n0 | Application | UAN       | uan-23.7.0                   |
       | x3209c0s22b0n0 | Application | Gateway   | MISSING                      |
       | x3209c0s23b0n0 | Application | Gateway   | MISSING                      |
       | x9002c1s0b0n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s0b0n1  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s0b1n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s0b1n1  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s1b0n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s1b0n1  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s1b1n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s1b1n1  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s2b0n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s2b0n1  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s2b1n0  | Compute     | Compute   | compute-23.7.0               |
       | x9002c1s2b1n1  | Compute     | Compute   | compute-23.7.0               |
       +----------------+-------------+-----------+------------------------------+
       ```

       **`NOTE`** When the `Most Recent Session Template` shows `MISSING`, it means the BOS session information was removed.
       Old BOS sessions are cleaned up based on the numbers of days in `cleanup_completed_session_ttl`. The default value is seven days.

       1. Check the current setting for `cleanup_completed_session_ttl`.

          ```bash
          cray bos options list | grep cleanup_completed_session_ttl
          ```

    1. Determine the list of xnames associated with the desired boot session template.

       ```bash
       cray bos sessiontemplates describe SESSION_TEMPLATE_NAME --format json | jq '.boot_sets | map({node_list, node_roles_groups, node_groups})'
       ```

       Example outputs:

       ```json
       [
         {
           "node_list": [
             "x3000c0s19b1n0",
             "x3000c0s19b2n0",
             "x3000c0s19b3n0",
             "x3000c0s19b4n0"
           ],
           "node_roles_groups": null,
           "node_groups": null
         }
       ]
       ```

       ```json
       [
         {
           "node_list": null,
           "node_roles_groups": [
             "Compute"
           ],
           "node_groups": null
         }
       ]
       ```

1. (`ncn-mw#`) Use SAT to capture state of the system before the shutdown.

    ```bash
    sat bootsys shutdown --stage capture-state
    ```

1. (`ncn-mw#`) Optional system health checks.

    1. Use the System Diagnostic Utility (SDU) to capture current state of system before the shutdown.

        **Important:** SDU may take about 45 minutes to run on a small system \(longer for large systems\).

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

    1. Capture the state of nodes in the workload manager.

        For example, if the system uses Slurm:

        ```bash
        ssh uan01 sinfo | tee -a uan01.sinfo
        ssh uan01 sinfo --list-reasons | tee -a sinfo.reasons
        ```

        For example, if the system uses PBS Pro:

        ```bash
        ssh uan01 pbsnodes -aS | tee -a pbsnodes.aS
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
        kubectl get pods -o wide -A | egrep "CrashLoopBackOff" | tee -a k8s.pods.CLBO
        kubectl get pods -o wide -A | egrep "ContainerCreating" | tee -a k8s.pods.CC
        kubectl get pods -o wide -A | egrep -v "Run|Completed" | tee -a k8s.pods.errors
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

        1. (`ncn-mw#`) Use CANU to confirm that all switches are reachable. Reachable switches have their
           version information populated in the network version report.

           Provide the password for the admin username on the management network switches.

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

        1. (Optional) (`ncn-mw#`) If CANU is not available, look in `/etc/hosts` for the management network
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

        1. (`ncn-mw#`) Ping the switches obtained in the previous step to determine if they are reachable.

           ```bash
           for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do
               echo -n "switch ${switch} is "
               ping -c 1 -W 10 $switch > /dev/null && echo "up" || echo "not up"
           done | tee -a switches
           ```

    1. (`ncn-mw#`) Check Lustre server health. See Lustre documentation for other health commands to run.

        ```bash
        ssh admin@cls01234n00.us.cray.com
        cscli csinfo
        cscli show_nodes
        cscli fs_info
        ```

    1. From a node which has the Lustre file system mounted.

        ```bash
        lfs check servers
        lfs df
        ```

1. (`ncn-mw#`) Check for running sessions.

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

    **`NOTE`** If the System Diagnostic Utility (SDU) has not been configured on master nodes, message like this will appear for the master nodes
    which are not configured for SDU. If the warning appears for all master nodes, then to enable this after the system has been powered up again,
    see the Configure section of the HPE Cray EX with CSM System Diagnostic Utility (SDU) Installation Guide to configure SDU and the optional RDA.

    ```text
    WARNING: The cray-sdu-rda container is not running on ncn-m001.
    WARNING: The cray-sdu-rda container is not running on ncn-m002.
    WARNING: The cray-sdu-rda container is not running on ncn-m003.
    ```

1. (`ncn-mw#`) Cancel the running BOS sessions.

    1. Identify the BOS sessions to delete.

        ```bash
        cray bos sessions list --format json
        ```

    1. Delete each running BOS session.

        ```bash
        cray bos sessions delete <session ID>
        ```

        Example:

        ```bash
        cray bos sessions delete 0216d2d9-b2bc-41b0-960d-165d2af7a742
        ```

1. Coordinate with the site system administrators to prevent new sessions from starting in the services listed.

    There is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1. Follow the vendor workload manager documentation to drain processes running on compute nodes.

    1. For Slurm, see the `scontrol` man page.

       Below are examples of how to drain nodes using `slurm`. The list of nodes can be copy/pasted from the `sinfo` command for nodes in an `idle` state:

       ```bash
       scontrol update NodeName=nid[001001-001003,001005] State=DRAIN Reason="Shutdown"
       ```

       ```bash
       scontrol update NodeName=ALL State=DRAIN Reason="Shutdown"
       ```

    1. For PBS Professional, see the `pbsnodes` man page.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
