

## Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

### Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the "SAT Authentication" section of the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (S-8031) for instructions on how to acquire a SAT authentication token.

### Procedure

1.  Obtain the user ID and passwords for system components:

    1.  Obtain user ID and passwords for all the system management network switches.

    1.  If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, `cls01053n00`.

    1.  If the Slingshot network includes edge switches, obtain the user ID and password for these switches.

1.  Use `sat auth` to authenticate to the API gateway within SAT.

    If SAT has already been authenticated to the API gateway, this step may be skipped.

    See the "SAT Authentication" section in the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (S-8031) for instructions on how to acquire a SAT authentication token.

1.  Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs.

    There will be separate session templates for UANs and computes nodes.

    1. List all the session templates.

       If it is unclear what session template is in use, proceed to the next substep.

       ```bash
       ncn# cray bos sessiontemplate list
       ```

    1. Find the xname with `sat status`.

       ```bash
       ncn# sat status | grep "Compute\|Application"
       ```

       Example output:

       ```bash
       ncn# sat status | grep "Compute\|Application"

       | x3000c0s19b1n0 | Node | 1        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b2n0 | Node | 2        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b3n0 | Node | 3        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s19b4n0 | Node | 4        | On    | OK   | True    | X86  | River | Compute     | Sling    |
       | x3000c0s27b0n0 | Node | 49169248 | On    | OK   | True    | X86  | River | Application | Sling    |
       ```

    1. Find the `bos_session` value via the Configuration Framework Service (CFS).

       ```bash
       ncn# cray cfs components describe XNAME | grep bos_session
       ```

       Example output:

       ```
       bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
       ```

    1. Find the required `templateUuid` value with BOS.

       ```bash
       ncn# cray bos session describe XNAME | grep templateUuid
       ```

       Example output:

       ```bash
       templateUuid = "compute-nid1-4-sessiontemplate"
       ```

    1. Determine the list of xnames associated with the desired boot session template.

       ```bash
       ncn# cray bos sessiontemplate describe SESSION_TEMPLATE_NAME | grep node_list
       ```

       Example output:

       ```bash
       node_list = [ "x3000c0s19b1n0", "x3000c0s19b2n0", "x3000c0s19b3n0", "x3000c0s19b4n0",]
       ```

1.  Use sat to capture state of the system before the shutdown.

    ```bash
    ncn# sat bootsys shutdown --stage capture-state
    ```

1.  Optional system health checks.

    1.  Use the System Diagnostic Utility (SDU) to capture current state of system before the shutdown.

        **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

        ```bash
        ncn# sdu --scenario triage --start_time '-4 hours' \
             --reason "saving state before powerdown/up"
        ```

    1.  Capture the state of all nodes.

        ```bash
        ncn# sat status | tee sat.status.off
        ```

    1.  Capture the list of disabled nodes.

        ```bash
        ncn# sat status --filter Enabled=false | tee sat.status.disabled
        ```

    1.  Capture the list of nodes that are `off`.

        ```bash
        ncn# sat status --filter State=Off | tee sat.status.off
        ```

    1.  Capture the state of nodes in the workload manager. For example, if the system uses Slurm:

        ```bash
        ncn# ssh uan01 sinfo | tee uan01.sinfo
        ```

    1.  Capture the list of down nodes in the workload manager and the reason.

        ```bash
        ncn# ssh nid000001-nmn sinfo --list-reasons | tee sinfo.reasons
        ```

    1.  Check Ceph status.

        ```bash
        ncn# ceph -s | tee ceph.status
        ```

    1.  Check k8s pod status for all pods.

        ```bash
        ncn# kubectl get pods -o wide -A | tee k8s.pods
        ```

        Additional k8s status check examples:

        ```bash
        ncn# kubectl get pods -o wide -A | egrep  "CrashLoopBackOff" > k8s.pods.CLBO
        ncn# kubectl get pods -o wide -A | egrep  "ContainerCreating" > k8s.pods.CC
        ncn# kubectl get pods -o wide -A | egrep -v "Run|Completed" > k8s.pods.errors
        ```

    1.  Check HSN status.

        Determine the name of the slingshot-fabric-manager pod:

        ```bash
        ncn# kubectl get pods -l app.kubernetes.io/name=slingshot-fabric-manager -n services
        ```

        Example output:

        ```
        NAME                                        READY   STATUS    RESTARTS   AGE
        slingshot-fabric-manager-5dc448779c-d8n6q   2/2     Running   0          4d21h
        ```

        Run `fmn_status` in the slingshot-fabric-manager pod and save the output to a file:

        ```bash
        ncn# kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \
             -c slingshot-fabric-manager -- fmn_status --details | tee fabric.status
        ```

    1. Check management switches to verify they are reachable \(switch host names depend on system configuration\).

        ```bash
        ncn# for switch in sw-leaf-00{1,2}.mtl sw-spine-00{1,2}.mtl sw-cdu-00{1,2}.mtl; do
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
        ncn# ssh admin@cls01234n00.us.cray.com
        admin@cls01234n00# cscli show_nodes
        ```

    1. From a node which has the Lustre file system mounted.

        ```bash
        uan01# lfs check servers
        uan01# lfs df
        ```

