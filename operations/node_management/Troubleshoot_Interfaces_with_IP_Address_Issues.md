# Troubleshoot Interfaces with IP Address Issues

Correct NCNs that are failing to assigning a static IP address or detect a duplicate IP address.

The Wicked network manager tool will fail to bring an interface up if its assigned IP address already exists in the respective LAN.
This can be detected by checking for signs of duplicate IP address messages in the log.

## Prerequisites

An NCN has an interface that is failing to assign a static IP address or that has a duplicate IP address.

## Procedure

Use one of the following options to correct NCNs that are failing to assigning a static IP address or to detect a duplicate IP address:

- Check the logs in `/var/log/` for reports of duplicate IP addresses.

    This also will show which MAC address is being used for the IP address.

    ```bash
    ncn# grep duplicate /var/log/*
    ```

    Example output:

    ```text
    warn:2020-08-04T19:22:02.434775+00:00 ncn-w001 wickedd[2188]: bond0: IPv4 duplicate address 10.1.1.1 detected (in use by 00:30:48:bb:e8:d2)!
    ```

- Add an IP address that is not found or commonly assigned on the respective network.

    1. Edit the `/etc/sysconfig/network/ifcfg-FILENAME` file.

    1. Reload the interface.

        Use the following command to safely reload the interface:

        ```bash
        ncn# wicked ifreload INTERFACE_NAME
        ```

        If that does not work, attempt to forcefully add it:

        ```bash
        ncn# systemctl restart wickedd-nanny
        ```

- Add the duplicate IP address with the `ip` command.

    1. Add the duplicate IP address.

        The command below will bypass Wicked and will ignore the system preference:

        ```bash
        ncn# ip a a IP_ADDRESS/MASK dev INTERFACE_NAME
        ```

        For example:

        ```bash
        ncn# ip a a 10.1.1.1/16 dev bond0
        ```

    1. View the bond.

        ```bash
        ncn# ip a s bond0
        ```

        Example output:

        ```text
        8: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 9238 qdisc noqueue state UP group default qlen 1000
            link/ether b8:59:9f:c7:11:12 brd ff:ff:ff:ff:ff:ff
            inet 10.1.1.1/16 brd 10.1.255.255 scope global bond0
               valid_lft forever preferred_lft forever
            inet6 fe80::ba59:9fff:fec7:1112/64 scope link
               valid_lft forever preferred_lft forever
        ```

    1. Delete the IP address after the duplicate IP address is removed.

        ```bash
        ncn# ip a d IP_ADDRESS/MASK dev bond0
        ```

        For example:

        ```bash
        ncn# ip a d 10.1.1.1/16 dev bond0
        ```

- \(Not recommended\) Allow the duplicate IP address to exist.

    This is not recommended because it is unstable and can make the work harder to correct down the line.
    The easiest way to deal with the duplicate is by adding another IP address, and then logging into the
    duplicate and nullifying it. This block will disable the safeguard for duplicate IP addresses.

    ```bash
    ncn# sed -i '^CHECK_DUPLICATE_IP=.*/CHECK_DUPLICATE_IP="no"/' /etc/sysconfig/network/config
    ncn# wicked ifup INTERFACE_NAME
    ```

## Notes

Running `wicked ifreload` on a worker node can have the side effect of causing Slurm and UAI pods to lose their `macvlan` attachments.

In this case, restarts of those services (in the Kubernetes `user` namespace) can be performed by executing the following command:

```bash
ncn-mw# kubectl delete po -n user $(kubectl get po -n user | grep -v NAME | awk '\{ print $1 }')
```
