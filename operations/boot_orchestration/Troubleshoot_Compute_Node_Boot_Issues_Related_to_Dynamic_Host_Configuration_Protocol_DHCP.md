# Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol \(DHCP\)

DHCP issues can result in node boot failures. This procedure helps investigate and resolve such issues.

## Prerequisites

- This procedure requires administrative privileges.
- `kubectl` is installed.

## Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

## Procedure

1. Log in to a non-compute node \(NCN\) as root.

2. (`ncn-mw#`) Check that the DHCP service is running.

    ```bash
    kubectl get pods -A | grep kea
    ```

    Example output:

    ```text
    services cray-dhcp-kea-7d4c5c9fb5-hs5gg      3/3 Running   0 23h
    services cray-dhcp-kea-7d4c5c9fb5-qtwtn      3/3 Running   0 23h
    services cray-dhcp-kea-7d4c5c9fb5-t4mkw      3/3 Running   0 23h
    services cray-dhcp-kea-helper-28256853-j8h6l 0/2 Completed 0 30m
    services cray-dhcp-kea-helper-28256856-d5cl4 0/2 Completed 0 27m
    services cray-dhcp-kea-helper-28256859-xj8tc 0/2 Completed 0 24m
    services cray-dhcp-kea-helper-28256862-9pmx4 0/2 Completed 0 21m
    services cray-dhcp-kea-helper-28256865-fljjs 0/2 Completed 0 18m
    services cray-dhcp-kea-helper-28256868-9cl9q 0/2 Completed 0 15m
    services cray-dhcp-kea-helper-28256871-sfhgs 0/2 Completed 0 12m
    services cray-dhcp-kea-helper-28256874-7s8n2 0/2 Completed 0 9m30s
    services cray-dhcp-kea-helper-28256877-jxhqt 0/2 Completed 0 6m30s
    services cray-dhcp-kea-helper-28256880-pl48w 0/2 Completed 0 3m29s
    services cray-dhcp-kea-init-24-nbhng         0/2 Completed 0 8d
    services cray-dhcp-kea-postgres-0            3/3 Running   0 24h
    services cray-dhcp-kea-postgres-1            3/3 Running   0 24h
    services cray-dhcp-kea-postgres-2            3/3 Running   0 24h
    ```

3. (`ncn-mw#`) Start a `tcpdump` session on the NCN.

    The following example sends `tcpdump` data to `stdout`.

    ```bash
    tcpdump
    ```

4. (`ncn-mw#`) Obtain the DHCP pod's ID.

    ```bash
    PODID=$(kubectl get pods --no-headers -o wide | grep cray-dhcp | awk '{print $1}')
    ```

5. (`ncn-mw#`) Enter the DHCP pod using its ID.

    ```bash
    kubectl exec -it $PODID /bin/sh
    ```

6. Start a `tcpdump` session from within the DHCP pod.

7. Open another terminal to perform the following tasks:

    1. Issue a DHCP discover request from the NCN using `nmap`.

    2. Analyze the NCN `tcpdump` data in order to ensure that the DHCP discover request is visible.

8. Go back to the original terminal to analyze the DHCP pod's `tcpdump` data in order to ensure that the DHCP discover request is visible inside the pod.

    **Troubleshooting Information:**

    If the DHCP Discover request is not visible on the NCN, it may be due to a firewall issue. If the DHCP
    Discover request is not visible inside the pod, double check if the request was issued over the correct
    interface for the Node Management Network \(NMN\). If it was, it could indicate a firewall issue.
