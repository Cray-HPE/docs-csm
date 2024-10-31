# Prepare the System for Power Off

This procedure prepares the system to remove power from all system cabinets. Be sure the system is healthy and ready to be shut down and powered off.

The `sat bootsys shutdown` and `sat bootsys boot` commands are used to shut down the system.

## Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. For more information, see
[Authenticate SAT Commands](../../operations/system_admin_toolkit/configuration/Authenticate_SAT_Commands.md).

## Procedure

### Collect authentication credentials and authenticate SAT

1. Obtain the user ID and passwords for system components:

    1. Obtain user ID and passwords for all the system management network switches.

    1. If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, `cls01053n00`.

    1. If the Slingshot network includes edge switches, obtain the user ID and password for these switches.

1. Use `sat auth` to authenticate to the API gateway within SAT.

   For information on acquiring a SAT authentication token, see
   [Authenticate SAT Commands](../../operations/system_admin_toolkit/configuration/Authenticate_SAT_Commands.md).

   If SAT has already been authenticated to the API gateway, this step may be skipped.

### Check shell initialization scripts

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

### Check SSH known hosts

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

### Check certificate expiration deadlines

1. Check certificate expiration deadlines to ensure that a certificate will not expire while the system is powered off.

   1. (`ncn-mw#`) Check the expiration date of the Spire Intermediate CA Certificate.

      ```bash
      kubectl get secret -n spire spire.spire.ca-tls -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
      ```

      Example output:

      ```bash
      notAfter=Dec 17 00:00:24 2024 GMT
      ```

      If the certificate will expire while the system is powered off, replace it before powering off the system.
      See [Replace the Spire Intermediate CA Certificate](../spire/Update_Spire_Intermediate_CA_Certificate.md#replace-the-spire-intermediate-ca-certificate).

   1. (`ncn-m#`) Check the Kubernetes and Bare Metal etcd certificates from a master node.

      Check certificate expiration deadlines for Kubernetes and its bare-metal etcd cluster.

      ```bash
      kubeadm certs check-expiration --config /etc/kubernetes/kubeadmcfg.yaml
      ```

      Example output:

      ```text
      WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]

      CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
      admin.conf                 Sep 24, 2021 15:21 UTC   14d             ca                      no
      apiserver                  Sep 24, 2021 15:21 UTC   14d             ca                      no
      apiserver-etcd-client      Sep 24, 2021 15:20 UTC   14d             etcd-ca                 no
      apiserver-kubelet-client   Sep 24, 2021 15:21 UTC   14d             ca                      no
      controller-manager.conf    Sep 24, 2021 15:21 UTC   14d             ca                      no
      etcd-healthcheck-client    Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
      etcd-peer                  Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
      etcd-server                Sep 24, 2021 15:19 UTC   14d             etcd-ca                 no
      front-proxy-client         Sep 24, 2021 15:21 UTC   14d             front-proxy-ca          no
      scheduler.conf             Sep 24, 2021 15:21 UTC   14d             ca                      no

      CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
      ca                      Sep 02, 2030 15:21 UTC   8y              no
      etcd-ca                 Sep 02, 2030 15:19 UTC   8y              no
      front-proxy-ca          Sep 02, 2030 15:21 UTC   8y              no
      ```

      Depending on which certificates will expire, one of these procedures could be used for the renewal. The first procedure
      will renew all certificates, but that may be more than needs to be renewed.

      * See [Renew All Certificates](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#renew-all-certificates)
      * See [Renew Etcd Certificate](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#renew-etcd-certificate)
      * See [Update Client Certificates](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#update-client-secrets)

   1. (`ncn-m#`) Check the `kube-etcdbackup-etcd` certificate expiration.

      ```bash
      kubectl get secret -n kube-system kube-etcdbackup-etcd -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
      ```

      Example output:

      ```text
      notAfter=Apr 17 09:37:52 2025 GMT
      ```

      If the certificate has expired or will expire while the system is powered off, see the procedure steps for changing the `kube-etcdbackup-etcd` secret and then restarting Prometheus after the change.

      * See [Update Client Secrets](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#update-client-secrets)

   1. (`ncn-m#`) Check the `etcd-ca` certificate expiration.

      ```bash
      kubectl get secret -n sysmgmt-health etcd-client-cert -o json | jq -r '.data."etcd-ca" | @base64d' | openssl x509 -noout -enddate
      ```

      Example output:

      ```text
      notAfter=Jan 13 18:01:48 2033 GMT
      ```

      If the `etcd-ca` certificate has expired or will expire while the system is powered off, see the procedure steps for changing the `etcd-client-cert` secret and then restarting Prometheus after the change.

      * See [Update Client Secrets](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#update-client-secrets)

   1. (`ncn-m#`) Check the `etcd-client` certificate expiration.

      ```bash
      kubectl get secret -n sysmgmt-health etcd-client-cert -o json | jq -r '.data."etcd-client" | @base64d' | openssl x509 -noout -enddate
      ```

      Example output:

      ```text
      notAfter=Jan 16 18:01:49 2024 GMT
      ```

      If either the `etcd-client` certificate has expired or will expire while the system is powered off, see the procedure steps for changing the `etcd-client-cert` secret and then restarting Prometheus after the change.

      * See [Update Client Secrets](../kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#update-client-secrets)

### Check Nexus backup status

1. (`ncn-mw#`) Check for a recent backup of Nexus data.

   **Note:** Doing the Nexus backup may take multiple hours with Nexus being unavailable for the entire time.

   Check whether an export PVC called `nexus-bak` exists and is recent.

   ```bash
   kubectl get pvc -n nexus
   ```

   Example output:

   ```text
   NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
   nexus-bak    Bound    pvc-09b6efe6-18e3-4681-8103-53590ad49d04   1000Gi     RWO            k8s-block-replicated   293d
   nexus-data   Bound    pvc-bce9db69-d1a6-491d-89fc-d458c92f2895   1000Gi     RWX            ceph-cephfs-external   518d
   ```

   This output shows that the `nexus-bak` PVC was created 293 days ago.

   * If there is no `nexus-bak` PVC, then use this Nexus export procedure to create one. This procedure does check that
   there is enough space available for the copy of the `nexus-data` PVC and provides guidance on how to clean up space if
   necessary or reduce the size of the existing `nexus-data` PVC.
   See [Nexus Export](../package_repository_management/Nexus_Export_and_Restore.md#Export).

   * If there is an existing `nexus-bak` PVC, but it is too old or the age is not recent enough to include the most recent
   software update or otherwise not considered valid, then use the Nexus cleanup procedure before the export procedure.
   See [Nexus Cleanup](../package_repository_management/Nexus_Export_and_Restore.md#Cleanup), then see
   [Nexus Export](../package_repository_management/Nexus_Export_and_Restore.md#Export).

### Identify BOS session templates for managed nodes

(`ncn-mw#`) Determine the appropriate Boot Orchestration Service (BOS) templates to use to shut down
managed nodes, including compute nodes and User Access Nodes (UANs).

1. (`ncn-mw#`) Use `sat status` to find the BOS session templates used most recently to boot nodes.

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

    **`NOTE`** The above command may show a value of `MISSING` for the `Most Recent Session
    Template`. This means the BOS session last used to boot the node was deleted. BOS automatically
    deletes sessions after the number of days specified in the BOS setting
    `cleanup_completed_session_ttl`. The default value is seven days. To view the value of this
    setting, use the following command:

    ```bash
    cray bos options list | grep cleanup_completed_session_ttl
    ```

1. (`ncn-mw#`) If the `sat status` command in the previous step identified the BOS session templates
    to use for shutting down and booting all managed nodes, proceed to the next step. Otherwise, the
    BOS session templates will have to be manually identified from the list of all BOS session
    templates.

    1. Use the following command to list the names of all BOS session templates.

       ```bash
       cray bos sessiontemplates list --format json | jq -r '.[].name' | sort
       ```

    1. Use the following command to get the details for a BOS session template listed by the
       previous command. Replace `BOS_SESSION_TEMPLATE` with the name of the BOS session template:

       ```bash
       cray bos sessiontemplates describe --format json BOS_SESSION_TEMPLATE
       ```

1. (`ncn-mw#`) Once the appropriate BOS session templates are identified, validate the set of nodes
   that each session template affects as follows.

    1. Set the name of the session template in an environment variable. For example:

       ```bash
       SESSION_TEMPLATE_NAME="compute-24.6.0"
       ```

    1. Get the nodes affected by the BOS session template:

       ```bash
       cray bos sessiontemplates describe $SESSION_TEMPLATE_NAME --format json \
           | jq '.boot_sets | map({node_list, node_roles_groups, node_groups})'
       ```

       The following example shows the output for a session template that specifies an explict list
       of node xnames:

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

       The following example shows the output for a session template that specifies a node group:

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

1. Confirm that the set of identified BOS session templates will affect all managed nodes in the
   system. This is important to ensure all managed nodes are gracefully shut down during the system
   power off.

### Capture state and perform system health checks

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

       Run `fmn-show-status` in the `slingshot-fabric-manager` pod and save the output to a file.

        ```bash
        kubectl exec -it -n services \
            "$(kubectl get pod -l app.kubernetes.io/name=slingshot-fabric-manager
            -n services --no-headers | head -1 | awk '{print $1}')" \
             -c slingshot-fabric-manager -- fmn-show-status --details \
           | tee -a fmn-show-status-details.txt
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

### Check system activity

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

### Notify people of upcoming power off

1. Notify users and operations staff about the upcoming full system power off.

   The notification method will vary by system, but might be email, messaging applications, `/etc/motd` on UANs, `wall` commands on UANs, and so on.

### Prepare workload managers

1. Follow the vendor workload manager documentation to drain processes running on compute nodes.

    1. For Slurm, see the `scontrol` man page.

       The following are examples of how to drain nodes using `slurm`. The list of nodes can be copy/pasted from the `sinfo` command for nodes in an `idle` state:

       ```bash
       scontrol update NodeName=nid[001001-001003,001005] State=DRAIN Reason="Shutdown"
       ```

       ```bash
       scontrol update NodeName=ALL State=DRAIN Reason="Shutdown"
       ```

    1. For PBS Professional, see the `qstat` and `qmgr` man pages.

       The following is an example to list the available queues, disable a specific queue named `workq`, and check
       that the queue has been disabled:

       ```bash
       qstat -q
       qmgr -c 'set queue workq enabled = False'
       qmgr -c 'list queue workq enabled'
       ```

       Each system might have many different queue names. There is no default queue name.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
