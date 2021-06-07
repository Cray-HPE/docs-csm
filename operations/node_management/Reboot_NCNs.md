## Reboot NCNs

The following is a high-level overview of the non-compute node \(NCN\) reboot workflow:

-   Run the NCN pre-reboot checks and procedures:
    -   Ensure `ncn-m001` is not running in "LiveCD" or install mode
    -   Check the `metal.no-wipe` settings for all NCNs
    -   Run all platform health checks, including checks on the Border Gateway Protocol \(BGP\) peering sessions
-   Run the rolling NCN reboot procedure:
    -   Loop through reboots on storage NCNs, worker NCNs, and master NCNs, where each boot consists of the following workflow:
        -   Establish console session with NCN to reboot
        -   Execute a power off/on sequence to the NCN to allow it to boot up to completion
        -   Execute NCN/platform health checks and do not go on to reboot the next NCN until health has been ensured on the most recently rebooted NCN
        -   Disconnect console session with the NCN that was rebooted
-   Re-run all platform health checks, including checks on BGP peering sessions

The time duration for this procedure \(if health checks are being executed in between each boot, as recommended\) could take between two to four hours for a system with approximately nine NCNs.

This same procedure can be used to reboot a single NCN node as outlined above. Be sure to carry out the NCN pre-reboot checks and procedures before and after rebooting the node. Execute the rolling NCN reboot procedure steps for the particular node type being rebooted.

### Prerequisites

The `kubectl` command is installed.

### Procedure

#### NCN Pre-Reboot Health Checks

1.  Ensure that `ncn-m001` is not running in "LiveCD" mode.

    This mode should only be in effect during the initial product install. If the word "pit" is NOT in the hostname of `ncn-m001`, then it is not in the "LiveCD" mode.

    If "pit" is in the hostname of `ncn-m001`, the system is not in normal operational mode and rebooting `ncn-m001` may have unexpected results. This procedure assumes that the node is not running in the "LiveCD" mode that occurs during product install.

2.  Check and set the `metal.no-wipe` setting on NCNs to ensure data on the node is preserved when rebooting.

    Refer to [Check and Set the metal.no-wipe Setting on NCNs](Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md).

