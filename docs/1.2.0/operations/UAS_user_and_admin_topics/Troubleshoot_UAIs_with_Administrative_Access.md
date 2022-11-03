# Troubleshoot UAIs with Administrative Access

Sometimes there is no better way to figure out a problem with a UAI than to get inside it and look around as an administrator. This is done using `kubectl exec` to start a shell
inside the running container as `root` (in the container). With this an administrator can diagnose problems, make changes to the running UAI, and find solutions. It is important
to remember that any change made inside a UAI is transitory. These changes only last as long as the UAI is running. To make a permanent change, either the UAI image has to be
changed or external customizations must be applied.

## Summary

The high-level steps of the procedure are the following:

1. Find the name of the UAI in question.
1. Use that name with `kubectl` to find the pod containing that UAI.
1. Use that pod name, the UAI name (as the container name), and the `user` namespace to open an interactive shell in the container with `kubectl exec`.
1. From this shell, look around the UAI as needed.

## Example

Here is an example session showing a `ps` command inside the container of a UAI by an administrator.

1. List the UAIs.

    ```console
    ncn# cray uas admin uais list
    ```

    Example output:

    ```text
    [[results]]
    uai_age = "1d4h"
    uai_connect_string = "ssh broker@10.103.13.162"
    uai_host = "ncn-w001"
    uai_img = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
    uai_ip = "10.103.13.162"
    uai_msg = ""
    uai_name = "uai-broker-2e6ce6b7"
    uai_status = "Running: Ready"
    username = "broker"
    
    [[results]]
    uai_age = "0m"
    uai_connect_string = "ssh vers@10.29.162.104"
    uai_host = "ncn-w001"
    uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.29.162.104"
    uai_msg = ""
    uai_name = "uai-vers-4ebe1966"
    uai_status = "Running: Ready"
    username = "vers"
    ```

1. Find the pod name.

    ```console
    ncn# kubectl get po -n user | grep uai-vers-4ebe1966
    ```

    Example output:

    ```text
    uai-vers-4ebe1966-77b7c9c84f-xgqm4     1/1     Running   0          77s
    ```

1. Open an interactive shell in the pod.

    ```console
    ncn# kubectl exec -it -n user uai-vers-4ebe1966-77b7c9c84f-xgqm4 -c uai-vers-4ebe1966 -- /bin/sh
    ```

1. Run the `ps` command inside the container of a UAI.

    ```console
    sh-4.4# ps -afe
    ```

    Example output:

    ```text
    UID          PID    PPID  C STIME TTY          TIME CMD
    root           1       0  0 22:56 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
    munge         36       1  0 22:56 ?        00:00:00 /usr/sbin/munged
    root          54       1  0 22:56 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
    vers          55      54  0 22:56 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
    root          90       0  0 22:58 pts/0    00:00:00 /bin/sh
    root          97      90  0 22:58 pts/0    00:00:00 ps -afe
    sh-4.4#
    ```

## Next Topic

[Next Topic: Troubleshoot Common Mistakes when Creating a Custom End-User UAI Image](Troubleshoot_Common_Mistakes_when_Creating_a_Custom_End-User_UAI_Image.md)
