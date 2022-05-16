# Troubleshoot UAS Issues

This section provides examples of some commands that can be used to troubleshoot UAS-related issues.

## Troubleshoot Connection Issues

```bash
packet_write_wait: Connection to 203.0.113.0 port 30841: Broken pipe
```

If an error message related to broken pipes returns, enable `keep-alives` on the client side.
The admin should update the `/etc/ssh/sshd_config` and `/etc/ssh/ssh_config` files to add the following:

```bash
TCPKeepAlive yes
ServerAliveInterval 120
ServerAliveCountMax 720
```

## Invalid Credentials

```bash
ncn-w001 # cray auth login --username USER --password WRONGPASSWORD
```

Example output:

```bash
Usage: cray auth login [OPTIONS]
Try "cray auth login --help" for help.

Error: Invalid Credentials
```

To resolve this issue:

* Log in to Keycloak and verify the user exists.
* Make sure the username and password are correct.

## Retrieve UAS Logs

The system administrator can execute the following commands to retrieve UAS and the remote execution service logs:

```bash
ncn-w001# kubectl logs -n services -c cray-uas-mgr -l "app=cray-uas-mgr"
```

## Ensure that Slurm is Running and Configured Correctly

Check if Slurm is running:

```bash
[user@uai-user-be3a6770-6876c88676-2p2lk ~] $ sinfo
```

The system returns a message similar to the following if Slurm is not running:

```bash
slurm_load_partitions: Unable to contact slurm controller (connect failure)
```

If this error is returned, it is likely that Slurm is not running.
The system administrator can use the following commands to debug the issue:

```bash
ncn-w001# kubectl logs -n user -l app=slurmdb -c slurmdb --tail=-1
ncn-w001# kubectl logs -n user -l app=slurmdbd -c slurmdbd --tail=-1
ncn-w001# kubectl logs -n user -l app=slurmctld -c slurmctld --tail=-1
```

## Troubleshoot Default Images Issues when Using the CLI

If the image name provided while creating a new UAI is not registered for use by the system, the system returns an error message similar to the following:

```bash
ncn-w001# cray uas create --publickey ~/.ssh/id_rsa.pub --imagename fred
Usage: cray uas create [OPTIONS]
Try "cray uas create --help" for help.

Error: Bad Request: Invalid image (fred). Valid images: ['dtr.dev.cray.com:443/cray/cray-uas-sles15sp1:latest']. Default: dtr.dev.cray.com:443/cray/cray-uas-sles15sp1:latest
```

Retry creating the UAI using the list of images and the name of the default image provided in the error message.

## Verify that the User Access Instances \(UAIs\) are Running

The system administrator can use the `kubectl` command to check the status of the UAI.

```bash
ncn-w001# kubectl get pod -n user -l uas=managed -o wide
```

Example output:

```bash
NAME                                    READY   STATUS              RESTARTS   AGE    IP       NODE    NOMINATED NODE   READINESS GATES
uai-user-603d55f1-85d5ddb4b7-zk6nl   0/1     ContainerCreating   0          109s   <none>   sms-2   <none>           <none>
uai-user-d7f8d2e7-6dbdc64d98-7h5t5   0/1     ContainerCreating   0          116s   <none>   sms-2   <none>           <none>
uai-user-f6b72c9f-5dccd879bd-grbjw   0/1     ContainerCreating   0          113s   <none>   sms-2   <none>           <none>
```

If UAS pods are stuck in the `Pending` state, the admin needs to ensure the Kubernetes cluster has nodes available for running UAIs.
Check that nodes are labeled with `uas=True` and are in the `Ready` state.

```bash
ncn-w001# kubectl get nodes -l uas
```

Example output:

```bash
NAME        STATUS   ROLES    AGE   VERSION
ncn-w001   Ready    <none>   11d   v1.20.13
```

If none of the nodes are found or if the nodes listed are marked as `NotReady`, the UAI pods will not be scheduled and will not start.

## Troubleshoot `kubectl` Certificate Issues

While `kubectl` is supported in a UAI, `kubeconfig` file to access a Kubernetes cluster is not provided.
To use `kubectl` to interface with a Kubernetes cluster, the user must supply their own `kubeconfig`.

