# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-1.0.1 or higher is required in order to upgrade to CSM-1.2.0

- [Stage 0.1 - Install latest docs RPM](#install-latest-docs)
- [Stage 0.2 - Update SLS](#update-sls)
- [Stage 0.3 - Upgrade Management Network](#update-management-network)
- [Stage 0.4 - Prerequisites Check](#prerequisites-check)
- [Stage 0.5 - Backup Workload Manager Data](#backup_workload_manager)
- [Stage 0.6 - Continue to Stage 1](#continue_to_stage1)

<a name="install-latest-docs"></a>

## Stage 0.1 - Install latest docs RPM

1. Install latest document RPM package and prepare assets:

   > The install scripts will look for the RPM in `/root`, so it is important that you copy it there.

   ```bash
    ncn-m001# CSM_RELEASE=csm-1.2.0
   ```

   - Internet Connected

     ```bash
     ncn-m001# wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm -P /root

     ncn-m001# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm

     ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
     ```

   - Air Gapped (replace the PATH_TO below with the location of the rpm)

     ```bash
     ncn-m001# cp [PATH_TO_docs-csm-*.noarch.rpm] /root

     ncn-m001# rpm -Uvh --force /root/docs-csm-*.noarch.rpm

     ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
     ```

<a name="reduce-cpu-limits"></a>

## Stage 0.2 - Update SLS

CSM 1.2 introduces the bifurcated CAN as well as network configuration controlled by data in SLS. An offline upgrade of SLS data is performed. More details on the upgrade and its sequence of events can be found in the [README.SLS_upgrade.md](./scripts/sls/README.SLS_Upgrade.md).

The SLS data upgrade is a critical step in moving to CSM 1.2. Upgraded SLS data is used in DNS and management network configuration. Details of Bifurcated CAN can be found in the [BICAN document](../../operations/network/management_network/index.md) to aid in understanding and decision-making.

One detail which must not be overlooked is that the existing Customer Access Network (CAN) will be migrated or retrofitted into the new Customer Management Network (CMN) while minimizing changes. A new CAN, (or CHN) network is then created. Pivoting the existing CAN to the new CMN allows administrative traffic (already on the CAN) to remain as-is while moving standard user traffic to a new site-routable network.

### Prerequisites

At a minimum, answers to the following questions must be known prior to upgrading:

1. _Will user traffic (non-administrative) come in via the CAN, CHN or is the site Air-gapped?_
2. _What is the internal VLAN and the site-routable IP subnet for the new CAN or CHN?_
3. _Is there a need to preserve any existing IP address(es) during the CAN-to-CMN migration?_
   1. One example would be the `external-dns` IP address used for DNS lookups of system resources from site DNS servers. Changes to `external-dns` often require changes to site resources with requisite process and timeframes from other groups. For preserving `external-dns` IP addresses, the flag is `--preserve-existing-subnet-for-cmn external-dns`. WARNING: It is up to the user to compare pre-upgraded and post-upgraded SLS files for sanity. Specifically, in the case of preserving `external-dns` values, to prevent site-networking changes that might result in NCN IP addresses overlapping during the upgrade process. This requires network subnetting expertise and EXPERT mode below.
   2. Another, mutually exclusive example is the need to preserve all NCN IP addresses related to the old CAN whilst migrating the new CMN. This preservation is not often needed as the transition of NCN IP addresses for the CAN-to-CMN is automatically handled during the upgrade. The flag to preserve CAN-to-CMN NCN IP addresses is mutually exclusive with other preservations and the flag is `--preserve-existing-subnet-for-cmn ncns`.
   3. Should no preservation flag be set, the default behavior is to recalculate every IP address on the existing CAN while migrating to the CMN. The behavior in this case is to calculate the subnet sizes based on number of devices (with a bit of spare room), while maximizing IP address pool sizes for (dynamic) services.
   4. An EXPERT mode of flags also exists whereby manually subnetted allocations can be assigned to the new CMN, bypassing several expectations, but not essential subnetting math. As a note for experts the "Remaining subnets" list from a run using `--preserve-existing-subnet-for-cmn` can be used as an aid in selecting subnets to override with `--cmn-subnet-override` or `--can-subnet-override` values and used to seed another run of the upgrader.

Several other flags in the migration script allow for user input, overrides and guidance to the upgrade process. Taking time to review these options is important. All current options can be seen by running:

```bash
ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --help
```

Example output:

```text
Usage: sls_updater_csm_1.2.py [OPTIONS]

  Upgrade a system SLS file from CSM 1.0 to CSM 1.2.

   1. Migrate switch naming (in order):  leaf to leaf-bmc and agg to leaf.
   2. Remove api-gateway entries from HMLB subnets for CSM 1.2 security.
   3. Remove kubeapi-vip reservations for all networks except NMN.
   4. Create the new BICAN "toggle" network.
   5. Migrate the existing CAN to CMN.
   7. Create the CHN network.
   7. Convert IP addresses of the CAN network.
   8. Create MetalLB Pools Names and ASN entries on CMN and NMN networks.
   9. Update uai_macvlan in NMN dhcp ranges and uai_macvlan VLAN.
  10. Remove unused user networks (CAN or CHN).

Options:
  --sls-input-file FILENAME - Input SLS JSON file  [required]
  --sls-output-file FILENAME - Upgraded SLS JSON file name
  --bican-user-network-name [CAN|CHN|HSN] - Name of the network over which non-admin users access the system  [required]
  --customer-access-network <INTEGER RANGE IPV4NETWORK>... - CAN - VLAN and IPv4 network CIDR block [default: 6, 10.103.6.0/24]
  --customer-highspeed-network <INTEGER RANGE IPV4NETWORK>... - CHN - VLAN and IPv4 network CIDR block [default: 5, 10.104.7.0/24]
  --bgp-asn INTEGER RANGE - The autonomous system number for BGP router [default: 65533;64512<=x<=65534]
  --bgp-chn-asn INTEGER RANGE - The autonomous system number for CHN BGP clients  [default: 65530;64512<=x<=65534]
  --bgp-cmn-asn INTEGER RANGE - The autonomous system number for CMN BGP clients  [default: 65532;64512<=x<=65534]
  --bgp-nmn-asn INTEGER RANGE - The autonomous system number for NMN BGP clients  [default: 65531;64512<=x<=65534]
  --preserve-existing-subnet-for-cmn [external-dns|ncns] -  When creating the CMN from the CAN, preserve the metallb_static_pool for external-dns IP, or bootstrap_dhcp for NCN IP addresses. By default no subnet IP addresses from CAN will be preserved.
  --can-subnet-override <CHOICE IPV4NETWORK>... - [EXPERT] Manually/Statically assign CAN subnets to your choice of network_hardware bootstrap_dhcp, can_metallb_address_pool, and/or can_metallb_static_pool subnets.
  --cmn-subnet-override <CHOICE IPV4NETWORK>... - [EXPERT] Manually/Statically assign CMN subnets to your choice of network_hardware, bootstrap_dhcp, cmn_metallb_address_pool, and/or cmn_metallb_static_pool subnets.
  --help - Show this message and exit.
```

### Retrieve SLS data as JSON

1. Obtain a token:

   ```bash
   ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o    jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Create a working directory:

   ```bash
   ncn-m001# mkdir /root/sls_upgrade
   ncn-m001# cd /root/sls_upgrade
   ```

1. Extract SLS data to a file:

   ```bash
   ncn-m001# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

### Migrate SLS data JSON to CSM 1.2

- Example 1: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

```bash
ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network 5 10.103.11.192/26
```

- Example 2: The CAN as the system default route, keep the generated CHN (for testing), and preserve the existing `external-dns` entry.

```bash
ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-access-network 6 10.103.15.192/26 \
                         --preserve-existing-subnet-for-cmn external-dns
```

- NOTE: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UAN, login nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure that subnet reservations are correct in order to prevent any data mismatches.

Upload migrated SLS file to SLS service:

```bash
ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
```

<a name="update-management-network"></a>

## Stage 0.3 - Upgrade Management Network

#### Verify if Switches have 1.2 Configuration in place.

  1. Login to each management switch `ssh admin@1.2.3.4`

  1. After logging into each switch, you will see output like the below in your prompt if the switches have a CANU generated config for CSM 1.2 in place.

   ```
##################################################################################
    # CSM version:  1.2
    # CANU version: 1.3.2
##################################################################################
   ```

  1. **`Warning:`** If the switch does NOT show like the above output, stop, and go perform the switch config upgrade steps in the [Upgrade Switches From 1.0 to 1.2 Preconfig](../../operations/network/managemenet_network/upgrade.md#upgrade-switches-from-10-to-12-preconfig). Once you've completed each step, return to tthis page.


- See the [Management Network User Guide](../../operations/network/management_network/index.md) for more information on the management network.

<a name="prerequisites-check"></a>

## Stage 0.4 - Prerequisites Check

Run check script:

Set the `SW_ADMIN_PASSWORD` environment variable to the admin password for the switches. This is needed for preflight tests within the check script.

```bash
ncn-m001# export SW_ADMIN_PASSWORD=PutYourOwnPasswordHere
```

> **`IMPORTANT:`** If the password for the local Nexus `admin` account has
> been changed from the default `admin123` (not typical), then set the
> `NEXUS_PASSWORD` environment variable to the correct `admin` password
> before running prerequisites.sh!
>
> For example:
>
> ```bash
> ncn-m001# export NEXUS_PASSWORD=PutYourOwnPasswordHered
> ```
>
> Otherwise, a random 32-character base64-encoded string will be generated
> and updated as the default `admin` password when Nexus is upgraded.

- ```bash
  ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE]
  ```

**`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. **IF** the upgrade `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

**`IMPORTANT:`** If the `NEXUS_PASSWORD` environment variable was set as previously mentioned, then remove it before continuing:

```bash
ncn-m001# unset NEXUS_PASSWORD
```

**`OPTIONAL:`** `customizations.yaml` has been updated in this step. If [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
clone a local working tree and commit appropriate changes to `customizations.yaml`.

For example:

```bash
ncn-m001# git clone <URL> site-init
ncn-m001# cd site-init
ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
ncn-m001# git add customizations.yaml
ncn-m001# git commit -m 'CSM 1.2 upgrade - customizations.yaml'
ncn-m001# git push
```

<a name="backup_workload_manager"></a>

## Stage 0.5 - Backup Workload Manager Data

To prevent any possibility of losing Workload Manager configuration data or files, a back-up is required. Please execute all Backup procedures (for the Workload Manager in use) located in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

<a name="continue_to_stage1"></a>

## Stage 0.6 - Continue to Stage 1
