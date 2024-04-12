# Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

## Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the
"SAT Authentication" section of the HPE Cray EX System Admin Toolkit (SAT) product stream documentation
(`S-8031`) for instructions on how to acquire a SAT authentication token.

## Procedure

1. Obtain the user ID and passwords for system components:

   1. Obtain user ID and passwords for all the system management network switches.

   1. If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, `cls01053n00`.

   1. If the Slingshot network includes edge switches, then obtain the user ID and password for these switches.

1. Use `sat auth` to authenticate to the API gateway within SAT.

   If SAT has already been authenticated to the API gateway, then this step may be skipped.

   See the "SAT Authentication" section in the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (`S-8031`) for instructions on how to acquire a SAT authentication token.

1. Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs.

   There will be separate session templates for UANs and computes nodes.

   1. List all the session templates.

      If it is unclear what session template is in use, then proceed to the next substep.

      ```bash
      ncn-mw# cray bos sessiontemplate list
      ```

   1. Find the xname with `sat status`.

      ```bash
      ncn-mw# sat status --filter role!=management --filter enabled=true \
               --fields xname,aliases,role,subrole,"desired config"
      ```

      Example output:

      ```text
      +----------------+-----------+-------------+---------+--------------------+
      | xname          | Aliases   | Role        | SubRole | Desired Config     |
      +----------------+-----------+-------------+---------+--------------------+
      | x1000c0s0b0n0  | nid001000 | Compute     | None    | cos-config-2.3.101 |
      | x1000c0s0b0n1  | nid001001 | Compute     | None    | cos-config-2.3.101 |
      | x1000c0s0b1n0  | nid001002 | Compute     | None    | cos-config-2.3.101 |
      | x1000c0s0b1n1  | nid001003 | Compute     | None    | cos-config-2.3.101 |
      | x3000c0s23b0n0 | uan01     | Application | UAN     | uan-config-2.4.3   |
      +----------------+-----------+-------------+---------+--------------------+
      ```

   1. Find the `bos_session` value via the Configuration Framework Service (CFS).

      ```bash
      ncn-mw# cray cfs components describe XNAME --format toml | grep bos_session
      ```

      Example output:

      ```toml
      bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
      ```

   1. Find the required `templateName` value with BOS.

      ```bash
      ncn-mw# cray bos session describe BOS_SESSION --format toml | grep templateName
      ```

      Example output:

      ```toml
      templateName = "cos-2.3.101"
      ```

   1. Determine the list of xnames or role groups or HSM groups associated with the desired boot session template.

      ```bash
      ncn-mw# cray bos sessiontemplate describe SESSION_TEMPLATE_NAME --format toml | egrep "node_list|node_roles_groups|node_groups"
      ```

      Example outputs:

      ```toml
      node_list = [ "x3000c0s19b1n0", "x3000c0s19b2n0", "x3000c0s19b3n0", "x3000c0s19b4n0",]
      ```

      ```toml
      node_roles_groups = [ "Compute",]
      ```

1. Use SAT to capture state of the system before the shutdown.

   ```bash
   ncn-mw# sat bootsys shutdown --stage capture-state
   ```

