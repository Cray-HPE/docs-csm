# Reboot NCNs

The following is a high-level overview of the non-compute node \(NCN\) reboot workflow:

- Run the NCN pre-reboot checks and procedures:
  - Ensure `ncn-m001` is not running in "LiveCD" or install mode
  - Check the `metal.no-wipe` settings for all NCNs
  - Enable pod priorities
  - Run all platform health checks, including checks on the Border Gateway Protocol \(BGP\) peering sessions
- Run the rolling NCN reboot procedure:
  - Loop through reboots on storage NCNs, worker NCNs, and master NCNs, where each boot consists of the following workflow:
         - Establish console session with NCN to reboot
	 - Check the hostname of the NCN to be rebooted
         - Execute a power off/on sequence to the NCN to allow it to boot up to completion
	 - Check the hosthame of the NCN after reboot and reset it if it is not correct
         - Execute NCN/platform health checks and do not go on to reboot the next NCN until health has been ensured on the most recently  rebooted NCN
         -   Disconnect console session with the NCN that was rebooted
- Re-run all platform health checks, including checks on BGP peering sessions

The time duration for this procedure \(if health checks are being executed in between each boot, as recommended\) could take between two to four hours for a system with approximately nine NCNs.

This same procedure can be used to reboot a single NCN node as outlined above. Be sure to carry out the NCN pre-reboot checks and procedures before and after rebooting the node. Execute the rolling NCN reboot procedure steps for the particular node type being rebooted.

## Prerequisites

This procedure requires that the `kubectl` command is installed.

It also requires that the **CSM_SCRIPTDIR variable was previously defined** as part of the execution of the steps in the csm-0.9.5 upgrade README. You can verify that it is set by running `echo $CSM_SCRIPTDIR` on the ncn-m001 cli. If that returns nothing, re-execute the setting of that variable from the [csm-0.9.5 README](../../README.md) file.

## Procedure

### NCN Pre-Reboot Health Checks

1.  Ensure that `ncn-m001` is not running in "LiveCD" mode.

    This mode should only be in effect during the initial product install. If the word "pit" is NOT in the hostname of `ncn-m001`, then it is not in the "LiveCD" mode.

    If "pit" is in the hostname of `ncn-m001`, the system is not in normal operational mode and rebooting `ncn-m001` may have unexpected results. This procedure assumes that the node is not running in the "LiveCD" mode that occurs during product install.

2.  Check and set the `metal.no-wipe` setting on NCNs to ensure data on the node is preserved when rebooting.

    Refer to [Check and Set the metal.no-wipe Setting on NCNs](Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md).

3.  Run the following script to enable a Kubernetes scheduling pod priority class for a set of critical pods.

    ```bash
    ncn-m001# "${CSM_SCRIPTDIR}/add_pod_priority.sh"
    ```

