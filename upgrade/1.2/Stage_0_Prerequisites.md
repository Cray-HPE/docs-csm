# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-1.0.1 is required in order to upgrade to CSM-1.2.0

## Stage 0.1 - Install latest docs RPM

1. Install latest document RPM package:

    * Internet Connected

        ```bash
        ncn-m001# cd /root/
        ncn-m001# wget https://storage.googleapis.com/csm-release-public/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm
        ncn-m001# rpm -Uvh docs-csm-latest.noarch.rpm
        ```

    * Air Gapped (replace the PATH_TO below with the location of the rpm)

        ```bash
        ncn-m001# cp [PATH_TO_docs-csm-*.noarch.rpm] /root
        ncn-m001# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
        ```

## Stage 0.2 - Update SLS

CSM 1.2 introduces the bifurcated CAN as well as network configuration controlled by data in SLS.  An offline upgrade of SLS data is performed.  More details on the upgrade and its sequence of events can be found in the [README.SLS_upgrade.md](./scripts/sls/README.SLS_Upgrade.md).

The SLS data upgrade is a critical step in moving to CSM 1.2.  Upgraded SLS data is used in DNS and management network configuration.  Details of Bifurcated CAN can be found in the [BICAN document](../../operations/network/management_network/index.md) to aid in understanding and decison-making.

One detail which must not be overlooked is that the existing Customer Access Network (CAN) will be migrated or retrofitted into the new Customer Management Network (CMN) while minimizing changes.  A new CAN, (or CHN) network is then created.  Pivoting the existing CAN to the new CMN allows administrative traffic (already on the CAN) to remain as-is while moving standard user traffic to a new site-routable network.

### Prerequisites

At a minimum, answers to the following questions must be known prior to upgrading:

1. _Will user traffic (non-administrative) come in via the CAN, CHN or is the site Air-gapped?_
2. _What is the internal VLAN and the site-routable IP subnet for the new CAN or CHN?_
3. _Is there a need to preserve any existing IP address(es) during the CAN-to-CMN migration?_
   1. One example would be the external-dns IP address used for DNS lookups of system resources from site DNS servers.  Changes to external-dns often require changes to site resources with requisite process and timeframes from other groups.  For preserving external-dns IPs, the flag is `--preserve-existing-subnet-for-cmn external-dns`.
   2. Another, mutually exclusive example is the need to preserve all NCN IPs related to the old CAN whilst migrating the new CMN.  This preservation is not often needed as the transition of NCN IPs for the CAN-to-CMN is automatically handled during the upgrade.  The flag to preserve CAN-to-CMN NCN IPs is mutually exclusive with other preservations and the flag is `--preserve-existing-subnet-for-cmn ncns`.
   3. Should no preservation flag be set, the default behavior is to recalculate every IP on the existing CAN while migrating to the CMN.  The behavior in this case is to calculate the subnet sizes based on number of devices (with a bit of spare room), while maximizing IP pool sizes for (dynamic) services.
   4. An expert mode of flags also exists whereby manually subnetted allocations can be assigned to the new CMN, bypassing several sanity checks.

Several other flags in the migration script allow for user input, overrides and guidance to the upgrade process.  Taking time to review these options is important.  All current options can be seen by running:

```bash
export DOC_DIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
${DOCDIR}/sls_updater_csm_1.2.py --help
```

Example:

