---
category: numbered
---

# Log in to a User's UAI to Troubleshoot Issues

Displays when you mouse over the topic on the Cray Portal.

This procedure requires root access.

-   **LEVEL**

    **Level 3 PaaS**

-   **ROLE**

    System administrator

-   **OBJECTIVE**

    Log in to a user's User Access Instance \(UAI\) to help the user troubleshoot issues.

-   **LIMITATIONS**

    This procedure does not work if the pod is in either "Error" or "Terminating" states.

-   **NEW IN THIS RELEASE**

    This entire procedure is new for this release.


1.  Log in to the first NCN acting as a Kubernetes master node \(ncn-m001\) as `root`.

2.  Find and record the name of the UAI.

    ```screen
    ncn-m001# cray uas uais list
    [[results]]
    username = "user"
    uai_host = "ncn-m001'
    uai_status = "Running: Ready"
    uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id\_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "14m"
    uai_name = "**uai-uastest-0abd2928**"
    ```

3.  Find the full name of the pod that represents this user's UAI.

    ```screen
    ncn-m001# kubectl get pods -n user -l app=USERS\_UAI\_NAME
    
    NAME                                 READY   STATUS    RESTARTS   AGE
    **
    uai-uastest-0abd2928-575fcf8cf7-ftgxw**   1/1     Running   0          89m
    ```

    Note the full name of the pod \(in this example: `uai-root-0abd2928-575fcf8cf7-ftgxw`\).

4.  Connect to the pod.

    ```screen
    ncn-m001# kubectl exec -n user -it FULL\_POD\_NAME /bin/bash
    ```

    As root in the user's UAI, an administrator will have the user's UID, GID, and full access to their file system mounts.


Assist the user with issues, and use exit to exit the UAI.

**Parent topic:**[Troubleshoot UAS Issues](Troubleshoot_UAS_Issues.md)

