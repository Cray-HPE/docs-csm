# Configure QoS

Network traffic is processed based on classification and policies that are created and applied to the traffic.

QoS trust is by default disabled.

## Configuration Commands

Create a `dot1p` trust map:

```text
trust dot1p-map dot1p-trust-map
switch(config-tmap-dot1p-map)#
```

Define the set of values to match the class:

```text
qos-group 3 dot1p 0-4
qos-group 5 dot1p 5-7
```

Apply the map on a specific interface or on global level:

```text
trust-map dot1p dot1p-trust-map
trust-map dot1p dot1p-trust-map
```

[Back to Index](../README.md)
