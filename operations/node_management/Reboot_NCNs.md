# Reboot NCNs

The following is a high-level overview of the non-compute node \(NCN\) reboot workflow:

- Run the NCN pre-reboot checks and procedures:
   - Ensure `ncn-m001` is not running in "LiveCD" or install mode
   - Check the `metal.no-wipe` settings for all NCNs
   - Run all platform health checks, including checks on the Border Gateway Protocol \(BGP\) peering sessions
   - [Validate the current boot order](../../background/ncn_boot_workflow.md#determine-the-current-boot-order) (or [specify the boot order](../../background/ncn_boot_workflow.md#set-boot-order))
- Run the rolling NCN reboot procedure:
   - Loop through reboots on storage nodes, worker nodes, and master nodes, where each boot consists of the following workflow:
      - Establish console session with node to reboot
      - Execute a Linux graceful shutdown or power off/on sequence to the node to allow it to boot up to completion
      - Execute NCN/platform health checks and do not go on to reboot the next NCN until health has been ensured on the most recently rebooted NCN
      - Disconnect console session with the node that was rebooted
- Re-run all platform health checks, including checks on BGP peering sessions

The time duration for this procedure \(if health checks are being executed in between each boot, as recommended\) could take between two to four hours for a system with nine management nodes.

This same procedure can be used to reboot a single management node as outlined above. Be sure to carry out the NCN pre-reboot checks and procedures before and after rebooting the node. Execute the rolling NCN reboot procedure steps for the particular node type being rebooted.

## Prerequisites

The `kubectl` command is installed.

## Procedure

### NCN Pre-Reboot Health Checks

1. Ensure that `ncn-m001` is not running in "LiveCD" mode.

    This mode should only be in effect during the initial product install. If the word "pit" is NOT in the hostname of `ncn-m001`, then it is not in the "LiveCD" mode.

    If "pit" is in the hostname of `ncn-m001`, the system is not in normal operational mode and rebooting `ncn-m001` may have unexpected results. This procedure assumes that the node is not running in the "LiveCD" mode that occurs during product install.

1. Run the platform health checks and analyze the results.

    Refer to the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md) for an overview of the health checks.

    1. Run the platform health scripts from a master or worker node.

        The output of the following scripts will need to be referenced in the remaining sub-steps.

        ```bash
        ncn-m001# /opt/cray/platform-utils/ncnHealthChecks.sh
        ncn-m001# csi pit validate --postgres
        ```

        **`NOTE`**: If the ncnHealthChecks script output indicates any `kube-multus-ds-` pods are in a `Terminating` state, that can indicate a previous restart of these pods did not complete. In this case, it is safe to force delete these pods in order to let them properly restart by executing the `kubectl delete po -n kube-system kube-multus-ds.. --force` command. After executing this command, re-running the ncnHealthChecks script should indicate a new pod is in a `Running` state.


    1. Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting:

        ```bash
        ncn-m001# kubectl describe pod -n user -lapp=slurmctld
        ```

        ```bash
        ncn-m001# kubectl describe pod -n user -lapp=slurmdbd
        ```

        ```bash
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

        - /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
        - /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf

    1. Check that the BGP peering sessions are established.

        This check will need to be run after all worker node have been rebooted. Ensure that the checks have been run to check BGP peering sessions on the spine switches

        ```
        ncn-m001# SW_ADMIN_PASSWORD='SWITCH_PASSWORD' GOSS_BASE=/opt/cray/tests/install/ncn goss -g  /opt/cray/tests/install/ncn/tests/goss-switch-bgp-neighbor-aruba-or-mellanox.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
        ```

1. Ensure that no nodes are in a `failed` state in CFS.
    Nodes that are in a failed state prior to the reboot will not be automatically
    configured once they have been rebooted. To get a list of nodes in the failed state:
   
   ```
   ncn-m001# cray cfs components list --status failed --format json | jq .[].id
   ```
   
   If there are any nodes in this list, they can be reset with:
   
   ```
   ncn-m001# cray cfs components update <xname> --enabled False --error-count 0
   ```
   
   Or, to reset the error count for all nodes:
   
   ```
   ncn-m001# cray cfs components list --status failed | jq .[].id -r | while read -r xname ; do
       echo "$xname"
       cray cfs components update $xname --enabled False --error-count 0
   done
   ```
   
   This will leave the nodes in a disabled state in CFS. CFS will automatically
   re-enable them when they reboot, this is just so that CFS does not immediately
   start retrying configuration against the failed node.

### NCN Rolling Reboot

Before rebooting NCNs:

* Ensure pre-reboot checks have been completed, including checking the `metal.no-wipe` setting for each NCN. Do not proceed if any of the NCN `metal.no-wipe` settings are zero.

#### Utility Storage Nodes (Ceph)

1. Reboot each of the storage nodes (one at a time).

    1. Establish a console session to each storage node.

        Use the [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) procedure referenced in step 4.

    2. If booting from disk is desired then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    3. Reboot the selected node.

        ```bash
         ncn-s# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below

        1. To power off the node:
           
           ```bash
           ncn-m001# export USERNAME=root
           ncn-m001# export IPMI_PASSWORD=changeme
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power off
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
           ```

           Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        2. To power back on the node:
           
           ```bash
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power on
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
           ```

           Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    4. Watch on the console until the node has successfully booted and the login prompt is reached.

    5. If desired verify method of boot is expected. If the `/proc/cmdline` begins with `BOOT_IMAGE` then this NCN booted from disk:

       ```bash
       ncn# egrep -o '^(BOOT_IMAGE.+/kernel)' /proc/cmdline
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    6. Retrieve the component name (xname) for the node being rebooted.

       This xname is available on the node being rebooted in the following file:

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    7. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

       The following command will indicate if a CFS job is currently in progress for this node. Replace the `XNAME` value in the following command with the component name (xname) of the node being rebooted.

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,
       ```

       If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

       If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from cray-cfs to determine why the configuration may not have completed.

    8. Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

         **Troubleshooting:** If the slurmctld and slurmdbd pods do not start after powering back up the node, check for the following error:

         ```bash
         ncn-m001# kubectl describe pod -n user -lapp=slurmctld
         ```

         Example output:

         ```
         Warning  FailedCreatePodSandBox  27m              kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "82c575cc978db00643b1bf84a4773c064c08dcb93dbd9741ba2e581bc7c5d545": Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
         ```

         ```bash
         ncn-m001# kubectl describe pod -n user -lapp=slurmdbd
         ```

         Example output:

         ```
         Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
         ```

         Remove the following files on every worker node to resolve the failure:

         - /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
         - /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf

    9. Disconnect from the console.

    10. Repeat all of the sub-steps above for the remaining storage nodes, going from the highest to lowest number until all storage nodes have successfully rebooted.

    **Important:** Ensure `ceph -s` shows that Ceph is healthy (`HEALTH_OK`) **BEFORE MOVING ON** to reboot the next storage node. Once Ceph has recovered the downed mon,
    it may take a several minutes for Ceph to resolve clock skew.

