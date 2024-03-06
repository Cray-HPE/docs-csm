# Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol \(DHCP\)

DHCP issues can result in node boot failures. This procedure helps investigate and resolve such issues.

### Prerequisites

- This procedure requires administrative privileges.
- `kubectl` is installed.

### Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

### Procedure

1.  Log in to a non-compute node \(NCN\) as root.

2.  Check that the DHCP service is running.

    ```bash
    kubectl get pods -A | grep kea
    ```

    Example output:

    ```
    services cray-dhcp-kea-554698bb69-r9wwt          3/3 Running   0 13h
    ```

3.  Start a `tcpdump` session on the NCN.

    The following example sends tcpdump data to `stdout`.

    ```bash
    tcpdump
    ```

4.  Obtain the DHCP pod's ID.

    ```bash
    PODID=$(kubectl get pods --no-headers -o wide | grep cray-dhcp | awk '{print $1}')
    ```

5.  Enter the DHCP pod using its ID.

    ```bash
    kubectl exec -it $PODID /bin/sh
    ```

6.  Start a `tcpdump` session from within the DHCP pod.

7.  Open another terminal to perform the following tasks:

    1.  Issue a DHCP discover request from the NCN using nmap.

    2.  Analyze the NCN tcpdump data in order to ensure that the DHCP discover request is visible.

8.  Go back to the original terminal to analyze the DHCP pod's tcpdump data in order to ensure that the DHCP discover request is visible inside the pod.

    **Troubleshooting Information:**

    If the DHCP Discover request is not visible on the NCN, it may be due to a firewall issue. If the DHCP Discover request is not visible inside the pod, double check if the request was issued over the correct interface for the Node Management Network \(NMN\). If it was, it could indicate a firewall issue.

