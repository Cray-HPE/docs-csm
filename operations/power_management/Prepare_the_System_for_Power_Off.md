

## Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

### Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the System Admin Toolkit (SAT) product stream documentation.

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

    See [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md), [Authenticate an Account with the Command Line](../security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md), and "SAT Authentication" in the System Admin Toolkit (SAT) product stream documentation.

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
    Checking for active SDU sessions.
    Found no active SDU sessions.
    No active sessions exist. It is safe to proceed with the shutdown procedure.
    ```

    If active sessions are running, either wait for them to complete or shut down/cancel/delete the session.

7.  Coordinate with the site to prevent new sessions from starting in the services listed.

    In version 1.4.x, there is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

8.  Follow the vendor workload manager documentation to drain processes running on compute nodes. For Slurm, the see `scontrol` man page and for PBS Professional, see the `pbsnodes` man page.



