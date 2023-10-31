# Troubleshoot Compute Node Boot Issues Using Kubernetes

A number of Kubernetes commands can be used to debug issues related to the node boot process. All of the traffic bound for the DHCP server, TFTP server, and
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) is sent on the
[Node Management Network (NMN)](../../glossary.md#node-management-network-nmn).

In the current arrangement, all three services are located on a [management non-compute node (NCN)](../../glossary.md#management-nodes).
Thus, traffic must first travel through the NCN to reach these services inside their pods. When attempting to track down missing requests for either DHCP or TFTP,
it is helpful to set up `tcpdump` on the NCN where the pod is resident to ensure that the request got that far.
The `NODE` column in the output of `kubectl get pods -o wide` shows which node the pod is running on.

## Troubleshooting tips

- Check if a Kubernetes pod is running.

    ```bash
    ncn-mw# kubectl get pods -A -o wide | grep pod_name
    ```

    Example command:

    ```bash
    ncn-mw# kubectl get pods -n services -o wide|grep -E "NAME|kea"
    ```

    Example output:

    ```text
    NAME                                 READY   STATUS      RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    cray-dhcp-kea-6b78789fc4-lzmff       3/3     Running     0          5d12h   10.42.0.30    ncn-w002   <none>           <none>
    ```

- Retrieve logs for a specific Kubernetes pod.

    ```bash
    ncn-mw# kubectl logs -n NAMESPACE pod_name
    ```

    Example command:

    ```bash
    ncn-mw# kubectl get pods -n services -o wide|grep -E "NAME|kea"
    ```

    Example output:

    ```text
    NAME                                 READY   STATUS      RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    cray-dhcp-kea-6b78789fc4-lzmff       3/3     Running     0          5d12h   10.42.0.30    ncn-w002   <none>           <none>
    ```

    Example command:

    ```bash
    ncn-mw# kubectl logs -n services DHCP_KEA_POD_ID -c CONTAINER
    ```

    Beginning of example output:

    ```text
    DHCPDISCOVER from a4:bf:01:23:1a:f4 via vlan100
    ICMP Echo reply while lease 10.100.160.199 valid.
    Abandoning IP address 10.100.160.199: pinged before offer
    Reclaiming abandoned lease 10.100.160.195.
    ```

- Gain access to a Kubernetes pod.

    Use the following command to enter a shell inside a container within the pod. Once inside the shell, execute commands as needed.

    ```bash
    ncn-mw# kubectl exec -A -it pod_name /bin/sh
    ```

    Example command for a pod named `cray-dhcp-kea-6b78789fc4-lzmff`:

    ```bash
    ncn-mw# kubectl exec -A -it cray-dhcp-kea-6b78789fc4-lzmff /bin/sh
    ```
