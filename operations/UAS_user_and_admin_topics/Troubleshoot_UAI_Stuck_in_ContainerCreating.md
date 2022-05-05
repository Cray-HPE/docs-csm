# Troubleshoot UAI Stuck in `ContainerCreating`

Resolve an issue causing UAIs to show a `uai_status` field of `Waiting`, and a `uai_msg` field of `ContainerCreating`.
It is possible that this is just a matter of starting the UAI taking longer than normal, perhaps as it pulls in a new UAI image from a registry. If the issue persists for a long time, it is worth investigating.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must be on an NCN or host that has Kubernetes (`kubectl` command) access to the HPE Cray EX System

## Symptoms

The UAI has been in the `ContainerCreating` status for several minutes.

## Procedure

1. Find the UAI.

    ```bash
    ncn-m001-pit# cray uas admin uais list --owner ctuser
    ```

    Example output:

    ```bash
    [[results]]
    uai_age = "1m"
    uai_connect_string = "ssh ctuser@10.103.13.159"
    uai_host = "ncn-w001"
    uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.103.13.159"
    uai_msg = "ContainerCreating"
    uai_name = "uai-ctuser-bcd1ff74"
    uai_status = "Waiting"
    username = "ctuser"
    ```

2. Look up the UAI's pod in Kubernetes.

    ```bash
    ncn-m001-pit# kubectl get po -n user | grep uai-ctuser-bcd1ff74
    ```

    Example output:

    ```bash
    uai-ctuser-bcd1ff74-7d94967bdc-4vm66   0/1     ContainerCreating   0          2m58s
    ```

3. Describe the pod in Kubernetes.

    ```bash
    ncn-m001-pit# kubectl describe pod -n user uai-ctuser-bcd1ff74-7d94967bdc-4vm66
    ```

    Example output:

    ```bash
    Name:                 uai-ctuser-bcd1ff74-7d94967bdc-4vm66
    Namespace:            user
    Priority:             -100
    Priority Class Name:  uai-priority
    Node:                 ncn-w001/10.252.1.12
    Start Time:           Wed, 03 Feb 2021 18:33:00 -0600

    [...]

    Events:
    Type     Reason       Age                    From               Message
    ----     ------       ----                   ----               -------
    Normal   Scheduled    <unknown>              default-scheduler  Successfully assigned user/uai-ctuser-bcd1ff74-7d94967bdc-4vm66 to ncn-w001
    Warning  FailedMount  2m53s (x8 over 3m57s)  kubelet, ncn-w001  MountVolume.SetUp failed for volume "broker-sssd-config" : secret "broker-sssd-conf" not found
    Warning  FailedMount  2m53s (x8 over 3m57s)  kubelet, ncn-w001  MountVolume.SetUp failed for volume "broker-sshd-config" : configmap "broker-sshd-conf" not found
    Warning  FailedMount  2m53s (x8 over 3m57s)  kubelet, ncn-w001  MountVolume.SetUp failed for volume "broker-entrypoint" : configmap "broker-entrypoint" not found
    Warning  FailedMount  114s                   kubelet, ncn-w001  Unable to attach or mount volumes: unmounted volumes=[broker-sssd-config broker-entrypoint broker-sshd-config], unattached volumes=[optcraype optlmod etcprofiled optr
    optforgelicense broker-sssd-config lustre timezone optintel optmodulefiles usrsharelmod default-token-58t5p
    optarmlicenceserver optcraycrayucx slurm-config opttoolworks optnvidiahpcsdk munge-key optamd opttotalview optgcc
    opttotalviewlicense broker-entrypoint broker-sshd-config etccrayped opttotalviewsupport optcraymodulefilescrayucx optforge
    usrlocalmodules varoptcraypepeimages]: timed out waiting for the condition
    ```

    This produces a lot of output, all of which can be useful for diagnosis. A good place to start is in the `Events` section at the bottom.
    Notice the warnings here about volumes whose secrets and ConfigMaps are not found.
    In this case, that means the UAI cannot start because it was started in legacy mode without a default UAI class,
    and some of the volumes configured in the UAS are in the `uas` namespace to support localization of Broker UAIs and cannot be found in the `user` namespace.
    To solve this particular problem, configure a default UAI class with the correct volume list in it, delete the UAI, and allow the user to try creating it again using the default class.

    Other problems can usually be quickly identified using this and other information found in the output from the `kubectl describe pod` command.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot Duplicate Mount Paths in a UAI](Troubleshoot_Duplicate_Mount_Paths_in_a_UAI.md)
