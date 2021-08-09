

## Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

### Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the SAT repository for more information.

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

2.  Determine which Boot Orchestration Service \(BOS\) templates to use to shut down compute nodes and UANs. For example:

    Compute nodes: `slurm`

    UANs: `uan-slurm`

3.  Use `sat auth` to authenticate to the API gateway within SAT.

    See [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md), [Authenticate an Account with the Command Line](../security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md), and "SAT Authentication" in the SAT repository for more information.

4.  Use sat to capture state of the system before the shutdown.

    ```bash
    ncn-m001# sat bootsys shutdown --stage capture-state
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
        ncn-m001# sat status --filter Enabled=false > sat.status.disabled
        ```

    4.  Capture the list of nodes that are `off`.

        ```bash
        ncn-m001# sat status --filter State=Off > sat.status.off
        ```

    5.  Capture the state of nodes in the workload manager, for example, if the system uses Slurm.

        ```bash
        ncn-m001# ssh uan01 sinfo > sinfo
        ```

    6.  Capture the list of down nodes in the workload manager and the reason.

        ```bash
        ncn-m001# ssh nid001000-nmn sinfo --list-reasons > sinfo.reasons
        ```

    7.  Check Ceph status.

        ```bash
        ncn-m001# ceph -s > ceph.status
        ```

    8.  Check k8s pod status for all pods.

        ```bash
        ncn-m001# kubectl get pods -o wide -A > k8s.pods
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

        Run `fmn_status` in the fabric manager pod and save it to a file:

        ```bash
        ncn-m001# kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \
        -c slingshot-fabric-manager -- fmn_status --details > fabric.status
        ```

    10. Check management switches to verify they are reachable \(switch host names depend on system configuration\).

        ```bash
        ncn-m001# for switch in sw-leaf-00{1,2}.mtl sw-spine-00{1,2}.mtl sw-cdu-00{1,2}.mtl; \
        do while true; do ping -c 1 $switch > /dev/null; if [[ $? == 0 ]]; then echo \
        "switch $switch is up"; break; else echo "switch $switch is not yet up"; fi; sleep 5; done; done
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
    ncn-m001# sat bootsys shutdown --stage session-checks
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

    If active sessions are running, either wait for them to complete or shut down/cancel/delete the session.

7.  Coordinate with the site to prevent new sessions from starting in the services listed.

    In version 1.4, there is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

8.  Follow the vendor WLM documentation to drain processes running on compute nodes.



