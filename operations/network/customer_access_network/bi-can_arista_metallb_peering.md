# MetalLB Peering with Arista Edge Router

This is an example configuration of how to connect a pair of Arista switches to MetalLB running inside of Kubernetes.

## Prerequisites

- Pair of Arista switches already connected to the high-speed network.
- Updated System Layout Service (SLS) file that has the `CHN` network configured.

## Example Configuration

Below is a snippet from an upgraded SLS.

```json
 "CHN": {
      "Name": "CHN",
      "FullName": "Customer High-Speed Network",
      "IPRanges": [
        "10.103.9.0/25"
      ],
      "Type": "ethernet",
      "LastUpdated": 1646843463,
      "LastUpdatedTime": "2022-03-09 16:31:03.504156 +0000 +0000",
      "ExtraProperties": {
        "CIDR": "10.103.9.0/25",
        "MTU": 9000,
        "MyASN": 65530,
        "PeerASN": 65533,
        "Subnets": [
          {
            "CIDR": "10.103.9.64/27",
            "FullName": "CHN Dynamic MetalLB",
            "Gateway": "10.103.9.65",
            "MetalLBPoolName": "customer-high-speed",
            "Name": "chn_metallb_address_pool",
            "VlanID": 5
          },
          {
            "CIDR": "10.103.9.0/25",
            "DHCPEnd": "10.103.9.62",
            "DHCPStart": "10.103.9.16",
            "FullName": "CHN Bootstrap DHCP Subnet",
            "Gateway": "10.103.9.1",
            "IPReservations": [
              {
                "IPAddress": "10.103.9.2",
                "Name": "chn-switch-1"
              },
              {
                "IPAddress": "10.103.9.3",
                "Name": "chn-switch-2"
              },
              {
                "Aliases": [
                  "ncn-w004-chn",
                  "time-chn",
                  "time-chn.local"
                ],
                "Comment": "x3000c0s7b0n0",
                "IPAddress": "10.103.9.7",
                "Name": "ncn-w004"
              },
              {
                "Aliases": [
                  "ncn-w003-chn",
                  "time-chn",
                  "time-chn.local"
                ],
                "Comment": "x3000c0s6b0n0",
                "IPAddress": "10.103.9.8",
                "Name": "ncn-w003"
              },
              {
                "Aliases": [
                  "ncn-w002-chn",
                  "time-chn",
                  "time-chn.local"
                ],
                "Comment": "x3000c0s5b0n0",
                "IPAddress": "10.103.9.9",
                "Name": "ncn-w002"
              },
              {
                "Aliases": [
                  "ncn-w001-chn",
                  "time-chn",
                  "time-chn.local"
                ],
                "Comment": "x3000c0s4b0n0",
                "IPAddress": "10.103.9.10",
                "Name": "ncn-w001"
              },
```

In this example, `chn-switch-1` and `chn-switch-2` will be the Arista pair.

SLS entries from the above output:

```json
                "IPAddress": "10.103.9.2",
                "Name": "chn-switch-1"
              },
              {
                "IPAddress": "10.103.9.3",
                "Name": "chn-switch-2"
```

The following config is needed on both switches:

- The prefix list will be the subnet of the CHN, the `ge` will equal the cidr.
  - This prevents routes from other networks being installed into the routing table.

- `router bgp 65533` will match the ASN from SLS.`"MyASN": 65533,`
- The `neighbor` will match every worker node.

```text
ip prefix-list CHN seq 10 permit 10.103.9.64/27 ge 27
!
route-map CHN permit 5
   match ip address prefix-list CHN
!
router bgp 65533
   maximum-paths 32
   neighbor 10.103.9.7 remote-as 65530
   neighbor 10.103.9.7 passive
   neighbor 10.103.9.7 route-map CHN in
   neighbor 10.103.9.7 maximum-routes 12000
   neighbor 10.103.9.8 remote-as 65530
   neighbor 10.103.9.8 passive
   neighbor 10.103.9.8 route-map CHN in
   neighbor 10.103.9.8 maximum-routes 12000
   neighbor 10.103.9.9 remote-as 65530
   neighbor 10.103.9.9 passive
   neighbor 10.103.9.9 route-map CHN in
   neighbor 10.103.9.9 maximum-routes 12000
   neighbor 10.103.9.10 remote-as 65530
   neighbor 10.103.9.10 passive
   neighbor 10.103.9.10 route-map CHN in
   neighbor 10.103.9.10 maximum-routes 12000
```