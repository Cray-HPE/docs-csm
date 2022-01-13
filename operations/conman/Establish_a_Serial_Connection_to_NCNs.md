## Establish a Serial Connection to NCNs

The ConMan pod can be used to establish a serial console connection with each non-compute node (NCN) in the system. In the scenario of a power down or reboot of an NCN worker, it will be important to check which NCN the conman pod is running on, and to ensure that it is NOT running on the NCN worker that will be impacted. If the NCN worker (where ConMan is running) is powered down or rebooted, the ConMan pod will be unavailable until the node comes back up or until the ConMan pod has terminated on the downed NCN worker node and come up on another NCN worker node.

### Prerequisites

The user performing this procedure needs to have access permission to the cray-console-operator and cray-console-node pods.

### Procedure

1. Check which cray-console-node pod the NCN is connected through using the xname of the NCN.

    If doing an NCN reboot, the xname can be gathered from the /opt/cray/platform-utils/ncnGetXnames.sh script.

    ```
    ncn-m001# CONPOD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}')
    ncn-m001# NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c '/app/get-node XNAME' \
    | jq .podname | sed 's/"//g')
    ncn-m001# echo $NODEPOD
    ```

2. Check which NCN this pod is running on.

    ```
    ncn-m001# kubectl -n services get pods -o wide -A | grep $NODEPOD
    ```

3. **Optional:** Move the cray-console-node pod.

    The pod can be proactively moved to a different worker if a power or reboot operation is going to be performed on the node where the pod is running.

    1. Prevent new pods from being scheduled on the NCN worker node currently running ConMan.

        Replace the NCN_HOSTNAME value before running the command. An example NCN_HOSTNAME is ncn-w002.

        ```
        ncn-m001# kubectl cordon NCN_HOSTNAME
        ```

    2. Delete the pod.

        When the pod comes back up, it will be on a different NCN worker node.

        ```
        ncn-m001# kubectl -n services delete $NODEPOD
        ```

    3. Wait for pod to terminate and come back up again.

        It may take several minutes even after the pod is running for the console connections to be re-established. In the mean time, there is a small chance that the console connection will be moved to a different cray-console-node pod.

    4. Check which cray-console-node pod the NCN is connected to.

        ```
        ncn-m001# NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c '/app/get-node XNAME' \
        | jq .podname | sed 's/"//g')
        ncn-m001# echo $NODEPOD
        ```

        If the result is 'cray-console-node-' the console connection has not been re-established so wait and try again until a valid pod name is returned.


4. Establish a serial console session (from ncn-m001) with the desired NCN.

    Exec into the correct cray-console-node pod.

    ```
    ncn-m001# kubectl -n services exec -it $NODEPOD -- /bin/bash
    ```


5. Establish a console session for the desired NCN.

    ```
    cray-console-node-1:/ # conman -j XNAME
    <ConMan> Connection to console [XNAME] opened.

    nid000009 login:
    ```

    The console session log files for each NCN is located in the cray-console-operator and cray-console-node pods in a shared volume at the /var/log/conman/ directory in a file named 'console.<xname>'.

    **IMPORTANT:** If the cray-console-node pod the user is connected through is running on the NCN that the console session is connected to and a reboot is initiated, expect the connection to terminate and there to be a gap in the console log file until the console connection is reestablished through a different cray-console-node pod or for the existing pod to be restarted on a different NCN. If the cray-console-node pod was running on a different NCN or was moved prior to the reboot, the console log and session should persist through the operation.

6.  Exit the connection to the console with the `&.` command.