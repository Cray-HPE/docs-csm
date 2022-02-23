

## Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

### Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the System Admin Toolkit (SAT) product documentation.

### Procedure

1.  Obtain the user ID and passwords for system components:

    1.  Obtain user ID and passwords for all the system management network switches. For example:

        ```bash
        sw-leaf-001
        sw-leaf-002
        sw-spine-001.nmn
        sw-spine-002.nmn
        sw-cdu-001
        sw-cdu-002
        ```

        User id: `admin`

        Password: `PASSWORD`

    2.  If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, `cls01053n00`.

        User id: `admin`

        Password: `PASSWORD`

    3.  If the Slingshot network includes edge switches, obtain the user ID and password for these switches.

2.  Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs. You can list all the session templates using `cray bos v1 sessiontemplate list`. If you are unsure of which template is in use, you can call `sat status` to find the xname, then use `cray cfs components describe XNAME` to find the bos_session, and use `cray bos v1 session describe BOS_SESSION` to find the `templateUuid`. Then finally use `cray bos v1 sessiontemplate describe TEMPLATE_UUID` to determine the list of xnames associated with a given template. For example:

    ```bash
    ncn-m001# sat status | grep "Compute\|Application"

    | x3000c0s19b1n0 | Node | 1        | On    | OK   | True    | X86  | River | Compute     | Sling    |
    | x3000c0s19b2n0 | Node | 2        | On    | OK   | True    | X86  | River | Compute     | Sling    |
    | x3000c0s19b3n0 | Node | 3        | On    | OK   | True    | X86  | River | Compute     | Sling    |
    | x3000c0s19b4n0 | Node | 4        | On    | OK   | True    | X86  | River | Compute     | Sling    |
    | x3000c0s27b0n0 | Node | 49169248 | On    | OK   | True    | X86  | River | Application | Sling    |

    ncn-m001# cray cfs components describe x3000c0s19b1n0 | grep bos_session
    bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"

    ncn-m001# cray bos v1 session describe e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f | grep templateUuid
    templateUuid = "compute-nid1-4-sessiontemplate"

    ncn-m001# cray bos v1 sessiontemplate describe Nid1-4session-compute | grep node_list
    node_list = [ "x3000c0s19b1n0", "x3000c0s19b2n0", "x3000c0s19b3n0", "x3000c0s19b4n0",]

    ncn-m001# cray cfs components describe x3000c0s27b0n0 | grep bos_session
    bos_session = "b969c25a-3811-4a61-91d5-f1c194625748"

    # cray bos v1 session describe b969c25a-3811-4a61-91d5-f1c194625748 | grep templateUuid
    templateUuid = "uan-sessiontemplate"
    ```

    Compute nodes: `compute-nid1-4-sessiontemplate`

    UANs: `uan-sessiontemplate`

3.  Use `sat auth` to authenticate to the API gateway within SAT.

    See [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md), [Authenticate an Account with the Command Line](../security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md), and "SAT Authentication" in the System Admin Toolkit (SAT) product documentation.

4.  Use sat to capture state of the system before the shutdown.

    ```bash
    ncn-m001# sat bootsys shutdown --stage capture-state | tee sat.capture-state
    ```

5.  Optional system health checks.

    1.  Use the System Dump Utility \(SDU\) to capture current state of system before the shutdown.

        **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

        ```bash
        ncn-m001# sdu --scenario triage --start_time '-4 hours' \
        --reason "saving state before powerdown/up"
        ```

    2.  Capture the state of all nodes.

        ```bash
        ncn-m001# sat status | tee sat.status.off
        ```

    3.  Capture the list of disabled nodes.

        ```bash
        ncn-m001# sat status --filter Enabled=false | tee sat.status.disabled
        ```

    4.  Capture the list of nodes that are `off`.

        ```bash
        ncn-m001# sat status --filter State=Off | tee sat.status.off
        ```

    5.  Capture the state of nodes in the workload manager, for example, if the system uses Slurm.

        ```bash
        ncn-m001# ssh uan01 sinfo | tee uan01.sinfo
        ```

    6.  Capture the list of down nodes in the workload manager and the reason.

        ```bash
        ncn-m001# ssh nid000001-nmn sinfo --list-reasons | tee sinfo.reasons
        ```

    7.  Check Ceph status.

        ```bash
        ncn-m001# ceph -s | tee ceph.status
        ```

    8.  Check k8s pod status for all pods.

        ```bash
        ncn-m001# kubectl get pods -o wide -A | tee k8s.pods
        ```

        Additional k8s status check examples :

        ```bash
        ncn-m001# kubectl get pods -o wide -A | egrep  "CrashLoopBackOff" > k8s.pods.CLBO
        ncn-m001# kubectl get pods -o wide -A | egrep  "ContainerCreating" > k8s.pods.CC
        ncn-m001# kubectl get pods -o wide -A | egrep -v "Run|Completed" > k8s.pods.errors
        ```

    9.  Check HSN status.

        Determine the name of the slingshot-fabric-manager pod:

        ```bash
        ncn-m001# kubectl get pods -l app.kubernetes.io/name=slingshot-fabric-manager -n services
        NAME                                        READY   STATUS    RESTARTS   AGE
        slingshot-fabric-manager-5dc448779c-d8n6q   2/2     Running   0          4d21h
        ```

        Run `fmn_status` in the slingshot-fabric-manager pod and save the output to a file:

        ```bash
        ncn-m001# kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \
        -c slingshot-fabric-manager -- fmn_status --details | tee fabric.status
        ```

    10. Check management switches to verify they are reachable \(switch host names depend on system configuration\).

        ```bash
        ncn-m001# for switch in sw-leaf-00{1,2}.mtl sw-spine-00{1,2}.mtl sw-cdu-00{1,2}.mtl; \
        do while true; do ping -c 1 $switch > /dev/null; if [[ $? == 0 ]]; then echo \
        "switch $switch is up"; break; else echo "switch $switch is not yet up"; fi; sleep 5; done; done | tee switches
        ```

    11. Check Lustre server health.

        ```bash
        ncn-m001# ssh admin@cls01234n00.us.cray.com
        admin@cls01234n00 ~]$ cscli show_nodes
        ```

    12. From a node which has the Lustre file system mounted.

        ```bash
        uan01:~ # lfs check servers
        uan01:~ # lfs df
        ```