1.  Check for running sessions.

    ```bash
    ncn# sat bootsys shutdown --stage session-checks | tee sat.session-checks
    ```

    Example output:

    ```
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

    If active sessions are running, either wait for them to complete or cancel the session. See the following step.

1. Cancel the running BOS sessions.

    1.   Identify the BOS Sessions and associated BOA Kubernetes jobs to delete.

         Determine which BOS session(s) to cancel. To cancel a BOS session, kill
	     its associated Boot Orchestration Agent (BOA) Kubernetes job.
         
         To find a list of BOA jobs that are still running:
         
         ```bash
         ncn# kubectl -n services get jobs|egrep -i "boa|Name"
         ```
         
         Output similar to the following will be returned:

         ```
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

         Any job with a 0/1 COMPLETIONS column is still running and is a candidate to be forcibly deleted.
         The BOA Job ID appears in the NAME column.

    1.   Clean up prior to BOA job deletion.

         The BOA pod mounts a ConfigMap under the name `boot-session` at the directory `/mnt/boot_session` inside the pod. This ConfigMap has a random UUID name like `e0543eb5-3445-4ee0-93ec-c53e3d1832ce`.
         Prior to deleting a BOA job, delete its ConfigMap.
         Find the BOA job's ConfigMap with the following command:
         
         ```bash
         ncn# kubectl -n services describe job <BOA Job ID> |grep ConfigMap -A 1 -B 1
         ```
	 
         Example:
         
         ```bash
         ncn# kubectl -n services describe job boa-0216d2d9-b2bc-41b0-960d-165d2af7a742 |grep ConfigMap -A 1 -B 1
            boot-session:
             Type:      ConfigMap (a volume populated by a ConfigMap)
             Name:      e0543eb5-3445-4ee0-93ec-c53e3d1832ce    <<< ConfigMap name. Delete this one.
         --
            ca-pubkey:
             Type:      ConfigMap (a volume populated by a ConfigMap)
             Name:      cray-configmap-ca-public-key
         ```
         
         Delete the ConfigMap associated with the boot-session, not the ca-pubkey.
         
         To delete the ConfigMap:
         
         ```bash
         ncn# kubectl -n services delete cm <ConfigMap name>
         ```
         
         Example:
         
         ```bash
         ncn# kubectl -n services delete cm e0543eb5-3445-4ee0-93ec-c53e3d1832ce
         configmap "e0543eb5-3445-4ee0-93ec-c53e3d1832ce" deleted
         ```
         
    1.   Delete the BOA job(s).

         ```bash
         ncn# kubectl -n services delete job <BOA JOB ID>
         ```
         
         This will cancel (i.e. kill) the BOA job and the BOS session associated with it.
         
         When a job is killed, BOA will no longer attempt to execute the operation it was attempting to perform. This does not mean that
         nothing continues to happen. If BOA has instructed a node to power on, the node will continue to power even after the BOA job
         has been killed.

    1.   Delete the BOS session.
         BOS keeps track of sessions in its database. These entries need to be deleted.
	     The BOS Session ID is the same as the BOA Job ID minus the prepended 'boa-'
	     string. Use the following command to delete the BOS database entry.
         
         ```bash
         ncn# cray bos session delete <session ID>
         ```
         
         Example:
         
         ```bash
         ncn# cray bos session delete 0216d2d9-b2bc-41b0-960d-165d2af7a742
         ```

1.  Coordinate with the site to prevent new sessions from starting in the services listed.

    There is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1.  Follow the vendor workload manager documentation to drain processes running on compute nodes. For Slurm, see the `scontrol` man page. For PBS Professional, see the `pbsnodes` man page.


