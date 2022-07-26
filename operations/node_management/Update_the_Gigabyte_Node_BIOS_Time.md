# Update the Gigabyte Node BIOS Time

Check and set the time for Gigabyte compute nodes.

If the console log indicates the time between the rest of the system and the compute nodes is off by several hours, then it prevents the `spire-agent` from getting a valid certificate,
which causes the node boot to drop into the `dracut` emergency shell.

## Procedure

1. Retrieve the `cray-console-operator` pod ID.

    ```bash
    ncn-mw# CONPOD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}'); echo ${CONPOD}
    ```

    Example output:

    ```text
    cray-console-operator-79bf95964-qpcpp
    ```

The following steps should be repeated for each Gigabyte node which needs to have its BIOS time reset.

1. Set the `XNAME` variable to the component name (xname) of the node whose console you wish to open.

    ```bash
    ncn-mw# XNAME=x1001c0s24b1n0
    ```

1. Find the `cray-console-node` pod that is connected to that node.

    ```bash
    ncn-mw# NODEPOD=$(kubectl -n services exec "${CONPOD}" -c cray-console-operator -- \
                        sh -c "/app/get-node ${XNAME}" | jq .podname | sed 's/"//g') ; echo ${NODEPOD}
    ```

    Example output:

    ```text
    cray-console-node-1
    ```

1. Connect to the node's console using ConMan on the identified `cray-console-node` pod.

    ```bash
    ncn-mw# kubectl exec -it -n services "${NODEPOD}" -- conman -j "${XNAME}"
    ```

    Example output:

    ```text
    <ConMan> Connection to console [x1001c0s24b1] opened.
    ```

1. In another terminal, boot the node to BIOS.

    1. Set the `BMC` variable to the component name (xname) of the BMC for the node.

        This value will be different for each node.

        ```bash
        ncn# BMC=x1001c0s24b1
        ```

    1. Boot the node to BIOS.

        > `read -s` is used to prevent the password from being written to the screen or the shell history.

        ```bash
        ncn# USERNAME=root
        ncn# read -r -s -p "$BMC ${USERNAME} password: " IPMI_PASSWORD
        ncn# export IPMI_PASSWORD
        ncn# ipmitool -I lanplus -U "${USERNAME}" -E -H "${BMC}" chassis bootdev bios
        ncn# ipmitool -I lanplus -U "${USERNAME}" -E -H "${BMC}" chassis power off
        ncn# sleep 10
        ncn# ipmitool -I lanplus -U "${USERNAME}" -E -H "${BMC}" chassis power on
        ```

1. Update the `System Date` field to match the time on the system.

   Use the terminal which is watching the console for this step.
   As the node powers on, it will complete POST (Power On Self Test) and then display the BIOS menu.

   The `System Date` field is located under the `Main` tab in the navigation bar.

   ![Compute Node Setup Menu](../../img/operations/CN_Setup_Menu.png)

1. Enter the `F10` key followed by the `Enter` key to save the BIOS time.

1. Exit the connection to the console by entering `&.`.

1. Repeat the above steps for other nodes which need their BIOS time reset.
