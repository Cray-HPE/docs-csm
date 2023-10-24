# Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol \(TFTP\)

TFTP issues can result in node boot failures. Use this procedure to investigate and resolve such issues.

## Prerequisites

This procedure requires administrative privileges.

## Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

## Procedure

1. (`ncn-mw#`) Check that the TFTP service is running.

    ```bash
     kubectl get pods -n services -o wide | grep cray-tftp
    ```

1. Start a `tcpdump` session on the NCN.

1. (`ncn-mw#`) Obtain the TFTP pod's ID.

    ```bash
    PODID=$(kubectl get pods -n services --no-headers -o wide | grep cray-tftp | awk '{print $1}')
    echo $PODID
    ```

1. (`ncn-mw#`) Enter the TFTP pod using the pod ID.

    Double check that `PODID` contains only one ID. If there are multiple TFTP pods listed, just choose one as the ID.

    ```bash
    kubectl exec -n services -it $PODID /bin/sh
    ```

1. Start a `tcpdump` session from within the TFTP pod.

1. Open another terminal to perform the following tasks:

    1. Use a TFTP client to issue a TFTP request from either the NCN or a laptop.

    1. Analyze the NCN `tcpdump` data to ensure that the TFTP discover request is visible.

1. Go back to the original terminal to analyze the TFTP pod's `tcpdump` data in order to ensure that the TFTP request is visible inside the pod.

## Troubleshooting

If the TFTP request is not visible on the NCN, it may be caused by a firewall issue. If the TFTP request is not visible inside the pod,
then double check that the request was issued over the correct interface for the Node Management Network \(NMN\). If it was, then the
underlying issue could be related to the firewall.
