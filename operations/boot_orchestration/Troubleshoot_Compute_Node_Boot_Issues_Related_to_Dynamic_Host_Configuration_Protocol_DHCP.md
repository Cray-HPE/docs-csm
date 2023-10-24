# Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol \(DHCP\)

DHCP issues can result in node boot failures. This procedure helps investigate and resolve such issues.

## Prerequisites

- This procedure requires administrative privileges.

## Procedure

1. Check that the DHCP service is running.

    ```bash
    ncn-m001# kubectl get pods -A | grep kea
    ```

    Example output:

    ```text
    services cray-dhcp-kea-554698bb69-r9wwt          3/3 Running   0 13h
    services cray-dhcp-kea-postgres-0                2/2 Running   0 10d
    services cray-dhcp-kea-postgres-1                2/2 Running   0 3d18h
    services cray-dhcp-kea-postgres-2                2/2 Running   0 10d
    services cray-dhcp-kea-wait-for-postgres-3-7gqvg 0/3 Completed 0 10d
    ```

1. Start a `tcpdump` session on the NCN.

    The following example sends `tcpdump` data to `stdout`.

    ```bash
    cray-dhcp# tcpdump
    ```

1. Obtain the DHCP pod's ID.

    ```bash
    ncn-m001# PODID=$(kubectl get pods --no-headers -o wide | grep cray-dhcp | awk '{print $1}')
    ```

1. Enter the DHCP pod using its ID.

    ```bash
    ncn-m001# kubectl exec -it $PODID /bin/sh
    ```

1. Start a `tcpdump` session from within the DHCP pod.

1. Open another terminal to perform the following tasks:

    1. Issue a DHCP discover request from the NCN using `nmap`.

    1. Analyze the NCN `tcpdump` data in order to ensure that the DHCP discover request is visible.

1. Go back to the original terminal to analyze the DHCP pod's `tcpdump` data in order to ensure that the DHCP discover request is visible inside the pod.

## Troubleshooting

If the DHCP discover request is not visible on the NCN, it may be due to a firewall issue. If the DHCP discover request is not visible inside the pod,
double check if the request was issued over the correct interface for the Node Management Network \(NMN\). If it was, it could indicate a firewall issue.
