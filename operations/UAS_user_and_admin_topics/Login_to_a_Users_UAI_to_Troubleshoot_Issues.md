# Log in to a User's UAI to Troubleshoot Issues

Log in to a user's User Access Instance \(UAI\) to help the user troubleshoot issues.

### Prerequisites

This procedure requires root access.

### Limitations

This procedure does not work if the pod is in either "Error" or "Terminating" states.

### Procedure

1.  Log in to the first NCN acting as a Kubernetes master node \(ncn-m001\) as `root`.

2.  Find and record the name of the UAI.

    ```bash
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

    ```bash
    ncn-m001# kubectl get pods -n user -l app=USERS_UAI_NAME

    NAME                                 READY   STATUS    RESTARTS   AGE
    **
    uai-uastest-0abd2928-575fcf8cf7-ftgxw**   1/1     Running   0          89m
    ```

    Note the full name of the pod \(in this example: `uai-root-0abd2928-575fcf8cf7-ftgxw`\).

4.  Connect to the pod.

    ```bash
    ncn-m001# kubectl exec -n user -it FULL_POD_NAME /bin/bash
    ```

    As root in the user's UAI, an administrator will have the user's UID, GID, and full access to their file system mounts.


Assist the user with issues, and use `exit` to exit the UAI.
