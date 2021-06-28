---
category: numbered
---

# Troubleshoot UAI Stuck in "ContainerCreating"

Instructions for admin to resovle issue when a UAI is stuck in the ContainerCreating state.

-   The UAI has been in the `ContainerCreating` status for several minutes.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Resolve issue causing a new UAI to be stuck in the `ContainerCreating`. This issue may occur due to an error with Macvlan showing no available IPs

    **Attention:** There is a hard limit to how many IP addresses \(and as a result UAIs\) are available on a node. If this limit is reached, the Macvlan error is valid. The UAI will be stay in the `ContainerCreating` status until an IP becomes available. However, if the admin knows there are available IPs and the error code still occurs, follow the steps below.

    **Warning:** This procedure restarts `kubelet` and `dockerd` and could have unintended consequences. Other services may stop and not restart correctly.


1.  Log in to an NCN as `root`.

2.  List the pods to find the name of the pod in `ContainerCreating`.

    ```screen
    ncn-w001# kubectl get pods -n user \| grep uai
    uai-user-04e0e58c-674d9d5b97-kgtj6                        1/1     Running             0          11m
    uai-user-91654d73-6f67c84676-zssq8                        1/1     Running             0          17m
    **uai-user-f62bef19-548dcd856-lg26j                         0/1     ContainerCreating   0          4m8s**
    ```

3.  List the pod details.

    Below is the "Events" section of the output, look for the bolded information.

    ```screen
    ncn-w001# kubectl describe pod -n user uai-user-f62bef19-548dcd856-lg26j
    Events:  Type     Reason                  Age                     From                Message  ----     ------                  ----                    ----                
    -------  Normal   Scheduled               5m14s                   default-scheduler   Successfully assigned default/uai-user-baecc887-5d88c99fd6-2wwtd to ncn-w001  
    Warning  FailedCreatePodSandBox  5m11s                   kubelet, ncn-w001  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container
     "ae15df320f5456fa557549e8750775c5eb4cedb6fdc2ed6875ab31e188e8ae7f" network for pod "uai-user-baecc887-5d88c99fd6-2wwtd": NetworkPlugin cni failed to set up pod 
    "uai-user-baecc887-5d88c99fd6-2wwtd_default" network: Multus: Err in tearing down failed plugins: Multus: error in invoke 
    Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.2.200.100-10.2.200.200  
    Warning  FailedCreatePodSandBox  5m8s                    kubelet, ncn-w001  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container
     "17a01880a3676b72766327cdda01abfeb95479f127cb0d72c23e30acfc34ce35" network for pod "uai-user-baecc887-5d88c99fd6-2wwtd": NetworkPlugin cni failed to set up pod
     "uai-user-baecc887-5d88c99fd6-2wwtd_default" network: Multus: Err in tearing down failed plugins: Multus: error in invoke 
    Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.2.200.100-10.2.200.200  
    Warning  FailedCreatePodSandBox  5m6s                    kubelet, ncn-w001  Failed create pod sandbox: 
    rpc error: code = Unknown desc = failed to set up sandbox container "37129554e71e75d7ecc50783dc7d7b5f02586fafabb7ceca1109cd56e7c8f6db" network for pod "uai-user-baecc887-5d88c99fd6-2wwtd": 
    NetworkPlugin cni failed to set up pod "uai-user-baecc887-5d88c99fd6-2wwtd_default" network: Multus: Err in tearing down failed plugins: Multus: error in invoke 
    **Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.2.200.100-10.2.200.200**
    ```

4.  Delete all the UAIs on the system.

    ```screen
    ncn-w001# cray uas uais delete
    This will delete all running UAIs, Are you sure? [y/N]: y
    [
    "Successfully deleted uai-user-04e0e58c-674d9d5b97-kgtj6",
    "Successfully deleted uai-user-91654d73-6f67c84676-zssq8",
    "Successfully deleted uai-user-f62bef19-548dcd856-lg26j",
    ]
    ```

5.  Log in to `ncn-w001`.

6.  Stop kubelet on `ncn-w001`.

    ```screen
    ncn-w001# systemctl stop kubelet.service
    ncn-w001# systemctl is-active kubeletdocker.service
    inactive
    ```

7.  Stop Docker on `ncn-w001`.

    ```screen
    ncn-w001# systemctl stop docker.service
    ncn-w001# systemctl is-active docker.service
    inactive
    ```

8.  Remove all files from /var/lib/cni/networks/macvlan-uas-nmn-conf.

    ```screen
    ncn-w001:/var/lib/cni/networks/macvlan-uas-nmn-conf # ls
    10.2.200.101  10.2.200.105  last_reserved_ip.0    lock
     
    ncn-w001:/var/lib/cni/networks/macvlan-uas-nmn-conf # sudo rm -rf \*
    ```

9.  Start kubelet.

    ```screen
    ncn-w001# systemctl start kubelet.service
    ncn-w001# systemctl is-active kubelet.service
    active 
    ```

10. Start Docker on `ncn-w001`.

    ```screen
    ncn-w001# systemctl start docker.service
    ncn-w001# systemctl is-active docker.service
    active 
    ```


**Parent topic:**[Troubleshoot UAS Issues](Troubleshoot_UAS_Issues.md)

