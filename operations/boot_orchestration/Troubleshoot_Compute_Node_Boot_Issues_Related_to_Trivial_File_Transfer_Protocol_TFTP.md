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

1. (`ncn-m001#`) Identify the TFTP pods and their worker nodes.

    ```bash
    kubectl -n services get pod -l app.kubernetes.io/name=cray-tftp -o wide
    ```

    Example output:

    ```text
    NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    cray-tftp-58d8648dfd-dx5xk   1/1     Running   0          5d16h   10.32.5.139   ncn-w004   <none>           <none>
    cray-tftp-58d8648dfd-lgtn9   1/1     Running   0          6d      10.32.2.30    ncn-w001   <none>           <none>
    cray-tftp-58d8648dfd-wks5l   1/1     Running   0          5d23h   10.32.4.136   ncn-w003   <none>           <none>
    ```

    Choose one of the pods and note both its name and the worker node it's running on. In this example, we'll use pod `cray-tftp-58d8648dfd-wks5l` running on `ncn-w003`.

1. (`ncn-m001#`) Copy the `pod-tcpdump.sh` script to the worker node running the TFTP pod.

    Replace `ncn-w003` with the actual worker node from the previous step.

    ```bash
    scp /usr/share/doc/csm/scripts/pod-tcpdump.sh ncn-w003:/tmp/
    ```

1. (`ncn-w#`) SSH to the worker node.

    Replace `ncn-w003` with the actual worker node.

    ```bash
    ssh ncn-w003
    ```

1. (`ncn-w#`) Run `tcpdump` on the TFTP pod to capture TFTP traffic (UDP port 69).

    Replace `cray-tftp-58d8648dfd-wks5l` with the actual pod name from step 2.

    ```bash
    /tmp/pod-tcpdump.sh -n services -p cray-tftp-58d8648dfd-wks5l -f "udp port 69"
    ```

    This will display live packet capture. Press `Ctrl+C` to stop the capture when done.

    Alternatively, to capture to a file for later analysis:

    ```bash
    /tmp/pod-tcpdump.sh -n services -p cray-tftp-58d8648dfd-wks5l -f "udp port 69" -w /tmp/tftp-capture.pcap -c 1000
    ```

1. Open another terminal to perform the following tasks:

    1. Use a TFTP client to issue a TFTP request from either an NCN or a laptop.

    1. Analyze the `tcpdump` data to ensure that the TFTP request is visible.

    Example TFTP request from a client:

    ```bash
    tftp <TFTP_SERVER_IP>
    tftp> get <filename>
    tftp> quit
    ```

1. Review the captured traffic.

    Look for TFTP read requests (RRQ) and responses. Successful TFTP transfers will show:
    - RRQ (Read Request) from client
    - DATA packets from server
    - ACK packets from client

    If a pcap file was created, it can be analyzed with:

    ```bash
    tcpdump -r /tmp/tftp-capture.pcap -nn -vv
    ```

## Troubleshooting

If the TFTP request is not visible in the packet capture, consider the following:

- **Firewall issues**: The TFTP traffic (UDP port 69) may be blocked by firewall rules on the NCN or network.
- **Wrong interface**: Ensure the TFTP request was issued over the correct interface for the Node Management Network (NMN).
- **Network routing**: Verify that routing is configured correctly between the client and the TFTP server.
- **Pod network issues**: If traffic reaches the worker node but not the pod, there may be issues with the pod network or Kubernetes networking components.

### Additional troubleshooting with the script

Capture all traffic on the pod's network interface (not just TFTP):

```bash
/tmp/pod-tcpdump.sh -n services -p <POD_NAME> -c 500
```

Capture on a different interface (if the pod has multiple interfaces):

```bash
/tmp/pod-tcpdump.sh -n services -p <POD_NAME> -i net1 -f "udp port 69"
```

For detailed packet inspection with full headers and payload:

```bash
/tmp/pod-tcpdump.sh -n services -p <POD_NAME> -t "-i eth0 -en -vvv -X udp port 69" -c 100
```

Replace `<POD_NAME>` with the actual TFTP pod name (e.g., `cray-tftp-58d8648dfd-wks5l`).