```bash
$ export DOC_DIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
$ ${DOCDIR}/sls_updater_csm_1.2.py --help

Usage: sls_updater_csm_1.2.py [OPTIONS]

  Upgrade a system SLS file from CSM 1.0 to CSM 1.2.

   1. Migrate switch naming (in order):  leaf to leaf-bmc and agg to leaf.
   2. Remove api-gateway entries from HMLB subnets for CSM 1.2 security.
   3. Remove kubeapi-vip reservations for all networks except NMN.
   4. Create the new BICAN "toggle" network.
   5. Migrate the existing CAN to CMN.
   7. Create the CHN network.
   7. Convert IPs of the CAN network.
   8. Create MetalLB Pools Names and ASN entries on CMN and NMN networks.
   9. Update uai_macvlan in NMN dhcp ranges and uai_macvlan VLAN.
  10. Remove unused user networks (CAN or CHN) if requested [--retain-unused-user-network] to keep.

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
  --preserve-existing-subnet-for-cmn [external-dns|ncns] -  When creating the CMN from the CAN, preserve the metallb_static_pool for external-dns IP, or bootstrap_dhcp for NCN IPs.  By default no subnet IPs from CAN will be preserved.
  --can-subnet-override <CHOICE IPV4NETWORK>... - [EXPERT] Manually/Statically assign CAN subnets to your choice of network_hardware bootstrap_dhcp, can_metallb_address_pool, and/or can_metallb_static_pool subnets.
  --cmn-subnet-override <CHOICE IPV4NETWORK>... - [EXPERT] Manually/Statically assign CMN subnets to your choice of network_hardware, bootstrap_dhcp, cmn_metallb_address_pool, and/or cmn_metallb_static_pool subnets.
  --retain-unused-user-network BOOLEAN - If a CHN is selected, remove the CAN.  For development systems you probably want this enabled.  [default: True]
  --help - Show this message and exit.
```

### Retrieve SLS data as JSON

Obtain a token:

```bash
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Create a working directory:

```bash
mkdir /root/sls_upgrade
cd /root/sls_upgrade
```

Extract SLS data to a file:

```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
```

### Migrate SLS data JSON to CSM 1.2

* Example 1: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

```bash
export DOC_DIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network 5 10.103.11.192/26
```

* Example 2: The CAN as the system default route, keep the generated CHN (for testing), and preserve the existing external-dns entry.

```bash
export DOC_DIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-access-network 6 10.103.15.192/26 \
                         --preserve-existing-subnet-for-cmn external-dns \
                         --retain-unused-user-network
```

* NOTE: A detailed review of the migrated/upgraded data (using vimdiff or otherwise) for production systems and for systems which have many add-on components (UAN, login nodes, storage integration points, etc...) is strongly recommended.  Particularly, ensure subnet reservations are correct to prevent any data mismatches.

Upload migrated SLS file to SLS service:

```bash
curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
```

## Stage 0.3 - Upgrade Management Network

* See the  [Management Network User Guide](../../operations/network/management_network/index.md) for more information on the management network.

## Stage 0.4 - Execute Prerequisites Check

Run check script:

   > **`IMPORTANT:`** If the password for the local Nexus `admin` account has
   > been changed from the default `admin123` (not typical), then set the
   > `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > before running prerequisites.sh!
   >
   > For example:
   >
   > ```bash
   > ncn-m001# export NEXUS_PASSWORD=cu$t0m@DM1Np4s5w0rd
   > ```
   >
   > Otherwise, a random 32-character base64-encoded string will be generated
   > and updated as the default `admin` password when Nexus is upgraded.

* Internet Connected

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
    ```

    **NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default.

* Air Gapped

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
   ```

**`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. **IF** the upgrade `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

**`IMPORTANT:`** If the `NEXUS_PASSWORD` environment variable was set as previously mentioned, then remove it before continuing:

   ```bash
   ncn-m001# export -n NEXUS_PASSWORD
   ncn-m001# unset NEXUS_PASSWORD
   ```

**`OPTIONAL:`** Customizations.yaml has been updated in this step. If [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
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

## Stage 0.5 - Backup VCS Data

To prevent any possibility of losing configuration data, backup the VCS data and store it in a safe location. See [Version_Control_Service_VCS.md](../../operations/configuration_management/Version_Control_Service_VCS.md#backup-and-restore-data) for these procedures.

**`IMPORTANT:`** As part of this stage, **only perform the backup, not the restore**. The backup procedure is being done here as a precautionary step.

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
