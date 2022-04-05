# Update the cmn-external-dns Value Post-Installation

By default, the `services/cray-externaldns-coredns-tcp` and `services/cray-externaldns-coredns-udp` services both share the same Customer Management Network \(CMN\) external IP as defined by the `cmn-external-dns` value. This value is specified during the `csi config init` input.

It is expected to be in the static range reserved in MetalLB's `cmn-static-pool` subnet. Theoretically, this is the only CMN IP address that must be known external to the system so IT DNS cmn delegate the `system-name.site-domain` zone to `services/cray-externaldns-coredns` deployments.

Changing it after install is relatively straightforward, and only requires the external IP address for `services/cray-externaldns-coredns-tcp` and `services/cray-externaldns-coredns-udp` services to be changed. This procedure will update the IP addresses that DNS queries.

### Prerequisites

The system is installed.

### Procedure

1.  Find the external IP address for the `services/cray-externaldns-coredns-tcp` and `services/cray-externaldns-coredns-udp` services.

    ```bash
    ncn-w001# kubectl -n services get svc | grep cray-externaldns-coredns-
    ```

    Example output:

    ```
    cray-externaldns-coredns-tcp                     LoadBalancer   10.25.211.48    10.102.14.113   53:31111/TCP                 2d2h
    cray-externaldns-coredns-udp                     LoadBalancer   10.25.156.88    10.102.14.113   53:32674/UDP                 2d2h
    ```

2.  Edit the services and change spec.loadBalancerIP to the desired CMN IP address.

    1.  Edit the `cray-externaldns-coredns-tcp` service.

        ```bash
        ncn-w001# kubectl -n services edit svc cray-externaldns-coredns-tcp
        ```

    2.  Edit the `cray-externaldns-coredns-udp` service.

        ```bash
        ncn-w001# kubectl -n services edit svc cray-externaldns-coredns-udp
        ```

