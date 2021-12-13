
# Rebooting NCNs and PXE Fails

The following are common error messages when PXE fails:

```bash
2021-04-19 23:27:09   PXE-E18: Server response timeout.
2021-02-02 17:06:13   PXE-E99: Unexpected network error.
```

## Procedure

1. Verify the IP helper-address on VLAN 1 on the switches.  

    This is the same configuration as above "Aruba Configuration".

    Verify DHCP packets can be forwarded from the workers to the MTL network (VLAN1)

    * If the worker nodes cannot reach the Metal (MTL) network DHCP will fail
    * ALL **WORKERS** need to be able to reach the MTL network
    * This can normally be achieved by having a default route 

1. Run connectivity tests.

    ```bash
    ncn-w001# ping 10.1.0.1
    PING 10.1.0.1 (10.1.0.1) 56(84) bytes of data.
    64 bytes from 10.1.0.1: icmp_seq=1 ttl=64 time=0.361 ms
    64 bytes from 10.1.0.1: icmp_seq=2 ttl=64 time=0.145 ms
    ```

    If this fails, CAN may be misconfigured, or a route might need to be added to the MTL network.

    ```bash
    ncn-w001# ip route add 10.1.0.0/16 via 10.252.0.1 dev bond0.nmn0
    ```

[Back to Index](index_aruba.md)