3.  Run the platform health checks and analyze the results.

    Refer to the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md) for an overview of the health checks.

    1.  Run the platform health scripts from a master or worker NCN.

        The output of the following scripts will need to be referenced in the remaining sub-steps.

        ```bash
        ncn-m001# cd /opt/cray/platform-utils
        ncn-m001# ./ncnHealthChecks.sh
        ncn-m001# ./ncnPostgresHealthChecks.sh
        ```

    2.  Check the status of the Kubernetes nodes.

        Ensure all Kubernetes nodes are in the Ready state.

        ```bash
        ncn-m001# kubectl get nodes
        ```

        **Troubleshooting:** If the NCN that was rebooted is in a Not Ready state, run the following command to get more information.

        ```bash
        ncn-m001# kubectl describe node NCN_HOSTNAME
        ```

        If that file is empty, run the following work-around to populate this file:

        ```bash
        ncn-m001# cp /srv/cray/resources/common/containerd/00-multus.conf \
        /etc/cni/net.d/00-multus.conf
        ncn-m001# cat /etc/cni/net.d/00-multus.conf
        ```

        Verify the worker or master NCN is now in a Ready state:

        ```bash
        ncn-m001# kubectl get nodes
        ```

    3.  Check the status of the Kubernetes pods.

        The bottom of the output returned after running the /opt/cray/platform-utils/ncnHealthChecks.sh script will show a list of pods that may be in a bad state. The following command can also be used to look for any pods that are not in a Running or Completed state:

        ```bash
        ncn-m001# kubectl get pods -o wide -A | grep -Ev 'Running\|Completed'
        ```

        It is important to pay attention to that list, but it is equally important to note what pods are in that list before and after NCN reboots to determine if the reboot caused any new issues.

        There are pods that may normally be in an Error, Not Ready, or Init state, and this may not indicate any problems caused by the NCN reboots. Error states can indicate that a job pod ran and ended in an Error. That means that there may be a problem with that job, but does not necessarily indicate that there is an overall health issue with the system. The key takeaway \(for health purposes\) is understanding the statuses of pods prior to doing an action like rebooting all of the NCNs. Comparing the pod statuses in between each NCN reboot will give a sense of what is new or different with respect to health.

    4.  Verify Ceph health.

        This output is included in the /opt/cray/platform-utils/ncnHealthChecks.sh script

        Run the following command during NCN reboots

        ```bash
        ncn-m001# watch -n 10 'ceph -s'
        ```

        This window can be kept up throughout the reboot process to ensure Ceph remains healthy and to watch if Ceph goes into a WARN state when rebooting storage NCNs.

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

        -   /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
        -   /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf
    
    6.  Check that the BGP peering sessions are established.

        This check will need to be run after all worker NCNs have been rebooted. Ensure that the checks have been run to check BGP peering sessions on the spine switches \(instructions will vary for Aruba and Mellanox switches\)

        If there are BGP Peering sessions that are not ESTABLISHED on either switch, refer to [Check BGP Status and Reset Sessions](../metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

4.  Establish a serial console session to the NCNs.

    See [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md).


#### NCN Rolling Reboot 

Before rebooting NCNs, ensure pre-reboot checks have been completed, including checking the `metal.no-wipe` setting for each NCN. Do not proceed if any of the NCN `metal.no-wipe` settings are zero.

5.  Reboot each of the NCN storage nodes \(one at a time\).

    1.  Establish a console session to each NCN storage node.

        Use the [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) procedure referenced in step 4.

    2.  Power cycle the highest numbered NCN storage node \(`ncn-s0xx`\).

        Ensure the expected results are returned from the power status check before rebooting:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        To power off the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power off
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power on
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    3.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    4.  Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

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

        -   /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
        -   /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf
    
    5.  Disconnect from the console.

    6.  Repeat all of the sub-steps above for the remaining storage nodes, going from the highest to lowest number until all storage nodes have successfully rebooted.

        **Important:** Ensure the ceph -s shows that Ceph is healthy BEFORE MOVING ON to reboot the next storage node. Once Ceph has recovered the downed mon, it may take a several minutes for Ceph to resolve clock skew.

6.  Reboot each of the NCN worker nodes \(one at a time\).

    1.  Establish a console session to each NCN worker node.

        Ensure that ConMan is not running on the worker node being rebooted.

        See [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    2.  Power cycle the highest numbered NCN worker node \(`ncn-w0xx`\).

        Ensure the expected results are returned from the power status check before rebooting:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        To power off the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power off
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power on
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    3.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    4.  Run the platform health checks from the [Validate CSM Health](../validate_csm_health.md) procedure.

        Verify that the `Check the Health of the Etcd Clusters in the Services Namespace` check from the ncnHealthChecks.sh script returns a healthy report for all members of each etcd cluster.

        If terminating pods are reported when checking the status of the Kubernetes pods, wait for all pods to recover before proceeding.

    5.  Disconnect from the console.

    6.  Repeat all of the sub-steps above for the remaining worker nodes, going from the highest to lowest number until all worker nodes have successfully rebooted.

    7.  Ensure that BGP sessions are reset so that all BGP peering sessions with the spine switches are in an ESTABLISHED state.

        See [Check BGP Status and Reset Sessions](../metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

7.  Reboot each of the NCN master nodes \(one at a time\).

    1.  Establish a console session to each NCN master node.

        See step [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md) for more information.

    2.  Power cycle the highest numbered NCN master node \(`ncn-m0xx`\).

        Ensure the expected results are returned from the power status check before rebooting:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        To power off the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power off
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power on
        ncn-m001# ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    3.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    4.  Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    5.  Disconnect from the console.

    6.  Repeat all of the sub-steps above for the remaining master nodes \(excluded `ncn-m001`\), going from the highest to lowest number until all master nodes have successfully rebooted.

8.  Reboot `ncn-m001`.

    1.  Determine the CAN IP address for one of the other NCNs in the system to establish an SSH session with that NCN.

    2.  Establish a console session to `ncn-m001` from a remote system, as `ncn-m001` is the NCN that has an externally facing IP address.

    3.  Power cycle the node

        Ensure the expected results are returned from the power status check before rebooting:

        ```bash
        # ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        To power off the node:

        ```bash
        # ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power off
        # ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

        To power back on the node:

        ```bash
        # ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power on
        # ipmitool -U root -H ${hostname}-mgmt -P PASSWORD-I lanplus power status
        ```

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

    4.  Watch on the console until the NCN has successfully booted and the login prompt is reached.

    5.  Run the platform health checks in [Validate CSM Health](../validate_csm_health.md).

    6.  Disconnect from the console.

9.  Re-run the platform health checks and ensure that all BGP peering sessions are Established with both spine switches.

    See [Validate CSM Health](../validate_csm_health.md) for the platform health checks.

    See [Check BGP Status and Reset Sessions](../metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md) to check the BGP peering sessions.

