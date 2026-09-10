# Border Gateway Protocol (BGP) Basics

"The primary function of a Border Gateway Protocol (BGP) speaking system is to exchange
network reachability information with other BGP systems. This network reachability
information includes information on the list of Autonomous Systems (ASes) that reachability
information traverses. This information is sufficient for constructing a graph of AS
connectivity for this reachability, from which routing loops may be pruned and, at the AS
level, some policy decisions may be enforced." – RFC `4271A`

BGP is configurable to run in either internal (iBGP) or external (eBGP) mode.

1. (`switch(config)#`) Enable BGP.

    ```console
    protocol bgp
    ```

1. (`switch(config)#`) Configure a BGP instance.

    ```console
    router bgp 100
    ```

1. (`switch (config interface vlan 10)#`) Apply IP address to the VLAN interface on router 1.

    ```console
    ip address 10.10.10.1 /24
    ```

1. (`switch (config interface vlan 10)#`) Apply IP address to the VLAN interface on router 2.

    ```console
    ip address 10.10.10.2 /24
    ```

1. (`switch(config router bgp 100)#`) On BGP router 1:

    ```console
    neighbor 10.10.10.2 remote-as 100
    ```

1. (`switch(config router bgp 100)#`) On BGP router 2:

    ```console
    neighbor 10.10.10.1 remote-as 100
    ```

## Show commands to validate functionality

(`switch#`)

```console
show ip bgp summary
```

## Expected results

* Administrators can configure BGP on the switch.
* Administrators can create the network statements and the routes are in the routing table.
* Administrators can configure a BGP neighbor that uses an MD5 encrypted password.
* Administrators can validate the BGP relationship is established and that the network statement is advertised to the peer.
* Soft reconfiguration is enabled.

[Back to Index](../README.md)