#### NCN Worker Nodes

1. Reboot each of the worker nodes (one at a time).

    **NOTE:** You are doing a single worker at a time, so please keep track of what ncn-w0xx you are on for these steps.

    1. Establish a console session to the worker node you are rebooting.

        **`IMPORTANT:`** If the ConMan console pod is on the node being rebooted you will need to re-establish your session after the Cordon/Drain in step 2

        See [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    2. Failover any postgres leader that is running on the worker node you are rebooting.

       ```bash
       ncn-m# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/failover-leader.sh <node to be rebooted>
       ```

    3. Cordon and Drain the node

       ```bash
       ncn-m# kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
       ```

       You may run into pods that cannot be gracefully evicted because of Pod Disruption Budgets (PDB), for example:

       ```bash
       ncn-m# error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
       ```

       In this case, there are some options. First, if the service is scalable, you can increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

       ```bash
       ncn-m# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
       ```

       This will delete the offending pod, and Kubernetes should schedule a replacement on another node. You can then rerun the kubectl drain command, and it should report that the node is drained

       ```bash
       ncn-m# kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
       ```

    4. If booting from disk is desired then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    5. Reboot the selected node.

        ```bash
         ncn-w# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below

        1. To power off the node:
           
           ```bash
           ncn-m001# export USERNAME=root
           ncn-m001# export IPMI_PASSWORD=changeme
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power off
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
           ```

           Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        2. To power back on the node:
           
           ```bash
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power on
           ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
           ```

           Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    6. Watch on the console until the node has successfully booted and the login prompt is reached.

    7. If desired verify method of boot is expected. If the `/proc/cmdline` begins with `BOOT_IMAGE` then this NCN booted from disk:

       ```bash
       ncn# egrep -o '^(BOOT_IMAGE.+/kernel)' /proc/cmdline
       BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
       ```

    8. Retrieve the component name (xname) for the node being rebooted.

       This xname is available on the node being rebooted in the following file:

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    9. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

       The following command will indicate if a CFS job is currently in progress for this node. Replace the `XNAME` value in the following command with the component name (xname) of the node being rebooted.

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,
       ```

       If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

       If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from cray-cfs to determine why the configuration may not have completed.

    10.  Uncordon the node.

        ```bash
        ncn-m# kubectl uncordon <node you just rebooted>
        ```

    11.  Verify pods are running on the rebooted node.

         Within a minute or two, the following command should begin to show pods in a `Running` state (replace NCN in the command below with the name of the worker node):

         ```bash
         ncn-m# kubectl get pods -o wide -A | grep <node to be rebooted>
         ```

    12.  Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

         Verify that the `Check the Health of the Etcd Clusters in the Services Namespace` check from the ncnHealthChecks.sh script returns a healthy report for all members of each etcd cluster.

         If terminating pods are reported when checking the status of the Kubernetes pods, wait for all pods to recover before proceeding.

    13.  Disconnect from the console.

    14.  Repeat all of the sub-steps above for the remaining worker nodes, going from the highest to lowest number until all worker nodes have successfully rebooted.

2. Ensure that BGP sessions are reset so that all BGP peering sessions with the spine switches are in an ESTABLISHED state.

   See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

#### NCN Master Nodes

1. Reboot each of the master nodes (one at a time) starting with `ncn-m003` then `ncn-m001`. There are special instructions for `ncn-m001` below because its console connection is not managed by conman.

    1. Establish a console session to the master node you are rebooting.

        See step [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    2. If booting from disk is desired then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    3. Reboot the selected node.

        ```bash
         ncn-m001# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shut down after 5 minutes, then proceed with the power reset below

        To power off the node:

        ```bash
        ncn-m001# export USERNAME=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power off
        ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power on
        ncn-m001# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    4. Watch on the console until the node has successfully booted and the login prompt is reached.

    5. If desired verify method of boot is expected. If the `/proc/cmdline` begins with `BOOT_IMAGE` then this NCN booted from disk:

   ```bash
   ncn# egrep -o '^(BOOT_IMAGE.+/kernel)' /proc/cmdline
   BOOT_IMAGE=(mduuid/a3899572a56f5fd88a0dec0e89fc12b4)/boot/grub2/../kernel
   ```

    6. Retrieve the component name (xname) for the node being rebooted.

       This xname is available on the node being rebooted in the following file:

       ```bash
       ncn# ssh NODE cat /etc/cray/xname
       ```

    7. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

       The following command will indicate if a CFS job is currently in progress for this node. Replace the `XNAME` value in the following command with the component name (xname) of the node being rebooted.

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,
       ```

       If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

       If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from cray-cfs to determine why the configuration may not have completed.

    8. Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    9. Disconnect from the console.

    10. Repeat all of the sub-steps above for the remaining master nodes \(excluding `ncn-m001`\), going from the highest to lowest number until all master nodes have successfully rebooted.

2. Reboot `ncn-m001`.

    1. Determine the CAN IP address for one of the other NCNs in the system to establish an SSH session with that NCN.

    2. Establish a console session to `ncn-m001` from a remote system, as `ncn-m001` is the NCN that has an externally facing IP address.

    3. If booting from disk is desired then [set the boot order](../../background/ncn_boot_workflow.md#set-boot-order).

    4. Power cycle the node

        Ensure the expected results are returned from the power status check before rebooting:

        ```bash
        external# export USERNAME=root
        external# export IPMI_PASSWORD=changeme
        external# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
        ```

        To power off the node:

        ```bash
        external# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power off
        external# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        external# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power on
        external# ipmitool -U $USERNAME -E -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    5. Watch on the console until the node has successfully booted and the login prompt is reached.

    6. Retrieve the component name (xname) for the node being rebooted.

        This xname is available on the node being rebooted in the following file:

        ```bash
        ncn# ssh NODE cat /etc/cray/xname
        ```

    7. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

       The following command will indicate if a CFS job is currently in progress for this node. Replace the `XNAME` value in the following command with the component name (xname) of the node being rebooted.

       ```bash
       ncn# cray cfs components describe XNAME --format json
       ```

       Example output:

       ```
       {
         "configurationStatus": "configured",
         "desiredConfig": "ncn-personalization-full",
         "enabled": true,
         "errorCount": 0,
         "id": "x3000c0s7b0n0",
         "retryPolicy": 3,
       ```

       If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

       If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from cray-cfs to determine why the configuration may not have completed.

    8. Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    9. Disconnect from the console.

3. Remove any dynamically assigned interface IP addresses that did not get released automatically by running the CASMINST-2015 script:

```bash
ncn-m001# /usr/share/doc/csm/scripts/CASMINST-2015.sh
```

4. Re-run the platform health checks and ensure that all BGP peering sessions are Established with both spine switches.

    See [Validate CSM Health](../validate_csm_health.md) for the platform health checks.

    See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md) to check the BGP peering sessions.
