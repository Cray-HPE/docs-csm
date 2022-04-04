# Upgrade SLS Offline from CSM 1.0.x to CSM 1.2

## TL;DR

* Get a token:

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

* Extract SLS data to a file:

```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
```

* Upgrade SLS data (Example 1): Upgrade, using the CHN as the system default route (will by default output to `migrated_sls_file.json`).

```bash
./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network 5 10.103.11.192/26
```

* Upgrade SLS data (Example 2): Upgrade, using the CAN as the system default route, keep the generated CHN (for testing), and preserve the existing external-dns entry.

```bash
./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-highspeed-network 5 10.103.11.192/26 \
                         --preserve-existing-subnet-for-cmn external-dns \
                         --retain-unused-user-network
```

* NOTE: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UAN, login nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure subnet reservations are correct to prevent any data loss.

* Upload migrated SLS file to SLS service:

```bash
curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
```

* For help and all options:

```bash
./sls_updater_csm_1.2.py --help
```

## Actions and Order

This migration script is performed offline for data security. The running SLS file is first dumped, then the migration script is run and a new, migrated output file is created.

  1. Migrate switch naming (in order):  leaf to leaf-bmc and agg to leaf.
  2. Remove api-gateway entries from HMLB subnets for CSM 1.2 security.
  3. Remove kubeapi-vip reservations for all networks except NMN.
  4. Create the new BICAN "toggle" network.
  5. Migrate the existing CAN to CMN.
  6. Create the CHN network.
  7. Convert IP addresses of the CAN network.
  8. Create MetalLB Pools and ASN entries on CMN and NMN networks.
  9. Update uai_macvlan in NMN dhcp ranges and uai_macvlan VLAN.
  10. Remove unused user networks (CAN or CHN) if requested [--retain-unused-user-network to keep].

## Migrate switch names

Switch names change in CSM 1.2 and must be applied in the following order:

1. leaf switches become leaf-bmc switches
2. agg switches become leaf switches

This needs to be done in the order listed above.

## Remove api-gw / istio-ingress-gateway reservations from HMNLB subnets

For CSM 1.2 the api gateway will no longer listen on the HMNLB metallb address pool.
These aliases provided DNS records and are being removed.

## Create the BICAN network "toggle"

New for CSM 1.2 the BICAN network ExtraProperties value of SystemDefaultRoute is used to point to the CAN, CHN or CMN and used by utilities to systematically toggle routes.

## Migrate (existing) CAN to (new) CMN

Using the existing CAN as a template, create the CMN.  The same IP addresses will be preserved for
NCNs (bootstrap_dhcp).  A new network_hardware subnet will be created where the end of the previous bootstrap_dhcp subnet existed to contain switching hardware. MetalLB pools in the bootstrap_dhcp subnet will be shifted around to remain at the end of the new bootstrap subnet.

## Create the CHN network

With the original CAN as a template, the new CHN network will be created. IP addresses will come from the `--customer-highspeed-network <vlan> <ipaddress>` (or its defaults). This will be created all the time and can be removed (if not needed/desired) by using the `--retain-unused-user-network` flag.

## Convert the IP addresses of the CAN network

Since the original/existing CAN has been converted to the new CMN, the CAN must have new IP addresses. These are provided via the `--customer-access-network <vlan> <ipaddress>` (or its defaults).  This CAN conversion will happen all the time, but the new CAN may be removed (if not needed/desired) by using the `--retain-unused-user-network` flag.

## Add BGP peering info to CMN and NMN

MetalLB and switches now obtain BGP peers via SLS data.

```bash
  --bgp-asn INTEGER RANGE         The autonomous system number for BGP router
                                  [default: 65533;64512<=x<=65534]
  --bgp-cmn-asn INTEGER RANGE     The autonomous system number for CMN BGP
                                  clients  [default: 65534;64512<=x<=65534]
  --bgp-nmn-asn INTEGER RANGE     The autonomous system number for NMN BGP
                                  clients  [default: 65533;64512<=x<=65534]
```

In CMN and NMN:

```bash
  "Type": "ethernet",
  "ExtraProperties": {
    "CIDR": "10.102.3.0/25",
    "MTU": 9000,
    "MyASN": 65536,
    "PeerASN": 65533,
    "Subnets": [
      {
```

## Remove kubeapi-vip reservations for all networks except NMN

Self explanatory. This endpoint now exists only on the NMN.

## Update uai_macvlan in NMN ranges and uai_macvlan VLAN

Self explanatory. Ranges are used for the addresses of UAIs.

## Remove unused user networks (either CAN or CHN) if desired

By default the CAN will be removed if `--bican-user-network-name CHN` or the CHN will be removed if `--bican-user-network-name CAN`.  To keep this network use the `--retain-unused-user-network` flag. Retention of the unused network is not normal behavior.

* Generally production systems will NOT want to use this flag unless active toggling between CAN and CHN is required. This is not usual behavior.
* Test/development systems may want to have all networks for testing purposes and might want to retain both user networks.
