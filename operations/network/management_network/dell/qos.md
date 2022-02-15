# QoS

Network traffic is processed based on classification and policies that are created and applied to the traffic.

QoS trust is by default disabled.

Create a dot1p trust map

```
switch(config)# trust dot1p-map dot1p-trust-map
switch(config-tmap-dot1p-map)#
```

Define the set of values to match the class

```
switch(config-tmap-dot1p-map)# qos-group 3 dot1p 0-4
switch(config-tmap-dot1p-map)# qos-group 5 dot1p 5-7
```

Apply the map on a specific interface or on global level

```
switch(conf-if-eth1/1/1)# trust-map dot1p dot1p-trust-map
switch(config-sys-qos)# trust-map dot1p dot1p-trust-map
```

[Back to Index](index.md)
