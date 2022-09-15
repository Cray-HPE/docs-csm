# Reboot NCNs

The following is a high-level overview of the non-compute node \(NCN\) reboot workflow:

1. Run the NCN pre-reboot checks and procedures.

   1. Ensure that `ncn-m001` is not booted to the LiveCD / PIT node.
   1. Check the `metal.no-wipe` settings for all NCNs.
   1. Run all platform health checks, including checks on the Border Gateway Protocol \(BGP\) peering sessions.
   1. [Validate the current boot order](../../background/ncn_boot_workflow.md#determine-the-current-boot-order) (or [specify the boot order](../../background/ncn_boot_workflow.md#set-boot-order)).

1. Run the rolling NCN reboot procedure.

   Loop through reboots on storage nodes, worker nodes, and master nodes, where each reboot consists of the following workflow:

   1. Establish console session with node to reboot.
   1. Execute a Linux graceful shutdown or power off/on sequence to the node, allowing it to boot up to completion.
   1. Execute NCN/platform health checks and do not go on to reboot the next NCN until health has been ensured on the most recently rebooted NCN.
   1. Disconnect console session with the node that was rebooted.

1. Re-run all platform health checks.

The time duration for this procedure \(if health checks are being executed in between each boot, as recommended\) could take between two to four hours for a system with nine management nodes.

This same procedure can be used to reboot a single management node as outlined above.
Be sure to carry out the NCN pre-reboot checks and procedures before and after rebooting the node.
Execute the rolling NCN reboot procedure steps for the particular node type being rebooted.

**IMPORTANT** whenever an NCN is rebooted the `CASMINST-2015.sh` script should be run to remove any dynamically assigned IP addresses that were not released automatically.

```bash
ncn-mw# /usr/share/doc/csm/scripts/CASMINST-2015.sh
```

## Prerequisites

* The `kubectl` command is installed.
* The Cray command line interface is configured on at least one NCN.
  * See [Configure the Cray CLI](../configure_cray_cli.md).
* The latest CSM documentation is installed, if rebooting `ncn-m001` or any worker nodes.
  * If rebooting `ncn-m001`, then the latest CSM documentation must be installed on `ncn-m001`.
  * If rebooting a worker node, then the latest CSM documentation must be installed on some master or worker node.
  * See [Check for latest workarounds and documentation updates](../../update_product_stream/index.md#check-for-latest-workarounds-and-documentation-updates).

## NCN pre-reboot health checks

1. Ensure that `ncn-m001` is not booted to the LiveCD / PIT node.

    This mode should only be in effect during the initial product install.
    If the word `pit` is NOT in the hostname of `ncn-m001`, then it is not in the LiveCD mode.

    If `pit` is in the hostname of `ncn-m001`, then the system is not in normal operational mode and rebooting `ncn-m001` may have unexpected results.
    This procedure assumes that the node is not running in the LiveCD mode that occurs during product install.

1. Check and set the `metal.no-wipe` setting on NCNs to ensure that data on the node is preserved when rebooting.

    Refer to [Check and Set the `metal.no-wipe` Setting on NCNs](Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md).

1. Run the platform health checks and analyze the results.

    Refer to the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md) for an overview of the health checks.

    1. Run the platform health scripts from a master or worker node.

        The output of the following scripts will need to be referenced in the remaining sub-steps.

        ```bash
        ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
        ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
        ```

        **NOTE**: If the `ncnHealthChecks` script output indicates any `kube-multus-ds-` pods are in
        a `Terminating` state, that can indicate that a previous restart of these pods did not complete.
        In this case, it is safe to force delete these pods in order to let them properly restart; this is
        done by running `kubectl delete po -n kube-system kube-multus-ds.. --force`. After executing this
        command, re-running the `ncnHealthChecks` script should indicate that a new pod is in the `Running` state.

    1. Check the status of the Kubernetes nodes.

        Ensure that all Kubernetes nodes are in the Ready state.

        ```bash
        ncn-mw# kubectl get nodes
        ```

        **Troubleshooting:** If the node that was rebooted is in a `Not Ready` state, then run the following command to get more information.

        ```bash
        ncn-mw# kubectl describe node NCN_HOSTNAME
        ```

        If that file is empty, run the following workaround to populate this file:

        ```bash
        ncn-mw# cp /srv/cray/resources/common/containerd/00-multus.conf /etc/cni/net.d/00-multus.conf
        ncn-mw# cat /etc/cni/net.d/00-multus.conf
        ```

        Verify that the worker or master node is now in a `Ready` state:

        ```bash
        ncn-mw# kubectl get nodes
        ```

    1. Check the status of the Kubernetes pods.

        The bottom of the output returned after running the `/opt/cray/platform-utils/ncnHealthChecks.sh` script will show a list of pods that may be in a bad state.
        The following command can also be used to look for any pods that are not in a `Running` or `Completed` state:

        ```bash
        ncn-mw# kubectl get pods -o wide -A | grep -Ev 'Running|Completed'
        ```

        It is important to pay attention to that list, but it is equally important to note what pods are in that list before and after node reboots to determine if the reboot caused any new issues.

        There are pods that may normally be in an `Error`, `Not Ready`, or `Init` state, and this may not indicate any problems caused by the NCN reboots.
        `Error` states can indicate that a job pod ran and ended in an error.
        That means that there may be a problem with that job, but does not necessarily indicate that there is an overall health issue with the system.
        The key takeaway \(for health purposes\) is understanding the statuses of pods prior to doing an action like rebooting all of the NCNs.
        Comparing the pod statuses in between each NCN reboot will give a sense of what is new or different with respect to health.

    1. Verify Ceph health (the command mentioned below can be run on any master or storage node).

        This output is included in the `/opt/cray/platform-utils/ncnHealthChecks.sh` script.

        Run the following command during NCN reboots:

        ```bash
        ncn-mw# watch -n 10 'ceph -s'
        ```

        This window can be kept up throughout the reboot process to ensure Ceph remains healthy
        and to watch if Ceph goes into a `WARN` state when rebooting storage node.

    1. Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting.

        ```bash
        ncn-mw# kubectl describe pod -n user -lapp=slurmctld
        ```

        ```bash
        ncn-mw# kubectl describe pod -n user -lapp=slurmdbd
        ```

        ```text
        Events:
          Type     Reason                  Age                    From               Message
          ----     ------                  ----                   ----               -------
          Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
        sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
        "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": Multus: Err in tearing down failed
        plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses
        available in range set: 10.252.2.4-10.252.2.4
          Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
        sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
        ...
        ```

        If the preceding error is displayed, then remove all files in the following directories on all worker nodes:

        * `/var/lib/cni/networks/macvlan-slurmctld-nmn-conf`
        * `/var/lib/cni/networks/macvlan-slurmdbd-nmn-conf`

    1. Check that the BGP peering sessions are established.

        This check will need to be run after all worker node have been rebooted.
        Ensure that the checks have been run to check BGP peering sessions on the spine switches.

        If there are BGP Peering sessions that are not `ESTABLISHED` on either switch, then refer to
        [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

1. Ensure that no nodes are in a `failed` state in CFS.

   Nodes that are in a failed state prior to the reboot will not be automatically
   configured once they have been rebooted.

   The following script will find all CFS components in the `failed` state and for each such
   component it will reset its CFS error count to 0 and disable it in CFS. It is disabled in
   order to prevent CFS from immediately triggering a configuration. The components will be
   automatically re-enabled when they boot.

   This can be run on any NCN where the Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

   ```bash
   ncn# cray cfs components list --status failed --format json | jq .[].id -r | while read -r xname ; do
            echo "${xname}"
            cray cfs components update "${xname}" --enabled False --error-count 0
        done
   ```

   Alternatively, this can be done manually. To get a list of nodes in the failed state:

   ```bash
   ncn# cray cfs components list --status failed --format json | jq .[].id
   ```

   To reset the error count and disable a node:

   **NOTE:** Be sure to replace the `<xname>` in the following command with the component name (xname) of the NCN component to be reset and disabled.

   ```bash
   ncn# cray cfs components update <xname> --enabled False --error-count 0
   ```

## NCN rolling reboot

Before rebooting NCNs:

* Ensure that pre-reboot checks have been completed, including checking the `metal.no-wipe` setting for each NCN. Do not proceed if any of the NCN `metal.no-wipe` settings are zero.

### Utility storage nodes (Ceph)

1. Reboot each of the storage nodes (one at a time), going from the highest to lowest number.

    1. Establish a console session to each storage node.

        Use the [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) procedure referenced in step 4.

    1. If booting from disk is desired then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    1. Reboot the selected node.

        ```bash
        ncn-s# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below.

        1. Power off the node.

            > `read -s` is used to prevent the password from being written to the screen or the shell history.
            >
            > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-s002`.

            ```bash
            ncn# USERNAME=root
            ncn# read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
            ncn# export IPMI_PASSWORD
            ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power off
            ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
            ```

           Ensure that the power is reporting as off. It may take 5-10 seconds for this to update.
           Wait about 30 seconds after receiving the correct power status before issuing the next command.

        1. Power on the node.

           > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-s002`.

           ```bash
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power on
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
           ```

           Ensure that the power is reporting as on. It may take 5-10 seconds for this to update.

    1. Watch on the console until the node has successfully booted and the login prompt is reached.

    1. If desired, verify that the method of boot is as expected.

       If the `/proc/cmdline` file begins with `BOOT_IMAGE`, then this NCN booted from disk.

       ```bash
       ncn-s# egrep -o '^(BOOT_IMAGE|kernel)' /proc/cmdline
       ```

       Example output for a disk boot is:

       ```text
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    1. Retrieve the component name (xname) for the node that was rebooted.

       This xname is available on the node that was rebooted in the `/etc/cray/xname` file.

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    1. Check the Configuration Framework Service (CFS) `configurationStatus` for the rebooted node's `desiredConfig`.

       The following command will indicate if a CFS job is currently in progress for this node.
       Replace the `XNAME` value in the following command with the component name (xname) of the node that was rebooted.

       This can be run on any NCN where the Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```json
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,
       ```

       * If the `configurationStatus` is `pending`, then wait for the job to finish before continuing.
       * If the `configurationStatus` is `failed`, then this means the failed CFS job `configurationStatus` should be addressed now for this node.
       * If the `configurationStatus` is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, then this can be ignored.
       * If the `configurationStatus` is `failed`, then see [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
         for how to analyze the pod logs from `cray-cfs` in order to determine why the configuration may not have completed.

    1. Remove any dynamically assigned interface IP addresses that did not get released automatically by running the `CASMINST-2015.sh` script:

       ```bash
       ncn-mw# /usr/share/doc/csm/scripts/CASMINST-2015.sh
       ```

    1. Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

         **Troubleshooting:** If the `slurmctld` and `slurmdbd` pods do not start after powering back up the node, then check for the following error:

         ```bash
         ncn-mw# kubectl describe pod -n user -lapp=slurmctld
         ```

         Example output:

         ```text
         Warning  FailedCreatePodSandBox  27m              kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code = 
         Unknown desc = failed to setup network for sandbox "82c575cc978db00643b1bf84a4773c064c08dcb93dbd9741ba2e581bc7c5d545": 
         Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for 
         range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
         ```

         ```bash
         ncn-mw# kubectl describe pod -n user -lapp=slurmdbd
         ```

         Example output:

         ```text
         Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code 
         = Unknown desc = failed to setup network for sandbox "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": 
         Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for 
         range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
         ```

         Remove the following files on every worker node to resolve the failure:

         * /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
         * /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf

    1. Disconnect from the console.

    1. Repeat all of the sub-steps above for the remaining storage nodes, going from the highest to lowest number, until all storage nodes have successfully rebooted.

    **Important:** Ensure that `ceph -s` shows that Ceph is healthy (`HEALTH_OK`) **BEFORE MOVING ON** to reboot the next storage node. Once Ceph has recovered the downed `mon`,
    it may take a several minutes for Ceph to resolve clock skew.

### NCN worker nodes

1. Reboot each of the worker nodes (one at a time), going from the highest to lowest number.

    **NOTE:** A single worker is being rebooted at a time, so be sure to follow the steps on the correct worker node.

    1. Establish a console session to the worker node being rebooted.

        **`IMPORTANT:`** If the ConMan console pod is on the node being rebooted, then the session must be re-established after the cordon/drain step.

        See [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    1. Failover any Postgres leader that is running on the worker node being rebooted.

       This script must be run from a master or worker node with the latest CSM documentation installed.
       See [Check for latest documentation](../../update_product_stream/index.md#check-for-latest-documentation).

       ```bash
       ncn-mw# /usr/share/doc/csm/upgrade/1.0.1/scripts/k8s/failover-leader.sh <node to be rebooted>
       ```

    1. Cordon and drain the node.

       ```bash
       ncn-mw# kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
       ```

       There may be pods that cannot be gracefully evicted because of Pod Disruption Budgets (PDB). This will result in messages like the following:

       ```text
       error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
       ```

       In this case, there are some options.
       First, if the service is scalable, then increase the scale to start up another pod on another node, and then the drain will be able to delete it.
       However, it will probably be necessary to force the deletion of the pod:

       ```bash
       ncn-mw# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
       ```

       This will delete the offending pod, and Kubernetes should schedule a replacement on another node.
       Then rerun the `kubectl drain` command, and it should report that the node is drained.

       ```bash
       ncn-mw# kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
       ```

    1. If booting from disk is desired, then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    1. Reboot the selected node.

        ```bash
        ncn-w# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below.

        1. Power off the node.

           > `read -s` is used to prevent the password from being written to the screen or the shell history.
           >
           > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-w002`.

           ```bash
           ncn# USERNAME=root
           ncn# read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
           ncn# export IPMI_PASSWORD
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power off
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
           ```

           Ensure that the power is reporting as off. It may take 5-10 seconds for this to update.
           Wait about 30 seconds after receiving the correct power status before issuing the next command.

        1. Power on the node.

           > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-w002`.

           ```bash
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power on
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
           ```

           Ensure that the power is reporting as on. It may take 5-10 seconds for this to update.

    1. Watch on the console until the node has successfully booted and the login prompt is reached.

    1. If desired, verify that the method of boot is as expected.

       If the `/proc/cmdline` file begins with `BOOT_IMAGE`, then this NCN booted from disk.

       ```bash
       ncn-w# egrep -o '^(BOOT_IMAGE|kernel)' /proc/cmdline
       ```

       Example output for a disk boot is:

       ```text
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    1. Retrieve the component name (xname) for the node that was rebooted.

       This xname is available on the node that was rebooted in the `/etc/cray/xname` file.

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    1. Check the Configuration Framework Service (CFS) `configurationStatus` for the rebooted node's `desiredConfig`.

       The following command will indicate if a CFS job is currently in progress for this node.
       Replace the `XNAME` value in the following command with the component name (xname) of the node that was rebooted.

       This can be run on any NCN where the Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```json
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,

         "lines omitted": "..."

       }
       ```

       * If the `configurationStatus` is `pending`, then wait for the job to finish before continuing.
       * If the `configurationStatus` is `failed`, then this means the failed CFS job `configurationStatus` should be addressed now for this node.
       * If the `configurationStatus` is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, then this can be ignored.
       * If the `configurationStatus` is `failed`, then see [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
         for how to analyze the pod logs from `cray-cfs` in order to determine why the configuration may not have completed.

    1. Remove the node cordon.

        ```bash
        ncn-mw# kubectl uncordon <node that just rebooted>
        ```

    1. Verify that pods are running on the rebooted node.

         Within a minute or two, the following command should begin to show pods in a `Running` state (replace NCN in the command below with the name of the rebooted worker node):

         ```bash
         ncn-mw# kubectl get pods -o wide -A | grep <node that was rebooted>
         ```

    1. Remove any dynamically assigned interface IP addresses that did not get released automatically by running the `CASMINST-2015.sh` script:

        ```bash
        ncn-mw# /usr/share/doc/csm/scripts/CASMINST-2015.sh
        ```

    1. Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

         Verify that the `Check the Health of the Etcd Clusters in the Services Namespace` check from the `ncnHealthChecks.sh` script returns a healthy report for all members of each etcd cluster.

         If terminating pods are reported when checking the status of the Kubernetes pods, then wait for all pods to recover before proceeding.

    1. Disconnect from the console.

    1. Repeat all of the sub-steps above for the remaining worker nodes, going from the highest to lowest number, until all worker nodes have successfully rebooted.

1. Ensure that BGP sessions are reset so that all BGP peering sessions with the spine switches are in an `ESTABLISHED` state.

   See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

### NCN master nodes

1. Reboot each of the master nodes (one at a time), going from the highest to lowest number, excluding `ncn-m001`. There are special instructions for `ncn-m001` later, because its console connection is not managed by ConMan.

    1. Establish a console session to the master node being rebooted.

        See step [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    1. If booting from disk is desired, then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    1. Reboot the selected node.

        ```bash
        ncn-m# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below.

        1. Power off the node.

           > `read -s` is used to prevent the password from being written to the screen or the shell history.
           >
           > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-m002`.

           ```bash
           ncn# USERNAME=root
           ncn# read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
           ncn# export IPMI_PASSWORD
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power off
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
           ```

           Ensure that the power is reporting as off. It may take 5-10 seconds for this to update.
           Wait about 30 seconds after receiving the correct power status before issuing the next command.

        1. Power on the node.

           > In the example commands below, be sure to replace `<node>` with the name of the node being rebooted. For example, `ncn-m002`.

           ```bash
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power on
           ncn# ipmitool -U "${USERNAME}" -E -H <node>-mgmt -I lanplus power status
           ```

           Ensure that the power is reporting as on. It may take 5-10 seconds for this to update.

    1. Watch on the console until the node has successfully booted and the login prompt is reached.

    1. If desired, verify that the method of boot is as expected.

       If the `/proc/cmdline` file begins with `BOOT_IMAGE`, then this NCN booted from disk.

       ```bash
       ncn-m# egrep -o '^(BOOT_IMAGE|kernel)' /proc/cmdline
       ```

       Example output for a disk boot is:

       ```text
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    1. Retrieve the component name (xname) for the node that was rebooted.

       This xname is available on the node that was rebooted in the `/etc/cray/xname` file.

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    1. Check the Configuration Framework Service (CFS) `configurationStatus` for the rebooted node's `desiredConfig`.

       The following command will indicate if a CFS job is currently in progress for this node.
       Replace the `XNAME` value in the following command with the component name (xname) of the node that was rebooted.

       This can be run on any NCN where the Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```json
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,

         "lines omitted": "..."

       }
       ```

       * If the `configurationStatus` is `pending`, then wait for the job to finish before continuing.
       * If the `configurationStatus` is `failed`, then this means the failed CFS job `configurationStatus` should be addressed now for this node.
       * If the `configurationStatus` is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, then this can be ignored.
       * If the `configurationStatus` is `failed`, then see [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
         for how to analyze the pod logs from `cray-cfs` in order to determine why the configuration may not have completed.

    1. Remove any dynamically assigned interface IP addresses that did not get released automatically by running the `CASMINST-2015.sh` script:

       ```bash
       ncn-m# /usr/share/doc/csm/scripts/CASMINST-2015.sh
       ```

    1. Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    1. Disconnect from the console.

    1. Repeat all of the sub-steps above for the remaining master nodes \(excluding `ncn-m001`\), going from the highest to lowest number, until all master nodes have successfully rebooted.

1. Reboot `ncn-m001`.

    1. Determine the CAN IP address for one of the other NCNs in the system, in order to establish an SSH session with that NCN.

    1. Establish a console session to `ncn-m001` from a system external to the cluster.

    1. If booting from disk is desired, then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    1. Power cycle the node.

        Ensure that the expected results are returned from the power status check before rebooting.

        > `read -s` is used to prevent the password from being written to the screen or the shell history.
        >
        > In the example commands below, be sure to replace `<ncn-m001-bmc>` with the external IP or hostname of the BMC of `ncn-m001`.

        ```bash
        external# USERNAME=root
        external# read -r -s -p "ncn-m001 BMC ${USERNAME} password: " IPMI_PASSWORD
        external# export IPMI_PASSWORD
        external# ipmitool -U "${USERNAME}" -E -H <ncn-m001-bmc> -I lanplus power status
        ```

        1. Power off `ncn-m001`.

            > In the example commands below, be sure to replace `<ncn-m001-bmc>` with the external IP or hostname of the BMC of `ncn-m001`.

            ```bash
            external# ipmitool -U "${USERNAME}" -E -H <ncn-m001-bmc> -I lanplus power off
            external# ipmitool -U "${USERNAME}" -E -H <ncn-m001-bmc> -I lanplus power status
            ```

            Ensure that power is reporting as off. It may take 5-10 seconds for this to update.
            Wait about 30 seconds after receiving the correct power status before issuing the next command.

        1. Power on the node.

            > In the example commands below, be sure to replace `<ncn-m001-bmc>` with the external IP or hostname of the BMC of `ncn-m001`.

            ```bash
            external# ipmitool -U "${USERNAME}" -E -H <ncn-m001-bmc> -I lanplus power on
            external# ipmitool -U "${USERNAME}" -E -H <ncn-m001-bmc> -I lanplus power status
            ```

            Ensure that the power is reporting as on. It may take 5-10 seconds for this to update.

    1. Watch on the console until the node has successfully booted and the login prompt is reached.

    1. If desired, verify that the method of boot is as expected.

       If the `/proc/cmdline` file begins with `BOOT_IMAGE`, then this NCN booted from disk.

       ```bash
       ncn-m001# egrep -o '^(BOOT_IMAGE|kernel)' /proc/cmdline
       ```

       Example output for a disk boot is:

       ```text
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    1. Retrieve the component name (xname) for the node that was rebooted.

        This xname is available on the node that was rebooted in the `/etc/cray/xname` file.

        ```bash
        ncn# ssh ncn-m001 cat /etc/cray/xname
        ```

    1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the `desiredConfig` after rebooting the node.

       The following command will indicate if a CFS job is currently in progress for this node.
       Replace the `XNAME` value in the following command with the component name (xname) of the node that was rebooted.

       This can be run on any NCN where the Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```json
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,

         "lines omitted": "..."

       }
       ```

       * If the `configurationStatus` is `pending`, then wait for the job to finish before continuing.
       * If the `configurationStatus` is `failed`, then this means the failed CFS job `configurationStatus` should be addressed now for this node.
       * If the `configurationStatus` is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, then this can be ignored.
       * If the `configurationStatus` is `failed`, then see [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
         for how to analyze the pod logs from `cray-cfs` in order to determine why the configuration may not have completed.

    1. Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    1. Disconnect from the console.

1. Remove any dynamically assigned interface IP addresses that did not get released automatically.

    This script must be run from `ncn-m001`, which must have the latest CSM documentation installed.
    See [Check for latest documentation](../../update_product_stream/index.md#check-for-latest-documentation).

   ```bash
   ncn-mw# /usr/share/doc/csm/scripts/CASMINST-2015.sh
   ```

1. Validate CSM health.

    At a minimum, run the platform health checks.

    See [Validate CSM Health](../validate_csm_health.md) for the platform health checks.