6.  Check for running sessions.

    ```bash
    ncn-m001# sat bootsys shutdown --stage session-checks | tee sat.session-checks
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
    No active sessions exist. It is safe to proceed with the shutdown procedure.
    ```

    If active sessions are running, either wait for them to complete or cancel the session. See the following step.

7. Cancel the running BOS sessions.

    1.   Identify the BOS Sessions and associated BOA Kubernetes jobs to delete.

         Determine which BOS session(s) to cancel. To cancel a BOS session, kill
	 its associated Boot Orchestration Agent (BOA) Kubernetes job.
         
         **Method #1: Use BOS Session Status**

         Use the following script to find the BOS session that have ended (true) or are still running (false)
         ```bash
         #! /bin/bash
         # List all of the BOS sessions. Look for ones whose status says they are
         # not complete, i.e. still running.
         # Output the BOA Job ID for each BOS Session that is still running.
         for ID in $(cray bos session list --format json | jq .[] | tr -d \"); do
             result=$(cray bos session status list --format json $ID | jq .metadata.complete)
             if [[ $result == "false" ]]; then
                 cray bos v1 session describe --format json $ID | jq .boa_job_name | tr -d \";
             fi
         done
         ````
	 
         These IDs are the BOA Kubernetes job IDs. Delete these to cancel the BOS
	 session.
         
         However, the BOS status output can be buggy, and it may misidentify BOS
	 sessions as still running when they have actually finished.
	 If you only want to delete currently running jobs, then use Method #2. 
         Method #2 is a more reliable method for identifying running BOA jobs
	 because it interacts directly with the BOA Kubernetes job.
         
         **Method #2: Look at BOA Kubernetes jobs**
         
         To find a list of BOA jobs that are still running:
         ```bash
         kubectl -n services get jobs|egrep -i "boa|Name"
         ```
         
         Output similar to the following will be returned:
         ```bash
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

    2.   Clean up prior to BOA job deletion.

         The BOA pod mounts a ConfigMap under the name `boot-session` at the directory `/mnt/boot_session` inside the pod. This ConfigMap has a random UUID name like `e0543eb5-3445-4ee0-93ec-c53e3d1832ce`.
         Prior to deleting a BOA job, delete its ConfigMap.
         Find the BOA job's ConfigMap with the following command:
         ```bash
         ncn-w001# kubectl -n services describe job <BOA Job ID> |grep ConfigMap -A 1 -B 1
         ```
	 
         Example:
         ```bash
         ncn-w001# kubectl -n services describe job boa-0216d2d9-b2bc-41b0-960d-165d2af7a742 |grep ConfigMap -A 1 -B 1
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
         kubectl -n services delete cm <ConfigMap name>
         ```
         
         Example:
         ```bash
         ncn-w001# kubectl -n services delete cm e0543eb5-3445-4ee0-93ec-c53e3d1832ce
         configmap "e0543eb5-3445-4ee0-93ec-c53e3d1832ce" deleted
         ```
         
    3.   Delete the BOA job(s).

         ```bash
         kubectl -n services delete job <BOA JOB ID>
         ```
         
         This will cancel (i.e. kill) the BOA job and the BOS session associated with it.
         
         When a job is killed, BOA will no longer attempt to execute the operation it was attempting to perform. This does not mean that
         nothing continues to happen. If BOA has instructed a node to power on, the node will continue to power even after the BOA job
         has been killed.

    4.   Delete the BOS session.
         BOS keeps track of sessions in its database. These entries need to be deleted.
	 Note, you found the BOS Session ID earlier, but it is also invariably the same
	 as the BOA Job ID minus the prepended 'boa-' string.
         Use the following command to delete the BOS database entry.
         ```bash
         cray bos v1 session delete <session ID>
         ```
         
         Example:
         ```bash
         ncn-w001# cray bos v1 session delete 0216d2d9-b2bc-41b0-960d-165d2af7a742
         ```

8.  Coordinate with the site to prevent new sessions from starting in the services listed.

    In version 1.4.x, there is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

9.  Follow the vendor workload manager documentation to drain processes running on compute nodes. For Slurm, the see `scontrol` man page and for PBS Professional, see the `pbsnodes` man page.



