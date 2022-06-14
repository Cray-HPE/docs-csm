# Update the `cmn-external-dns` value post-installation

By default, the `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-udp` services both share the same Customer Management Network \(CMN\) external IP as defined by the `cmn-external-dns` value.
This value is specified during the `csi config init` input.

It must be in the static range reserved in MetalLB's `cmn-static-pool` subnet. Currently, this is the only CMN IP address that must be known external to the system so IT DNS can delegate the `system-name.site-domain` zone to `services/cray-dns-powerdns` deployment.

Changing it after install is relatively straightforward, and only requires the external IP address for `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-udp` services to be changed. This
procedure will update the IP addresses that DNS queries.

## Prerequisites

The system is installed.

## Procedure

1. Find the external IP address for the `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-tcp` services.

    ```bash
    ncn-m001# kubectl -n services get svc | grep cray-dns-powerdns-cmn-
    ```

    Example output:

    ```console
    cray-dns-powerdns-cmn-tcp                     LoadBalancer   10.25.211.48    10.102.14.113   53:31111/TCP                 2d2h
    cray-dns-powerdns-cmn-udp                     LoadBalancer   10.25.156.88    10.102.14.113   53:32674/UDP                 2d2h
    ```

2. Edit the services and change `spec.loadBalancerIP` to the desired CMN IP address.

    1. Edit the `cray-dns-powerdns-cmn-tcp` service.

        ```bash
        ncn-m001# kubectl -n services edit svc cray-dns-powerdns-cmn-tcp
        ```

    2. Edit the `cray-dns-powerdns-cmn-udp` service.

        ```bash
        ncn-m001# kubectl -n services edit svc cray-dns-powerdns-cmn-udp
        ```
