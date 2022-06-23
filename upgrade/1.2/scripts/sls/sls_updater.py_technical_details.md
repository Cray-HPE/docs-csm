# `sls_updater.py` Technical Details

**No action needed. Informational purposes only.**

## Actions and order

This migration is performed offline for data security. The running SLS file is first dumped, then the
migration script is run and a new, migrated output file is created.

1. Migrate switch naming (in order): `leaf` to `leaf-bmc`, and `agg` to `leaf`.
1. Remove `api-gateway` entries from HMLB subnets for CSM 1.2 security.
1. Remove `kubeapi-vip` reservations for all networks except NMN.
1. Create the new BICAN "toggle" network.
1. Migrate the existing CAN to CMN.
1. Create the CHN network.
1. Convert IP addresses of the CAN network.
1. Create MetalLB Pools and ASN entries on CMN and NMN networks.
1. Update `uai_macvlan` in NMN DHCP ranges and `uai_macvlan` VLAN.
1. Remove unused user networks (CAN or CHN) if requested (`--retain-unused-user-network` to keep).

## Migrate switch names

Switch names change in CSM 1.2 and must be applied in the following order:

1. `leaf` switches become `leaf-bmc` switches.
1. `agg` switches become `leaf` switches.

This needs to be done in the order listed above.

## Remove `api-gateway` / `istio-ingress-gateway` reservations from HMNLB subnets

For CSM 1.2, the API gateway no longer listens on the HMNLB MetalLB address pool.
These aliases provided DNS records and have been removed in CSM 1.2.

## Create the BICAN network "toggle"

New for CSM 1.2: The BICAN network `ExtraProperties` value of `SystemDefaultRoute` is used
to point to the CAN, CHN, or CMN, and is used by utilities to systematically toggle routes.

## Migrate existing CAN to new CMN

Using the existing CAN as a template, create the CMN. The same IP addresses will be preserved for
NCNs (`bootstrap_dhcp`). A new `network_hardware` subnet will be created where the end of the previous
`bootstrap_dhcp` subnet existed to contain switching hardware. MetalLB pools in the `bootstrap_dhcp`
subnet will be shifted around to remain at the end of the new bootstrap subnet.

## Create the CHN

With the original CAN as a template, the new CHN will be created. IP addresses will come from the
`--customer-highspeed-network <vlan> <ipaddress>` (or its defaults). This is be created by default, but
can be removed (if not needed or desired) by using the `--retain-unused-user-network` flag.

## Convert the IP addresses of the CAN

Since the original/existing CAN has been converted to the new CMN, the CAN must have new IP addresses.
These are provided using the `--customer-access-network <vlan> <ipaddress>` (or its defaults). This CAN
conversion will happen by default, but the new CAN may be removed (if not needed or desired) by using the
`--retain-unused-user-network` flag.

## Add BGP peering information to CMN and NMN

MetalLB and switches now obtain BGP peers using SLS data.

```text
  --bgp-asn INTEGER RANGE         The autonomous system number for BGP router
                                  [default: 65533;64512<=x<=65534]
  --bgp-cmn-asn INTEGER RANGE     The autonomous system number for CMN BGP
                                  clients  [default: 65534;64512<=x<=65534]
  --bgp-nmn-asn INTEGER RANGE     The autonomous system number for NMN BGP
                                  clients  [default: 65533;64512<=x<=65534]
```

In CMN and NMN:

```yaml
  "Type": "ethernet",
  "ExtraProperties": {
    "CIDR": "10.102.3.0/25",
    "MTU": 9000,
    "MyASN": 65536,
    "PeerASN": 65533,
    "Subnets": 
```

## Remove `kubeapi-vip` reservations for all networks except NMN

Self explanatory. This endpoint now exists only on the NMN.

## Update `uai_macvlan` in NMN ranges and `uai_macvlan` VLAN

Self explanatory. Ranges are used for the addresses of UAIs.

## Remove unused user networks (either CAN or CHN) if desired

By default, the CAN will be removed if `--bican-user-network-name CHN` is specified, or the CHN will be removed if
`--bican-user-network-name CAN` is specified. In order to keep a network from being removed, use the `--retain-unused-user-network` flag.
Retention of the unused network is not normal behavior.

* Generally production systems will NOT want to use this flag unless active toggling between CAN and CHN is required. This is not usual behavior.
* Test/development systems may want to have all networks for testing purposes and might want to retain both user networks.

[Go Back to README.SLS_Upgrade page.](README.SLS_Upgrade.md)