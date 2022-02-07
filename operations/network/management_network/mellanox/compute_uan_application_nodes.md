# Computes/UANs/Application Nodes

If the Computes make it past PXE and go into the PXE shell you can verify DNS and connectivity.

```
iPXE> dhcp
Configuring (net0 98:03:9b:a8:60:88).................. No configuration methods succeeded (http://ipxe.org/040ee186)
Configuring (net1 b4:2e:99:be:1a:37)...... ok
```

```
iPXE> show dns
net1.dhcp/dns:ipv4 = 10.92.100.225
```

```
iPXE> nslookup address api-gw-service-nmn.local
iPXE> echo ${address}
10.92.100.71
```

[Back to Index](./index.md)