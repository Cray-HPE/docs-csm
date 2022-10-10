# Using the CMN for the CHN BGP control plane

## Summary

In a typical CHN configuration BGP peering is done over the CHN.  This means that the BGP control plane packets are sent over the High speed network on the CHN.  In some cases, admins may want to use the CMN as the BGP control plane.

The following example shows how to move the BGP control plane from the CHN to the CMN.  Currently, the MetalLB configuration will not persist through CSM upgrades.

### Edge Router Configuration

CANU `1.6.21` can generate this confiuration for Arista Edge Routers.

CANU install and docs can be found [here](https://github.com/Cray-HPE/canu)

Example CLI to generate switch configs for the entire management network.

```bash
canu generate network config --csm 1.3 --ccj ./ccj.json --sls-file ./sls_input_file.json --folder ./cmn_control_plane --bgp-control-plane cmn
```

- Remove existing BGP configuration and route-maps related to BI-CAN.
- Loopback addresses of the edge switches can be changed if needed.  This will require updating the BGP configuration.
- Once you generate the configuration you can simply copy/paste the configuration onto the Edge Switches.
- Verify BGP sessions are established

```code
sw-edge-001(config-router-bgp)#show ip bgp summary
BGP summary information for VRF default
Router identifier 10.2.1.194, local AS number 65533
Neighbor Status Codes: m - Under maintenance
  Neighbor         V  AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  10.2.1.195       4  65533             41        42    0    0 00:00:12 Estab   0      0
  10.103.11.22     4  65530             49        33    0    0 00:00:31 Estab   17     3
  10.103.11.23     4  65530             51        34    0    0 00:00:31 Estab   19     3
  10.103.11.24     4  65530             49        34    0    0 00:00:31 Estab   17     3
```

example configuration of `sw-edge-001` generated from CANU using the `--bgp-control-plane cmn` feature flag.

```code
route-map ncn-w001-CHN permit 10
   match ip address prefix-list HSN
   set ip next-hop 10.103.11.199
!
route-map ncn-w002-CHN permit 10
   match ip address prefix-list HSN
   set ip next-hop 10.103.11.198
!
route-map ncn-w003-CHN permit 10
   match ip address prefix-list HSN
   set ip next-hop 10.103.11.197
!
router bgp 65533
   router-id 10.2.1.194
   timers bgp 1 3
   distance bgp 20 200 200
   maximum-paths 32
   neighbor 10.2.1.194 maximum-routes 12000
   neighbor 10.2.1.195 remote-as 65533
   neighbor 10.2.1.195 next-hop-self
   neighbor 10.2.1.195 update-source Loopback0
   neighbor 10.2.1.195 maximum-routes 12000
   neighbor 10.103.11.22 remote-as 65530
   neighbor 10.103.11.22 passive
   neighbor 10.103.11.22 update-source Loopback0
   neighbor 10.103.11.22 ebgp-multihop 5
   neighbor 10.103.11.22 route-map ncn-w003-CHN in
   neighbor 10.103.11.22 maximum-routes 12000
   neighbor 10.103.11.23 remote-as 65530
   neighbor 10.103.11.23 passive
   neighbor 10.103.11.23 update-source Loopback0
   neighbor 10.103.11.23 ebgp-multihop 5
   neighbor 10.103.11.23 route-map ncn-w002-CHN in
   neighbor 10.103.11.23 maximum-routes 12000
   neighbor 10.103.11.24 remote-as 65530
   neighbor 10.103.11.24 passive
   neighbor 10.103.11.24 update-source Loopback0
   neighbor 10.103.11.24 ebgp-multihop 5
   neighbor 10.103.11.24 route-map ncn-w001-CHN in
   neighbor 10.103.11.24 maximum-routes 12000
   !
   address-family ipv4
      neighbor 10.2.1.194 activate
      neighbor 10.103.11.22 activate
      neighbor 10.103.11.23 activate
      neighbor 10.103.11.24 activate
```

### Configure MetalLB

1. (`ncn-m001#`) Backup running system MetalLB `ConfigMap` data.

   ```bash
    kubectl get cm -n metallb-system metallb -o yaml | egrep -v 'creationTimestamp:|resourceVersion:|uid:' | tee metallb.yaml > metallb_bak.yaml
   ```

    - The output of the file should be similar to the following.

    ```bash
    apiVersion: v1
    data:
    config: |
        peers:
        - peer-address: 10.252.0.2
            peer-asn: 65533
            my-asn: 65533
        - peer-address: 10.252.0.3
            peer-asn: 65533
            my-asn: 65533
        - peer-address: 10.103.11.2
            peer-asn: 65533
            my-asn: 65532
        - peer-address: 10.103.11.3
            peer-asn: 65533
            my-asn: 65532
        - peer-address: 10.103.11.194
            peer-asn: 65533
            my-asn: 65530
        - peer-address: 10.103.11.195
            peer-asn: 65533
            my-asn: 65530
        address-pools:
        - name: node-management
            protocol: bgp
            addresses:
            - 10.92.100.0/24
        - name: customer-high-speed
            protocol: bgp
            addresses:
            - 10.103.11.224/28
        - name: customer-management-static
            protocol: bgp
            addresses:
            - 10.103.11.60/30
        - name: customer-management
            protocol: bgp
            addresses:
            - 10.103.11.64/26
        - name: hardware-management
            protocol: bgp
            addresses:
            - 10.94.100.0/24
        - name: node-management
            protocol: bgp
            addresses:
            - 10.92.100.0/24
    ```

1. Edit the CHN peer addresses.

    - The peer addresses should be changed to a loopback address from each edge switch.
      - These addresses are generated from CANU, however they can be changed depending on the site requirements.
    - This address needs to be reachable from the CMN network on the Worker NCNs.

    before

    ```bash
        - peer-address: 10.103.11.194
            peer-asn: 65533
            my-asn: 65530
        - peer-address: 10.103.11.195
            peer-asn: 65533
            my-asn: 65530
    ```

    after

    ```bash
        - peer-address: 10.2.1.194
            peer-asn: 65533
            my-asn: 65530
        - peer-address: 10.2.1.195
            peer-asn: 65533
            my-asn: 65530
    ```

1. (`ncn-m001#`) Apply MetalLB configuration map.

   ```bash
    kubectl apply -f metallb.yaml 
   ```