```bash
[user@uai-user-be3a6770-6876c88676-2p2lk ~]# kubectl get nodes
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Specify the location of the Kubernetes certificate with `KUBECONFIG`.

```bash
[user@uai-user-be3a6770-6876c88676-2p2lk ~]# KUBECONFIG=/tmp/CONFIG kubectl get nodes
```

Example output:

```bash
NAME STATUS ROLES AGE VERSION
ncn-m001 Ready control-plane,master 16d v1.20.13
ncn-m002 Ready control-plane,master 16d v1.20.13
```

Users must specify `KUBECONFIG` with every `kubectl` command or specify the `kubeconfig` file location for the life of the UAI.
To do this, either set the `KUBECONFIG` environment variable or set the `--kubeconfig` flag.

## Troubleshoot X11 Issues

The system may return the following error if the user attempts to use an application that requires an X window \(such as `xeyes`\):

```bash
# ssh user@203.0.113.0 -i ~/.ssh/id_rsa
```

Example output:

```bash
   ______ ____   ___ __  __   __  __ ___     ____
  / ____// __ \ /   |\ \/ /  / / / //   |   /  _/
 / /    / /_/ // /| | \  /  / / / // /| |   / /
/ /___ / _, _// ___ | / /  / /_/ // ___ | _/ /
\____//_/ |_|/_/  |_|/_/   \____//_/  |_|/___/

[user@uai-user-be3a6770-6876c88676-2p2lk ~]$ xeyes
Error: Can't open display:
```

To resolve this issue, pass the `-X` option with the `ssh` command as shown below:

```bash
# ssh UAI_USERNAME@UAI_IP_ADDRESS -i ~/.ssh/id_rsa -X
```

Example output:

```bash
   ______ ____   ___ __  __   __  __ ___     ____
  / ____// __ \ /   |\ \/ /  / / / //   |   /  _/
 / /    / /_/ // /| | \  /  / / / // /| |   / /
/ /___ / _, _// ___ | / /  / /_/ // ___ | _/ /
\____//_/ |_|/_/  |_|/_/   \____//_/  |_|/___/
/usr/bin/xauth:  file /home/users/user/.Xauthority does not exist

[user@uai-user-be3a6770-6876c88676-2p2lk ~]$ echo $DISPLAY
203.0.113.0
```

The warning stating `"Xauthority does not exist"` will disappear with subsequent logins.

## Troubleshoot SSH Host Key Issues

If strict host key checking enabled is enabled on the user's client, the below error may appear when connecting to a UAI over SSH.

```bash
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED
```

This can occur in a few circumstances, but is most likely to occur after the UAI container is restarted. If this occurs, remove the offending `ssh` host key from the local `known_hosts` file and try to connect again.
The error message from `ssh` will contain the correct path to the `known_hosts` file and the line number of the problematic key.

## Delete UAS Objects with `kubectl`

If Kubernetes resources used to create a UAI are not cleaned up during the normal deletion process, resources can be deleted with the following commands.

Delete anything created by the User Access Service \(`uas-mgr`\):

**WARNING:** This command will delete all UAS resources for the entire system, it is not for targeted cleanup of a single UAI.

```bash
ncn-w001# kubectl delete all -n user -l uas=managed
```

Delete all objects associated with a particular UAI:

```bash
ncn-w001# kubectl delete all -n user -l app=UAI-NAME
```

Delete all objects for a single user:

```bash
ncn-w001# kubectl delete all -n user -l user=USERNAME
```

## Hard limits on UAI Creation

Each Kubernetes worker node has limits on how many pods it can run. Nodes are installed by default with a hard limit of 110 pods per node, but the number of pods may be further limited by memory and CPU utilization constraints.
For a standard node the maximum number of UAIs per node is 110; if other pods are co-scheduled on the node, the number will be reduced.

Determine the hard limit on Kubernetes pods with `kubectl describe node` and look for the `Capacity` section.

```bash
# kubectl describe node NODE_NAME -o yaml
```

Example output:

```bash
[...]

capacity:
    cpu: "16"
    ephemeral-storage: 1921298528Ki
    hugepages-1Gi: "0"
    hugepages-2Mi: "0"
    memory: 181009640Ki
    pods: "110"

[...]
```

When UAIs are created, some UAIs might left in the `Pending` state. The Kubernetes scheduler is unable to schedule them to a node, because of CPU, memory, or pod limit constraints.
Use `kubectl` describe pod to check why the pod is `Pending`. For example, this pod is `Pending` because the node has reached the hard limit of 110 pods.

```bash
# kubectl describe pod UAI-POD
```

Example output:

```bash
Warning  Failed
Scheduling  21s (x20 over 4m31s)  default-scheduler  0/4 nodes are available: 1 Insufficient pods, 3 node(s) didn't match node selector.
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot UAS by Viewing Log Output](Troubleshoot_UAS_by_Viewing_Log_Output.md)
