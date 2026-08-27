# Computes/UANs/Application Nodes

If a node makes it past PXE and goes into the PXE shell, then it is possible to verify DNS and connectivity.

```console
iPXE> dhcp
Configuring (net0 98:03:9b:a8:60:88).................. No configuration methods succeeded (http://ipxe.org/040ee186)
Configuring (net1 b4:2e:99:be:1a:37)...... ok
```

```console
iPXE> show dns
net1.dhcp/dns:ipv4 = 10.92.100.225
```

```console
iPXE> nslookup address api-gw-service-nmn.local
iPXE> echo ${address}
10.92.100.71
```

[Back to Index](../README.md)
