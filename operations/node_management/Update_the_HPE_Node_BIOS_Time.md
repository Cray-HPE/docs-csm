# Update the HPE Node BIOS Time

Check and set the time for HPE nodes.

If the console log indicates the time between the rest of the system and the node is off by several hours, it prevents the spire-agent from getting a valid certificate, causing the node boot to drop into the dracut emergency shell.

## Procedure

1. Log in to a second terminal session in order to watch the node's console.

    ***Please open this link in a new tab or page*** [Log in to a Node Using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md)

    The first terminal session will be needed to run the commands to boot the node into the BIOS menu.

1. (`ncn#`) In another terminal session set the following environment variables:

    1. The BMC hostname.

        ```bash
        BMC=x3000c0s3b0
        ```

    1. Export the `root` user password of the BMC.

        > NOTE: `read -s` is used to prevent the password from echoing to the screen or
        > being saved in the shell history.

        ```bash
        read -r -s -p "${BMC} root password: " IPMI_PASSWORD
        export IPMI_PASSWORD
        ```

1. (`ncn#`) Boot the node into its BIOS via the serial console.

    When `ipmitool` is used to boot a HPE node into its BIOS menu it will not be available on on the nodes serial console, due to the node booting into a graphical BIOS menu. To access the serial version of the BIOS setup. Perform the `ipmitool` steps
    above to boot the node. Then in conman press `ESC+9` key combination when you see the following messages in the console. This will open a menu you use to enter the BIOS via serial console.

    ```text
    For access via BIOS Serial Console:
    Press 'ESC+9' for System Utilities
    Press 'ESC+0' for Intelligent Provisioning
    Press 'ESC+!' for One-Time Boot Menu
    Press 'ESC+@' for Network Boot
    ```

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power off
    sleep 10
    ipmitool -I lanplus -U root -E -H $BMC chassis bootdev bios
    ipmitool -I lanplus -U root -E -H $BMC chassis power on
    ```

    > (`linux#`) Alternatively, for HPE NCNs you can log in to the BMC's web interface and access the HTML5 console for the node, in order to interact with the graphical BIOS.
    > From the administrator's own machine, create an SSH tunnel (`-L` creates the tunnel; `-N` prevents a shell and stubs the connection):
    >
    > ```bash
    > bmc=x3000c0s3b0 # Change this to be each node in turn.
    > ssh -L 9443:$bmc:443 -N root@eniac-ncn-m001
    > ```
    >
    > Opening a web browser to `https://localhost:9443` will give access to the BMC's web interface.

1. When the node boots, you will be able to use the conman session to see the BIOS menu to check and set the time to current UTC time. The process varies depending on the vendor of the NCN.

    On HPE NCNs the date configuration menu can be found at the following path: `System Configuration -> BIOS/Platform Configuration (RBSU) -> Date and Time`

1. (`ncn#`) After you have verified the correct time, power off the NCN.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power off
    ```