4.  Run the platform health checks and analyze the results.

    Refer to the "Platform Health Checks" section in [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) for an overview of the health checks.

    Please note that though the CSM validation document references running the the HealthCheck scripts from /opt/cray/platform-utils, more recent versions of those scripts are referenced in the instructions below. Please ensure they are run from the location referenced below.
  
    1.  Run the platform health scripts from ncn-m001:

        The output of the following scripts will need to be referenced in the remaining sub-steps.

        ```bash
        ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
        ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
        ```

        **`NOTE`**: If the ncnHealthChecks script output indicates any `kube-multus-ds-` pods are in a `Termininating` state, that can indicate a previous restart of these pods did not complete. In this case, it is safe to force delete these pods in order to let them properly restart by executing the `kubectl delete po -n kube-system kube-multus-ds.. --force` command. After executing this command, re-running the ncnHealthChecks script should indicate a new pod is in a `Running` state.

    2.  Check the status of the Kubernetes nodes.

        Ensure all Kubernetes nodes are in the Ready state.

        ```bash
        ncn-m001# kubectl get nodes
        ```

        **Troubleshooting:** If the NCN that was rebooted is in a Not Ready state, run the following command to get more information.

        ```bash
        ncn-m001# kubectl describe node NCN_HOSTNAME
        ```

        Verify the worker or master NCN is now in a Ready state:

        ```bash
        ncn-m001# kubectl get nodes
        ```

    3.  Check the status of the Kubernetes pods.

        The bottom of the output returned after running the `${CSM_SCRIPTDIR}/ncnHealthChecks.sh` script will show a list of pods that may be in a bad state. The following command can also be used to look for any pods that are not in a Running or Completed state:

        ```bash
        ncn-m001# kubectl get pods -o wide -A | grep -Ev 'Running|Completed'
        ```

        It is important to pay attention to that list, but it is equally important to note what pods are in that list before and after NCN reboots to determine if the reboot caused any new issues.

        There are pods that may normally be in an Error, Not Ready, or Init state, and this may not indicate any problems caused by the NCN reboots. Error states can indicate that a job pod ran and ended in an Error. That means that there may be a problem with that job, but does not necessarily indicate that there is an overall health issue with the system. The key takeaway (for health purposes) is understanding the statuses of pods prior to doing an action like rebooting all of the NCNs. Comparing the pod statuses in between each NCN reboot will give a sense of what is new or different with respect to health.

    4.  Monitor Ceph health continuously.

        In a separate cli session, run the following command during NCN reboots:

        ```bash
        ncn-m001# watch -n 10 'ceph -s'
        ```

        This window can be kept up throughout the reboot process to ensure Ceph remains healthy and to watch if Ceph goes into a WARN state when rebooting storage NCNs. It will be necessary to run it from an ssh session to an NCN that is not the one being rebooted.

    5.  Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting:

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

    6.  Check that the BGP peering sessions are established by using [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

        This check will need to be run now and after all worker NCNs have been rebooted. Ensure that the checks have been run to check BGP peering sessions on the BGP peer switches (instructions will vary for Aruba and Mellanox switches).

### NCN Rolling Reboot

Before rebooting NCNs:

* Ensure pre-reboot checks have been completed, including checking the `metal.no-wipe` setting for each NCN. **Do not proceed** if any of the NCN `metal.no-wipe` settings are zero.

#### Utility Storage Nodes (Ceph)

Reboot each of the NCN storage nodes **one at a time** going from the highest to the lowest number.

1. Establish a console session to each NCN storage node.
   1. Use the `${CSM_SCRIPTDIR}/ncnGetXnames.sh` script to get the xnames for each of the NCNs.
   2. Use cray-conman to observe each node as it boots:

      ```bash
      ncn-m001# kubectl exec -it -n services cray-conman-<hash> cray-conman -- /bin/bash
      cray-conman# conman -q
      cray-conman# conman -j XNAME
      ```

      **NOTE:** Exiting the connection to the console can be achieved with the `&.` command.

2. Check and take note of the hostname of the storage NCN by running the following command on the NCN which will be rebooted.

    ```bash
    ncn-s# hostname
    ```

3. Reboot the selected NCN (run this command on the NCN which needs to be rebooted).

    ```bash
    ncn-s# shutdown -r now
    ```

    **`IMPORTANT:`** If the node does not shutdown after 5 mins, then proceed with the power reset below

    To power off the node:

    ```bash
    ncn-m001# hostname=ncn-s001 # Set the NCN being rebooted
    ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power off
    ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
    ```

    Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

    To power back on the node:

    ```bash
    ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power on
    ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
    ```

    Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

4.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

5.  Login to the storage NCN and ensure that the hostname matches what was being reported before the reboot.

    ```bash
    ncn-s# hostname
    ```

    If the hostname after reboot does not match the hostname from before the reboot, the hostname will need to be reset followed by another reboot. 
    The following command will need to be run on the cli for the NCN that has just been rebooted (and is incorrect).

    ```bash
    ncn-s# hostnamectl set-hostname $hostname
    ```

    where `$hostname` is the original hostname from before reboot

    Follow the procedure outlined above to `Reboot the selected NCN` again and verify the hostname is correctly set, afterward.

6.  Run the platform health checks from the [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) procedure.

    Recall that updated copies of the two HealthCheck scripts referenced in the `Platform Health Checks` can be run from here:

    ```bash
    ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
    ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
    ```

    **Troubleshooting:** If the slurmctld and slurmdbd pods do not start after powering back up the node, check for the following error:

    ```bash
    ncn-m001# kubectl describe pod -n user -lapp=slurmctld
    Warning  FailedCreatePodSandBox  27m              kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "82c575cc978db00643b1bf84a4773c064c08dcb93dbd9741ba2e581bc7c5d545": Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
    ```

    ```bash
    ncn-m001# kubectl describe pod -n user -lapp=slurmdbd
    Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": Multus: Err in tearing down failed plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
    ```

    Remove the following files on every worker node to resolve the failure:

    - /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
    - /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf

7.  Disconnect from the console.

8.  Repeat all of the sub-steps above for the remaining storage nodes, going from the highest to lowest number until all storage nodes have successfully rebooted.

    **Important:** Ensure `ceph -s` shows that Ceph is healthy BEFORE MOVING ON to reboot the next storage node. Once Ceph has recovered the downed mon, 
it may take a several minutes for Ceph to resolve clock skew.

#### NCN Worker Nodes

1.  Reboot each of the NCN worker nodes \(one at a time\).

    **NOTE:** You are doing a single worker at a time, so please keep track of what ncn-w0xx you are on for these steps.

    1.  Establish a console session to the NCN worker node you are rebooting.

        **`IMPORTANT:`** If the ConMan console pod is on the worker node being rebooted you will need to re-establish your session after the Cordon/Drain in step 2

        Locate the `Booting CSM Barebones Image` section in [Validate CSM Health](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image). 
        Within that section, there are sub-steps for [Verify Consoles](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image#csm-consoles) and [Watch Boot on Console](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image#csm-watch). Follow these procedures to establish a console session and watch the boot-up of the appropriate NCN.
        
        **NOTE:** "${CSM_SCRIPTDIR}/ncnGetXnames.sh" can be run to get the xname for each NCN.
        
        **ALSO NOTE:** Exiting the connection to the console can be achieved with the `&.` command.

    2.  Check and take note of the hostname of the worker NCN by running the following command on the NCN which will be rebooted.

        ```bash
    	ncn-w# hostname
    	```

    3.  Failover any postgres leader that is running on the NCN worker node you are rebooting.

        ````bash
        ncn-m001# "${CSM_SCRIPTDIR}/failover-leader.sh <node to be rebooted>"
        ````

    4.  Cordon and Drain the node

        ```bash
        ncn-w# kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
        ```

    5.  Reboot the selected NCN (run this command on the NCN which needs to be rebooted).

        ```bash
        ncn-w# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shutdown after 5 mins, then proceed with the power reset below

        To power off the node:

        ```bash
        ncn-m001# hostname=ncn-w001 # Set the NCN being rebooted
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power off
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power on
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    6.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    7.  Login to the worker NCN and ensure that the hostname matches what was being reported before the reboot.

        ```bash
        ncn-w# hostname
        ```
        If the hostname after reboot does not match the hostname from before the reboot, the hostname will need to be reset followed by another reboot.  
        The following command will need to be run on the cli for the NCN that has just been rebooted (and is incorrect).

        ```bash
        ncn-w# hostnamectl set-hostname $hostname
        ```
        where `$hostname` is the original hostname from before reboot

        Follow the procedure outlined above to `Reboot the selected NCN` again and verify the hostname is correctly set, afterward.

    8.  Uncordon the node

        ```bash
        ncn-m# kubectl uncordon <node you just rebooted>
        ```

    9.  Run the platform health checks from the [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) procedure.

        Recall that updated copies of the two HealthCheck scripts referenced in the `Platform Health Checks` can be run from here:

        ```bash
        ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
        ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
        ```

        Verify that the `Check the Health of the Etcd Clusters in the Services Namespace` check from the ncnHealthChecks.sh script returns a healthy report for all members of each etcd cluster.

        If terminating pods are reported when checking the status of the Kubernetes pods, wait for all pods to recover before proceeding.

    10. Disconnect from the console.

    11. Repeat all of the sub-steps above for the remaining worker nodes, going from the highest to lowest number until all worker nodes have successfully rebooted.

    12. Ensure that BGP sessions are reset so that all BGP peering sessions with the spine switches are in an ESTABLISHED state.

        See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

#### NCN Master Nodes

1. Reboot each of the NCN master nodes \(one at a time\), **except for ncn-m001**.

    1.  Establish a console session to the NCN master node you are rebooting.

        Locate the `Booting CSM Barebones Image` section in [Validate CSM Health](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image). 
        Within that section, there are sub-steps for [Verify Consoles](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image#csm-consoles) and [Watch Boot on Console](../../../../../008-CSM-VALIDATION.md#booting-csm-barebones-image#csm-watch). Follow these procedures to establish a console session and watch the boot-up of the appropriate NCN.

        **NOTE:** "${CSM_SCRIPTDIR}/ncnGetXnames.sh" can be run to get the xname for each NCN.
        
        **ALSO NOTE:** Exiting the connection to the console can be achieved with the `&.` command.

    2.  Check and take note of the hostname of the master NCN by running the command on the NCN that will be rebooted.

        ```bash
        ncn-m# hostname
        ```

    3.  Reboot the selected NCN (run this command on the NCN which needs to be rebooted).

        ```bash
        ncn-m# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shutdown after 5 mins, then proceed with the power reset below

        To power off the node:

        ```bash
        ncn-m001# hostname=ncn-m002 # Set the NCN being rebooted
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power off
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power on
        ncn-m001# ipmitool -U root -P PASSWORD -H ${hostname}-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    4.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    5.  Login to the master NCN and ensure that the hostname matches what was being reported before the reboot.

        ```bash
        ncn-m# hostname
        ```

        If the hostname after reboot does not match the hostname from before the reboot, the hostname will need to be reset followed by another reboot. 
        The following command will need to be run on the cli for the NCN that has just been rebooted (and is incorrect).

        ```bash
        ncn-m# hostnamectl set-hostname $hostname
        ```
        where `$hostname` is the original hostname from before reboot

        Follow the procedure outlined above to `Reboot the selected NCN` again and verify the hostname is correctly set, afterward.


    6.  Run the platform health checks from the [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) procedure.

        Recall that updated copies of the two HealthCheck scripts referenced in the `Platform Health Checks` can be run from here:

        ```bash
        ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
        ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
        ```

    7.  Disconnect from the console.

    8.  Repeat all of the sub-steps above for the remaining master nodes \(excluding `ncn-m001`\), going from the highest to lowest number until all master nodes have successfully rebooted.

2. Reboot `ncn-m001`.

    1.  Determine the CAN IP address for one of the other NCNs in the system to establish an SSH session with that NCN.

        ```bash
        ncn-m001# ssh ncn-m002
        ncn-m002# ip a show vlan007 | grep inet
        ```

        Expected output looks similar to the following:
    
        ```
        inet 10.102.11.13/24 brd 10.102.11.255 scope global vlan007
        inet6 fe80::1602:ecff:fed9:7820/64 scope link
        ```
        
        Now login from another machine to verify that IP is usable:
        
        ```bash
        external# ssh root@10.102.11.13
        ncn-m002#
        ```

    2.  Establish a console session to `ncn-m001` from a remote system, as the BMC of `ncn-m001` is the NCN that has an externally facing IP address.
        ```bash
        external# SYSTEM_NAME=eniac
        external# ipmitool -I lanplus -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt chassis power status
        external# ipmitool -I lanplus -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt sol activate
        ```

    3.  Check and take note of the hostname of the ncn-m001 NCN by running this command on it:

        ```bash
        ncn-m001# hostname
        ```

    3.  Reboot `ncn-m001`.

        ```bash
        ncn-m001# shutdown -r now
        ```

        **`IMPORTANT:`** If the node does not shutdown after 5 mins, then proceed with the power reset below

        To power off the node:

        ```bash
        external# SYSTEM_NAME=eniac
        external# ipmitool -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt -I lanplus power off
        external# ipmitool -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt -I lanplus power on
        ncn-m001# ipmitool -U root -P PASSWORD -H ${SYSTEM_NAME}-ncn-m001-mgmt -I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    4.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    5.  Login to `ncn-m001` and ensure that the hostname matches what was being reported before the reboot.

        ```bash
        ncn-m001# hostname
        ```
        If the hostname after reboot does not match the hostname from before the reboot, the hostname will need to be reset followed by another reboot.  
        The following command will need to be run on the cli for the NCN that has just been rebooted (and is incorrect).

        ```bash
        ncn-m001# hostname=ncn-m001
        ncn-m001# hostnamectl set-hostname $hostname
        ```
        where `$hostname` is the original hostname from before reboot

        Follow the procedure outlined above to `Power cycle the node` again and verify the hostname is correctly set, afterward.

    7. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM for the CSM 0.9.5 patch:

        ```bash
        ncn-m001# export CSM_SCRIPTDIR=/usr/share/doc/metal/upgrade/0.9/csm-0.9.5/scripts
        ```

    6.  Run the platform health checks from the [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) procedure.

        Recall that updated copies of the two HealthCheck scripts referenced in the `Platform Health Checks` can be run from here:

        ```bash
        ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
        ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
        ```

    7.  Disconnect from the console.

3.  Re-run the platform health checks and ensure that all BGP peering sessions are Established with both spine switches.

    See [Validate CSM Health](../../../../../008-CSM-VALIDATION.md) for the section titled `Platform Health Checks.`

    Recall that updated copies of the two HealthCheck scripts referenced in the `Platform Health Checks` can be run from here:

    ```bash
    ncn-m001# "${CSM_SCRIPTDIR}/ncnHealthChecks.sh"
    ncn-m001# "${CSM_SCRIPTDIR}/ncnPostgresHealthChecks.sh"
    ```

    See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md) to check the BGP peering sessions.
