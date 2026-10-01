# Verify Computes/UANs/Application Nodes

(`iPXE#`) If the computes nodes make it past PXE and go into the PXE shell, verify DNS and connectivity.

```console
dhcp
```

Example output:

```text
Configuring (net0 98:03:9b:a8:60:88).................. No configuration methods succeeded (http://ipxe.org/040ee186)
Configuring (net1 b4:2e:99:be:1a:37)...... ok
```

## Procedure

1. (`iPXE`) Verify DNS:

    ```console
    show dns
    ```

    Example output:

    ```text
    net1.dhcp/dns:ipv4 = 10.92.100.225
    ```

1. (`iPXE`) Verify connectivity:

    ```console
    nslookup address api-gw-service-nmn.local
    echo ${address}
    ```

    Example output:

    ```text
    10.92.100.71
    ```

[Back to Index](../README.md)