1. Optional system health checks.

   **Important:** Running the System Diagnostic Utility (SDU) may take 20 to 60 minutes to run so
   start this command in one terminal session and then start another session for the other optional
   system health checks to be run while SDU is in progress.

   1. Use the System Diagnostic Utility (SDU) to capture current state of system before the shutdown.

      ```bash
      ncn-m# sdu --scenario triage --start_time '-4 hours' \
               --reason "saving state before powerdown"
      ```

      ***Important:*** If `sdu` is not installed on a particular master node, then it may be installed on a different master node.
      If it is not installed and configured
      on any master nodes, then see the SDU documentation about how to install the `cray-sdu-rda` RPM, start
      the `cray-sdu-rda` serivce, wait for the `cray-sdu-rda` service to become ready, and configure it using
      the `sdu setup` command. See the Install and Configure topics in the HPE Cray EX
      CSM System Diagnostic Utility (SDU) Installation Guide (`S-8034`).

   1. Capture the state of all nodes.

      ```bash
      ncn-mw# sat status | tee sat.status
      ```

   1. Capture the list of disabled nodes.

      ```bash
      ncn-mw# sat status --filter Enabled=false | tee sat.status.disabled
      ```

   1. Capture the list of nodes that are `off`.

      ```bash
      ncn-mw# sat status --filter State=Off | tee sat.status.off
      ```

   1. Capture the state of nodes in the workload manager.

      For example, if the system uses Slurm:

      ```bash
      ncn-mw# ssh uan01 sinfo | tee uan01.sinfo
      ```

   1. Capture the list of down nodes in the workload manager and the reason.

      ```bash
      ncn-mw# ssh nid000001-nmn sinfo --list-reasons | tee sinfo.reasons
      ```

   1. Check Ceph status.

      ```bash
      ncn-mw# ceph -s | tee ceph.status
      ```

   1. Check Kubernetes pod status for all pods.

      ```bash
      ncn-mw# kubectl get pods -o wide -A | tee k8s.pods
      ```

      Additional Kubernetes status check examples:

      ```bash
      ncn-mw# kubectl get pods -o wide -A | egrep  "CrashLoopBackOff" | tee k8s.pods.CLBO
      ncn-mw# kubectl get pods -o wide -A | egrep  "ContainerCreating" | tee k8s.pods.CC
      ncn-mw# kubectl get pods -o wide -A | egrep -v "Run|Completed" | tee k8s.pods.errors
      ```

   1. Check HSN status.

      Run `fmn_status` in the `slingshot-fabric-manager` pod and save the output to a file:

      ```bash
      ncn-mw# kubectl exec -it -n services $(kubectl get pods \
                  -l app.kubernetes.io/name=slingshot-fabric-manager -n services | tail -1 \
                  | cut -f1 -d" ") -c slingshot-fabric-manager -- fmn_status --details \
                  | tee fabric.status.details
      ```

   1. Check management switches to verify they are reachable.

      > *Note:* The switch host names depend on the system configuration.

      1. Look in `/etc/hosts` for the management network switches on this system. The names of
      all spine switches, leaf switches, leaf BMC switches, and CDU switches need to be used in
      the next step.

         ```bash
         ncn-mw# grep sw- /etc/hosts
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

      1. Ping all switches using the proper list of hostnames in the index of the for loop.

         ```bash
         ncn-mw# for switch in sw-leaf-00{1,2} sw-leaf-bmc-00{1-2} sw-spine-00{1,2} sw-cdu-00{1,2}l; do
                 while true; do
                      ping -c 1 $switch > /dev/null && break
                      echo "switch $switch is not yet up"
                      sleep 5
                  done
                  echo "switch $switch is up"
              done | tee switches
         ```

   1. Check Lustre server health.

       ```bash
       ncn-mw# ssh admin@cls01234n00.us.cray.com
       admin@cls01234n00# cscli csinfo
       admin@cls01234n00# cscli show_nodes
       admin@cls01234n00# cscli fs_info
       ```

   1. From a node which has the Lustre file system mounted.

       ```bash
       uan01# lfs check servers
       uan01# lfs df
       ```

1. Check for running sessions.

   ```bash
   ncn-mw# sat bootsys shutdown --stage session-checks | tee sat.session-checks
   ```

   Example output:

   ```text
   Checking for active BOS sessions.
   Found no active BOS sessions.
   Checking for active CFS sessions.
   Found no active CFS sessions.
   Checking for active CRUS upgrades.
   Found no active CRUS upgrades.
   Checking for active FAS actions.
   Found no active FAS actions.
   Checking for active NMD dumps.
   Found no active NMD dumps.
   Checking for active SDU sessions.
   Found no active SDU sessions.
   No active sessions exist. It is safe to proceed with the shutdown procedure.
   ```

   If active sessions are running, then either wait for them to complete or cancel the session. See the following step.

1. Cancel the running BOS sessions.

   1. Identify the BOS Sessions and associated BOA Kubernetes jobs to delete.

      Determine which BOS sessions to cancel. To cancel a BOS session, kill
      its associated Boot Orchestration Agent (BOA) Kubernetes job.

      To find a list of BOA jobs that are still running:

      ```bash
      ncn-mw# kubectl -n services get jobs|egrep -i "boa|Name"
      ```

      Output similar to the following will be returned:

      ```text
      NAME                                       COMPLETIONS   DURATION   AGE
      boa-0216d2d9-b2bc-41b0-960d-165d2af7a742   0/1           36m        36m
      boa-0dbd7adb-fe53-4cda-bf0b-c47b0c111c9f   1/1           36m        3d5h
      boa-4274b117-826a-4d8b-ac20-800fcac9afcc   1/1           36m        3d7h
      boa-504dd626-d566-4f58-9974-3c50573146d6   1/1           8m47s      3d5h
      boa-bae3fc19-7d91-44fc-a1ad-999e03f1daef   1/1           36m        3d7h
      boa-bd95dc0b-8cb2-4ad4-8673-bb4cc8cae9b0   1/1           36m        3d7h
      boa-ccdd1c29-cbd2-45df-8e7f-540d0c9cf453   1/1           35m        3d5h
      boa-e0543eb5-3445-4ee0-93ec-c53e3d1832ce   1/1           36m        3d5h
      boa-e0fca5e3-b671-4184-aa21-84feba50e85f   1/1           36m        3d5h
      ```

      Any job with a `0/1` `COMPLETIONS` column is still running and is a candidate to be forcibly deleted.
      The BOA Job ID appears in the `NAME` column.

   1. Clean up prior to BOA job deletion.

      The BOA pod mounts a ConfigMap under the name `boot-session` at the directory `/mnt/boot_session` inside the pod. This ConfigMap has a random UUID name like `e0543eb5-3445-4ee0-93ec-c53e3d1832ce`.
      Prior to deleting a BOA job, delete its ConfigMap.
      Find the BOA job's ConfigMap with the following command:

      ```bash
      ncn-mw# kubectl -n services describe job <BOA Job ID> |grep ConfigMap -A 1 -B 1
      ```

      Example:

      ```bash
      ncn-mw# kubectl -n services describe job boa-0216d2d9-b2bc-41b0-960d-165d2af7a742 |grep ConfigMap -A 1 -B 1
      ```

      Example output:

      ```text
         boot-session:
          Type:      ConfigMap (a volume populated by a ConfigMap)
          Name:      e0543eb5-3445-4ee0-93ec-c53e3d1832ce    <<< ConfigMap name. Delete this one.
      --
         ca-pubkey:
          Type:      ConfigMap (a volume populated by a ConfigMap)
          Name:      cray-configmap-ca-public-key
      ```

      Delete the ConfigMap associated with the `boot-session`, not the `ca-pubkey`.

      To delete the ConfigMap:

      ```bash
      ncn-mw# kubectl -n services delete cm <ConfigMap name>
      ```

      Example:

      ```bash
      ncn-mw# kubectl -n services delete cm e0543eb5-3445-4ee0-93ec-c53e3d1832ce
      ```

      Example output:

      ```text
      configmap "e0543eb5-3445-4ee0-93ec-c53e3d1832ce" deleted
      ```

   1. Delete the BOA jobs.

      ```bash
      ncn-mw# kubectl -n services delete job <BOA JOB ID>
      ```

      This will kill the BOA job and the BOS session associated with it.

      When a job is killed, BOA will no longer attempt to execute the operation it was attempting to perform. This does not mean that
      nothing continues to happen. If BOA has instructed a node to power on, the node will continue to power even after the BOA job
      has been killed.

   1. Delete the BOS session.
      BOS keeps track of sessions in its database. These entries need to be deleted.
      The BOS Session ID is the same as the BOA Job ID minus the prepended `boa-`
      string. Use the following command to delete the BOS database entry.

      ```bash
      ncn-mw# cray bos session delete <session ID>
      ```

      Example:

      ```bash
      ncn-mw# cray bos session delete 0216d2d9-b2bc-41b0-960d-165d2af7a742
      ```

1. Coordinate with the site to prevent new sessions from starting in the services listed.

   There is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1. Follow the vendor workload manager documentation to drain processes running on compute nodes. For Slurm, see the `scontrol` man page. For PBS Professional, see the `pbsnodes` man page.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
