# Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol \(TFTP\)

TFTP issues can result in node boot failures. Use this procedure to investigate and resolve such issues.

### Prerequisites

This procedure requires administrative privileges.

### Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.


1.  Log onto a non-compute node \(NCN\) as root.

2.  Check that the TFTP service is running.

    ```bash
    ncn-m001#  kubectl get pods -n services -o wide | grep cray-tftp
    ```

3.  Start a tcpdump session on the NCN.

4.  Obtain the TFTP pod's ID.

    ```bash
    ncn-m001# PODID=$(kubectl get pods -n services --no-headers -o wide | grep cray-tftp | awk '{print $1}')
    ncn-m001# echo $PODID
    ```

5.  Enter the TFTP pod using the pod ID.

    Double check that `PODID` contains only one ID. If there are multiple TFTP pods listed, just choose one as the ID.

    ```bash
    ncn-m001# kubectl exec -n services -it $PODID /bin/sh
    ```

6.  Start a tcpdump session from within the TFTP pod.

7.  Open another terminal to perform the following tasks:

    1.  Use a TFTP client to issue a TFTP request from either the NCN or a laptop.

    2.  Analyze the NCN tcpdump data to ensure that the TFTP discover request is visible.

8.  Go back to the original terminal to analyze the TFTP pod's tcpdump data in order to ensure that the TFTP request is visible inside the pod.

    **Troubleshooting Information:**

    If the TFTP request is not visible on the NCN, it may be due to a firewall issue. If the TFTP request is not visible inside the pod, double check that the request was issued over the correct interface for the Node Management Network \(NMN\). If it was, the underlying issue could be related to the firewall.

