# PowerDNS Migration Notice

The migration to PowerDNS as the authoritative DNS source and the introduction of Bifurcated CAN (Customer Access Network) will result in some changes to the node and service naming conventions.

## DNS Record Naming Changes

Fully qualified domain names will be introduced for all DNS records.

Canonical name: `hostname`.`network-path`.`system-name`.`tld`

* `hostname` - The hostname of the node or service
* `network-path` - The network path used to access the node
  * .nmn - Node Management Network
  * .hmn - Hardware Management Network
  * .hsn - High Speed Network (Slingshot)
  * .can - Customer Access Network
  * .chn - Customer High Speed network
  * .cmn - Customer Management Network
* `system-name` - The customer defined name of the system
* `tld` - The top-level domain

Kubernetes services present on the Hardware Management Network (HMN) and Node Management Network (NMN) that needed to be referenced by name used names in the `.local` domain which will be deprecated in favor of a fully qualified domain name.

### Examples

The following examples assume the system was configured with a `system-name` of `shasta` and a `site-domain` of `dev.cray.com`

| Old name                  | New name                                                                                  |
|---------------------------|-------------------------------------------------------------------------------------------|
| ncn-w001                  | ncn-w001.nmn.shasta.dev.cray.com                                                          |
| nid000001-nmn             | nid000001.nmn.shasta.dev.cray.com                                                         |
| x3000c0s2b0               | x3000c0s2b0.hmn.shasta.dev.cray.com                                                       |
| api-gw-service-nmn.local  | api.nmn.shasta.dev.cray.com                                                               |
| registry.local            | registry.nmn.shasta.dev.cray.com                                                          |
| packages.local            | packages.nmn.shasta.dev.cray.com                                                          |
| nexus.shasta.dev.cray.com | nexus.cmn.shasta.dev.cray.com                                                             |
| api.shasta.dev.cray.com   | api.cmn.shasta.dev.cray.com<br>api.chn.shasta.dev.cray.com<br>api.can.shasta.dev.cray.com |

## Backwards Compatibility

The old service and node names will not be migrated to PowerDNS however they will be maintained in Unbound as local records for the purpose of backwards compatibility. These records will be removed entirely in a future release when the cray-dns-unbound-manager job is deprecated.