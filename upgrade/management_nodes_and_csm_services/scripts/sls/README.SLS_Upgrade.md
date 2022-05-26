# Upgrade SLS Offline from CSM 1.0.x to CSM 1.2

## Abstract

During the update of SLS, at a minimum, answers to the following questions must be known prior to upgrading:

1. By default in 1.2 non-administrative user traffic will be migrated from the CAN to the CHN while minimizing changes. If
   you want it to continue to come in via the CAN, or if the site is air-gapped, specify the correct options Will user
   traffic (non-administrative) come in via the CAN, CHN or is the site air-gapped?

1. What is the internal VLAN and the site-routable IP subnet for the new CAN or CHN?

1. Is there a need to preserve any existing IP address(es) during the CAN-to-CMN migration?

   * One example is the `external-dns` IP address used for DNS lookups of system resources from site DNS servers. Changes to
     `external-dns` often require changes to site resources with requisite process and timeframes from other groups. For
     preserving `external-dns` IP addresses, the flag is `--preserve-existing-subnet-for-cmn external-dns`.

     **WARNING:** It is up to the user to compare pre-upgraded and post-upgraded SLS files for sanity. Specifically, in the
     case of preserving `external-dns` values, to prevent site-networking changes that might result in NCN IP addresses
     overlapping during the upgrade process. This requires network subnetting expertise and EXPERT mode below.
   * Another, mutually exclusive example is the need to preserve all NCN IP addresses related to the old CAN while migrating
     the new CMN. This preservation is not often needed as the transition of NCN IP addresses for the CAN-to-CMN is automatically
     handled during the upgrade. The flag to preserve CAN-to-CMN NCN IP addresses is mutually exclusive with other preservations
     and the flag is `--preserve-existing-subnet-for-cmn ncns`.
   * Should no preservation flag be set, the default behavior is to recalculate every IP address on the existing CAN while migrating
     to the CMN. The behavior in this case is to calculate the subnet sizesbased on number of devices (with a bit of spare room),
     while maximizing IP address pool sizes for (dynamic) services.

## Procedure

1. Get a token:

    ```bash
    ncn# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. Extract SLS data to a file:

    ```bash
    ncn# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
    ```

1. Upgrade SLS data.

    * Example 1: Upgrade, using the CHN as the system default route (will by default output to `migrated_sls_file.json`).

        ```bash
        ncn# ./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                --bican-user-network-name CHN \
                --customer-highspeed-network 5 10.103.11.192/26
        ```

    * Example 2: Upgrade, using the CAN as the system default route, keep the generated CHN (for testing), and preserve the existing external-dns entry.

        ```bash
        ncn# ./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                --bican-user-network-name CAN \
                --customer-highspeed-network 5 10.103.11.192/26 \
                --preserve-existing-subnet-for-cmn external-dns \
                --retain-unused-user-network
        ```

    NOTE: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components
    (UAN, login nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure subnet reservations are correct to prevent any data loss.

1. Upload migrated SLS file to SLS service:

    ```bash
    ncn# curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
    ```

## SLS Updater Help

For help and all options, run the following:

```bash
ncn# ./sls_updater_csm_1.2.py --help
```

## Actions and Order

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

## Migrate Switch Names

Switch names change in CSM 1.2 and must be applied in the following order:

1. `leaf` switches become `leaf-bmc` switches.
1. `agg` switches become `leaf` switches.

This needs to be done in the order listed above.

## Remove `api-gateway` / `istio-ingress-gateway` Reservations from HMNLB Subnets

For CSM 1.2, the API gateway will no longer listen on the HMNLB MetalLB address pool.
These aliases provided DNS records and are being removed.

## Create the BICAN Network "Toggle"

New for CSM 1.2, the BICAN network `ExtraProperties` value of `SystemDefaultRoute` is used
to point to the CAN, CHN, or CMN, and is used by utilities to systematically toggle routes.

## Migrate (existing) CAN to (new) CMN

Using the existing CAN as a template, create the CMN.  The same IP addresses will be preserved for
NCNs (`bootstrap_dhcp`).  A new `network_hardware` subnet will be created where the end of the previous
`bootstrap_dhcp` subnet existed to contain switching hardware. MetalLB pools in the `bootstrap_dhcp`
subnet will be shifted around to remain at the end of the new bootstrap subnet.

## Create the CHN Network

With the original CAN as a template, the new CHN network will be created. IP addresses will come from the
`--customer-highspeed-network <vlan> <ipaddress>` (or its defaults). This is be created by default, but
can be removed (if not needed or desired) by using the `--retain-unused-user-network` flag.

## Convert the IP Addresses of the CAN Network

Since the original/existing CAN has been converted to the new CMN, the CAN must have new IP addresses.
These are provided using the `--customer-access-network <vlan> <ipaddress>` (or its defaults). This CAN
conversion will happen by default, but the new CAN may be removed (if not needed or desired) by using the
`--retain-unused-user-network` flag.

## Add BGP Peering Information to CMN and NMN

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

## Remove `kubeapi-vip` Reservations For All Networks Except NMN

Self explanatory. This endpoint now exists only on the NMN.

## Update `uai_macvlan` in NMN Ranges and `uai_macvlan` VLAN

Self explanatory. Ranges are used for the addresses of UAIs.

## Remove Unused User Networks (Either CAN or CHN) if Desired

By default the CAN will be removed if `--bican-user-network-name CHN` or the CHN will be removed if
`--bican-user-network-name CAN`. In order to keep this network, use the `--retain-unused-user-network` flag.
Retention of the unused network is not normal behavior.

* Generally production systems will NOT want to use this flag unless active toggling between CAN and CHN is required. This is not usual behavior.
* Test/development systems may want to have all networks for testing purposes and might want to retain both user networks.
