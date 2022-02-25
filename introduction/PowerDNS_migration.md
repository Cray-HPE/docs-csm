# PowerDNS Migration Notice

The migration to PowerDNS as the authoritative DNS source and the introduction of Bifurcated CAN (Customer Access Network) will result in some changes to the node and service naming conventions.

## DNS Record Naming Changes

Fully qualified domain names will be introduced for all DNS records.

Canonical name: `hostname`.`network-path`.`system-name`.`site-domain`

* `hostname` - The hostname of the node or service
* `network-path` - The network path used to access the node
  * .nmn - Node Management Network
  * .nmnlb - Node Management Network LoadBalancers
  * .hmn - Hardware Management Network
  * .hmnlb - Hardware management Network LoadBalancers
  * .hsn - High Speed Network (Slingshot)
  * .can - Customer Access Network
  * .chn - Customer High Speed network
  * .cmn - Customer Management Network
* `system-name` - The customer defined name of the system
* `site-domain` - The top-level domain

It will be possible to refer to a hostname via a short name consisting of `hostname`.`network-path`, for example `ncn-w001.nmn`.

Underscores (`_`) will be removed from all names in favour of hyphens (`-`) to ensure compliance with RFC 1035.

Network paths such as `-nmn` and `-hmn` in the hostname will be removed. The fully qualified domain name will be used to define the network path.

Kubernetes services that were accessed via the `.local` domain will now be accessed via a fully qualified domain name.

### Examples

The following examples assume the system was configured with a `system-name` of `shasta` and a `site-domain` of `dev.cray.com`

| Old name                    | New name                                | Short name                                          |
|-----------------------------|-----------------------------------------|-----------------------------------------------------|
| api-gw-service-nmn.local    | api.nmnlb.shasta.dev.cray.com           | api.nmnlb                                           |
| registry.local              | registry.nmnlb.shasta.dev.cray.com      | registry.nmnlb                                      |
| packages.local              | packages.nmnlb.shasta.dev.cray.com      | packages.nmnlb                                      |
| spire.local                 | spire.nmnlb.shasta.dev.cray.com         | spire.nmnlb                                         |
| rgw-vip.nmn <br> rgw-vip.nmn.local | rgw-vip.nmn.shasta.dev.cray.com  | rgw-vip.nmn                                         |
| rgw-vip.hmn <br> rgw-vip.hmn.local | rgw-vip.hmn.shasta.dev.cray.com  | rgw-vip.hmn                                         |
| ncn-w001                    | ncn-w001.nmn.shasta.dev.cray.com        | ncn-w001.nmn                                        |
| ncn-w001-mgmt               | ncn-w001-mgmt.hmn.shasta.dev.cray.com   | ncn-w001-mgmt.hmn                                   |
| nid000001-nmn               | nid000001.nmn.shasta.dev.cray.com       | nid000001.nmn                                       |
| x3000c0s2b0                 | x3000c0s2b0.hmn.shasta.dev.cray.com     | x3000c0s2b0.hmn                                     |
| x3000c0s2b0n0               | x3000c0s2b0n0.nmn.shasta.dev.cray.com   | x3000c0s2b0n0.nmn                                   |
| x1000c5s0b0n0h0             | x1000c5s0b0n0h0.hsn.shasta.dev.cray.com | x1000c5s0b0n0h0.hsn                                 |
| x1000c5s0b0n0h1             | x1000c5s0b0n0h1.hsn.shasta.dev.cray.com | x1000c5s0b0n0h1.hsn                                 |
| auth.shasta.dev.cray.com    | auth.cmn.shasta.dev.cray.com            |                                                     |
| nexus.shasta.dev.cray.com   | nexus.cmn.shasta.dev.cray.com           |                                                     |
| grafana.shasta.dev.cray.com | grafana.cmn.shasta.dev.cray.com         |                                                     |
| api.shasta.dev.cray.com     | api.cmn.shasta.dev.cray.com<br>api.chn.shasta.dev.cray.com<br>api.can.shasta.dev.cray.com |   |

## Backwards Compatibility

The old service and node names will not be migrated to PowerDNS however they will be maintained in Unbound as local records for the purpose of backwards compatibility. These records will be removed entirely in a future release when the cray-dns-unbound-manager job is deprecated. Unbound will remain as the front-end cache.
