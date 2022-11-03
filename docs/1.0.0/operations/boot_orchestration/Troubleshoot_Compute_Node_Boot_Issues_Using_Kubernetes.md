# Troubleshoot Compute Node Boot Issues Using Kubernetes

A number of Kubernetes commands can be used to debug issues related to the node boot process. All of the traffic bound for the DHCP server, TFTP server, and Boot Script Service \(BSS\) is sent on the Node Management Network \(NMN\).

In the current arrangement, all three services are located on a non-compute node \(NCN\). Thus, traffic must first travel through the NCN to reach these services inside their pods. When attempting to track down missing requests for either DHCP or TFTP, it is helpful to set up `tcpdump` on the NCN where the pod is resident to ensure that the request got that far. The `NODE` column in the output of `kubectl get pods -o wide` shows which node the pod is running on.

### Troubleshooting Tips

-   Retrieve logs for a specific Kubernetes pod:

    Syntax:

    ```bash
    ncn-m001# kubectl logs -n NAMESPACE pod_name
    ```

    Example:

    ```bash
    ncn-m001# kubectl get pods -n services -o wide|grep -E "NAME|kea"
    NAME                                 READY   STATUS      RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    cray-dhcp-kea-6b78789fc4-lzmff       3/3     Running     0          5d12h   10.42.0.30    ncn-w002   <none>           <none>


    ncn-m001# kubectl logs -n services DHCP_KEA_POD_ID -c CONTAINER
    DHCPDISCOVER from a4:bf:01:23:1a:f4 via vlan100
    ICMP Echo reply while lease 10.100.160.199 valid.
    Abandoning IP address 10.100.160.199: pinged before offer
    Reclaiming abandoned lease 10.100.160.195.
    ...
    ```

-   Check if a Kubernetes pod is running:

    Syntax:

    ```bash
    ncn-m001# kubectl get pods -A -o wide | grep pod_name
    ```

    Example:

    ```bash
    ncn-m001# kubectl get pods -A -o wide |grep -E "NAME|kea"
    NAMESPACE   NAME                               READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    services    cray-dhcp-kea-6b78789fc4-lzmff     3/3     Running   0          5d12h   10.42.0.30    ncn-w002   <none>           <none>
    ```

-   Gain access to a Kubernetes pod:

    Use the following command to enter a shell inside a container within the pod. Once inside the shell, execute commands as needed.

    ```bash
    ncn-m001# kubectl exec -A -it pod_name /bin/sh
    ```

    For example, if the pod's name is `cray-dhcp-kea-6b78789fc4-lzmff`, execute:

    ```bash
    ncn-m001# kubectl exec -A -it cray-dhcp-kea-6b78789fc4-lzmff /bin/sh
    ```

