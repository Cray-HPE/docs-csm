# Manage Node Consoles

The cray-conman service determines which nodes it should monitor by checking with the Hardware State
Manager (HSM) service. It does this once when it starts. If HSM has not discovered some nodes when
cray-conman starts, then HSM is unaware of them and so is cray-conman.

Verify that all nodes are being monitored for console logging and reinitialize `cray-conman` if needed.

Refer to "About the ConMan Containerized Service" in the _HPE Cray EX System Administration Guide S-8001_
for more information about these topics.

   * Access Compute Node Logs Using conman
   * Access Console Log Data Via the System Monitoring Framework (SMF)
   * Log in to a Node Using ConMan
   * Establish a Serial Connection to NCNs
   * Troubleshoot ConMan Blocking Access to a Node BMC
   * Troubleshoot ConMan Failing to Recognize New or Removed Nodes


## Procedure

This procedure can be run from any member of the Kubernetes cluster to verify node consoles are being managed
by cray-conman and reinitialize cray-conman to add new nodes.

1. Identify the `cray-conman` pod:

   ```bash
   ncn# kubectl get pods -n services | grep "^cray-conman-"
   ```

   Expected output looks similar to the following:

   ```
   cray-conman-b69748645-qtfxj                                     3/3     Running           0          16m
   ```

1. Set the `PODNAME` variable accordingly:

   ```bash
   ncn# export PODNAME=cray-conman-b69748645-qtfxj
   ```

1. Log into the `cray-conman` container in this pod:

   ```bash
   ncn# kubectl exec -n services -it $PODNAME -c cray-conman -- bash
   cray-conman#
   ```

1. Check the existing list of nodes being monitored.

   ```bash
   cray-conman# conman -q
   ```

   Output looks similar to the following:

   ```
   x9000c0s1b0n0
   x9000c0s20b0n0
   x9000c0s22b0n0
   x9000c0s24b0n0
   x9000c0s27b1n0
   x9000c0s27b2n0
   x9000c0s27b3n0
   ```

1. If any compute nodes or UANs are not included in this list, the
conman process can be re-initialized by killing the conmand process.

   1. Identify the command process

      ```bash
      cray-conman# ps -ax | grep conmand | grep -v grep
      ```

      Output will look similar to:

      ```
      13 ?        Sl     0:45 conmand -F -v -c /etc/conman.conf
      ```

   1. Set CONPID to the process ID from the previous command output:

      ```bash
      cray-conman# export CONPID=13
      ```

   1. Kill the process:

      ```bash
      cray-conman# kill $CONPID
      ```

   This will regenerate the conman configuration file and restart the conmand process.

1. Repeat the previous steps to verify that cray-conman is now managing all nodes that are included in HSM.

