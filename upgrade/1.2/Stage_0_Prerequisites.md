# Stage 0 - Prerequisites and Preflight Checks

> **Reminders:**
>
> - CSM 1.0.1 or higher is required in order to upgrade to CSM 1.2.0.
> - If any problems are encountered and the procedure or command output does not provide relevant guidance, see
>   [Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Abstract (Stage 0)

Stage 0 has several critical procedures which prepares and verify if the environment is ready for upgrade. First, the latest documentation RPM is installed; it includes
critical install scripts used in the upgrade procedure. Next, the current configuration of the System Layout Service (SLS) is updated to have necessary information for CSM 1.2.
The management network configuration is also upgraded. Towards the end, prerequisite checks are performed to ensure that the upgrade is ready to proceed. Finally, a
backup of Workload Manager configuration data and files is created. Once complete, the upgrade proceeds to Stage 1.

### Stages

- [Stage 0.1 - Prepare assets](#stage-01---prepare-assets)
- [Stage 0.2 - Plan and coordinate network upgrade](#stage-02---plan-and-coordinate-network-upgrade)
- [Stage 0.3 - Update SLS](#stage-03---update-sls)
- [Stage 0.4 - Upgrade Management Network](#stage-04---upgrade-management-network)
- [Stage 0.5 - Prerequisites Check](#stage-05---prerequisites-check)
- [Stage 0.6 - Backup Workload Manager Data](#stage-06---backup-workload-manager-data)
- [Stage completed](#stage-completed)

## Stage 0.1 - Prepare assets

1. (`ncn-m001#`) Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   CSM_RELEASE=1.2.0
   ```

1. If there are space concerns on the node, then add an `rbd` device on the node for the CSM tarball.

    See [Create a storage pool](../../operations/utility_storage/Alternate_Storage_Pools.md#create-a-storage-pool)
    and [Create and map an `rbd` device](../../operations/utility_storage/Alternate_Storage_Pools.md#create-and-map-an-rbd-device).

    **Note:** This same `rbd` device can be remapped to `ncn-m002` later in the upgrade procedure, when the CSM tarball is needed on that node.
    However, by default the `prepare-assets.sh` script will delete the CSM tarball in order to free space on the node.
    If using an `rbd` device, this is not necessary or desirable, as it will require the CSM tarball to be downloaded again later in the
    procedure. Therefore, **if using an `rbd` device to store the CSM tarball, then run the `prepare-assets.sh` script with the
    `--no-delete-tarball-file` argument.**

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. (`ncn-m001#`) Download and install the latest documentation RPM.

   > **Important:** The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm \
                -O /root/docs-csm-latest.noarch.rpm &&
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. (`ncn-m001#`) Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_RELEASE}.tar.gz`

   > **`NOTE`** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. (`ncn-m001#`) Run the script.

   > **`NOTE`** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version csm-${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection.

### Manual copy

1. Copy the `docs-csm` RPM package and CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../../update_product_stream/README.md).

1. (`ncn-m001#`) Copy the documentation RPM to `/root` and install it.

   > **Important:**
   >
   > - Replace the `PATH_TO_DOCS_RPM` below with the location of the RPM on `ncn-m001`.
   > - The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   cp PATH_TO_DOCS_RPM /root/docs-csm-latest.noarch.rpm &&
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. (`ncn-m001#`) Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   ```bash
   CSM_TAR_PATH=/path/to/csm-${CSM_RELEASE}.tar.gz
   ```

1. (`ncn-m001#`) Run the script.

   > If using an `rbd` device to store the CSM tarball (or if not wanting the tarball file deleted for other reasons), then append the
   `--no-delete-tarball-file` argument when running the script.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version csm-${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Stage 0.2 - Plan and coordinate network upgrade

### Abstract (Stage 0.2)

Prior to CSM 1.2, the single Customer Access Network (CAN) carried both the administrative network traffic and the user network
traffic. CSM 1.2 introduces bifurcated CAN (BICAN), which is designed to separate administrative network traffic and user network traffic.
With BICAN, the pre-1.2 CAN network is split into two separate networks:

1. Customer Management Network (CMN)

   This network allows only system administrative access from the customer site. The pre-1.2 CAN is renamed to CMN. By
   the end of the CSM 1.2 upgrade, all non-administrative access, such as from UANs, will be removed from CMN.

   During the CSM 1.2 upgrade, UANs will retain their pre-1.2 CAN IP addresses in order to minimize disruption to UANs. However,
   toward the end of the CSM 1.2 upgrade, UANs will stop registering themselves on CMN and will receive new IP addresses on the
   CAN/CHN network. This process is described in more detail in [UAN Migration](#uan-migration).

   Pivoting the pre-1.2 CAN to the new CMN allows administrative traffic (already on the pre-1.2 CAN) to remain as-is while
   moving standard user traffic to a new site-routable network (CAN / CHN).

1. Customer Access Network (CAN) / Customer High-speed Network (CHN)

   For user traffic only (e.g. users running and monitoring jobs), CSM 1.2 allows a choice of one of two networks:

      - Customer Access Network (CAN) \[Recommended\]: this is a new network (VLAN6 in switches) that runs over the management network. This
         network must not be confused with pre-1.2 CAN, which was a monolithic network that allowed both user and administrative
         traffic, was configured as VLAN7 in switches, and is now renamed to CMN. The new CAN allows only user traffic.

      - Customer High-speed Network (CHN) \[CSM 1.2 Tech Preview\]: this is a new network (VLAN5 in switches) that runs over the high-speed fabric.

   Either the new CAN or CHN must be chosen, but not both. Note that the CHN is a technical preview in CSM 1.2, and the new CAN is
   the recommended upgrade. The rest of the upgrade guide provides options for configuring either the new CAN or CHN.

### UAN migration

Steps are taken in order to minimize disruption to UANs during the CSM 1.2 upgrade process. Read these steps
carefully and follow any recommendations and warnings to minimize disruptions to user activity. Note that these steps apply
to all types of application nodes and not just UANs -- the term "UAN" just happens to be more commonly used and understood when
referring to user activity.

1. During the upgrade, the switch `1.2 Preconfig` will not remove UAN ports from the CMN VLAN (the pre-1.2 CAN), allowing UANs
   to retain their existing IP addresses during the CSM 1.2 upgrade process. Traffic to and from UANs will still flow through CMN, but
   may also flow through CAN/CHN networks if desired.

1. CFS will be temporarily disabled for UANs, so that running CFS plays does not remove CMN interfaces from UANs. As mentioned
   in [Abstract (Stage 0.3)](#abstract-stage-03), network configuration is controlled by data in SLS, but CFS plays also pick up
   the same SLS data, which can lead to UANs being prematurely removed from CMN and causing UAN outage. As such, CFS plays
   need to be disabled for UANs.

   (`ncn-m001#`) To disable CFS plays for UANs, you must remove CFS assignment for UANs by running the following command:

   ```bash
   export CRAY_FORMAT=json
   for xname in $(cray hsm state components list --role Application --subrole UAN --type node | jq -r .Components[].ID)
   do
      cray cfs components update --enabled false --desired-config "" $xname
   done
   ```

   > Note that the above command will disable CFS plays for UANs only. If you wish to disable CFS plays for all types of
   > application nodes (recommended), then remove the `--subrole UAN` portion in the snippet above.

1. UAN reboots must be avoided and is not a supported operation during CSM 1.2 upgrade. Rebooting a UAN during a CSM 1.2
   upgrade can re-enable CFS and ultimately lead to removing the CMN interface from UANs, disrupting UAN access for your users.
   As a system administrator, you must inform your users to avoid UAN reboots during the CSM 1.2 upgrade process.

   If, however, a UAN is rebooted, then you need to patch the file `roles/uan_interfaces/tasks/can-v2.yml` for your current
   CSM release in the `vcs/cray/uan-config-management.git` repository and reboot again to bring back the
   CMN (pre-1.2 CAN) interface back in the UAN. Use the following patch file and follow the instructions in
   [Configuration Management](../../operations/README.md#configuration-management) to restore CMN access in your UAN:

   ```text
   --- a/roles/uan_interfaces/tasks/can-v2.yml
   +++ b/roles/uan_interfaces/tasks/can-v2.yml
   @@ -33,21 +33,16 @@
   - name: Get Customer Access Network info from SLS
     local_action:
     module: uri
   -    url: "http://cray-sls/v1/search/networks?name={{ sls_can_name }}"
   +    url: "http://cray-sls/v1/search/networks?name=CMN"
        method: GET
        register: sls_can
   
   -- name: Get Customer Access Network CIDR from SLS, if network exists.
   -  # This assumes that the CAN network is _always_ the third item in the array. This makes the
   -  # implementation fragile. See CASMCMS-6714.
   -  set_fact:
   -    customer_access_network: "{{ sls_can.json[0].ExtraProperties.Subnets[2].CIDR }}"
   -  when: sls_can.status == 200
   -
   -- name: Get Customer Access Network Gateway from SLS, if network exists
   -  set_fact:
   -    customer_access_gateway: "{{ sls_can.json[0].ExtraProperties.Subnets[2].Gateway }}"
   -  when: sls_can.status == 200
   
   +- name: "Get {{ uan_user_access_cfg | upper }} CIDR from SLS, if network exists."
   +  set_fact:
   +    customer_access_network: "{{ item.CIDR }}"
   +    customer_access_gateway: "{{ item.Gateway }}"
   +  loop: "{{ sls_can.json[0].ExtraProperties.Subnets }}"
   +  when: item.FullName == "CMN Bootstrap DHCP Subnet"
   ```

1. Once UAN has been upgraded to 2.4, you may reboot the UANs for the new network configuration changes to take effect.
   UANs will not receive an IP on the CMN network and instead will default their traffic through the new CAN/CHN. For concrete
   details on UAN transition plan for your users, please refer to
   [Minimize UAN Downtime](../../operations/network/management_network/bican_enable.md#minimize-uan-downtime)

1. Note that in CSM 1.2, UAN ports will not be removed from the CMN VLAN7 in switches. In the next CSM release, switch
   configuration will be updated to remove UAN ports from the CMN VLAN7. This enables non-rebooted UANs to continue to work
   and allows for better easing into BICAN in CSM 1.2. More details about this transition plan are outlined in
   [Minimize UAN Downtime](../../operations/network/management_network/bican_enable.md#minimize-uan-downtime)

### UAI migration

Access to UAIs will be disrupted until CSM 1.2 upgrade completes. After the upgrade is completed, UAIs need to be restarted.

### Decide on subnet ranges for new CAN/CHN

Once you have decided whether to use the new CAN or to use CHN for user access, you must decide on the subnet range. Refer
to [Customer Accessible Networks](../../operations/network/customer_accessible_networks/Customer_Accessible_Networks.md)
for subnet ranges and defaults for CAN/CHN.

### Preserving CMN subnet range

It is vital that you preserve the subnet range for the pre-1.2 CAN that is now being renamed to CMN. Changing the subnet
size during the CSM 1.2 upgrade process is unsupported and will break the upgrade.

### Changes to service endpoints

With the introduction of BICAN, URLs for certain services are now different, as it is now necessary to include the network path in the
fully qualified domain name. Furthermore, certain services are only available on CMN:

- Access to administrative services is now restricted to the CMN.
- API access is available via the CMN, new CAN, and CHN.

The following table are a set of examples of how domain names of existing services are impacted. It assumes the system was
configured with a `system-name` of `shasta` and a `site-domain` of `dev.cray.com`.

| Old Name                           | New Name                                  |
|------------------------------------|-------------------------------------------|
| `auth.shasta.dev.cray.com`         | `auth.cmn.shasta.dev.cray.com`            |
| `nexus.shasta.dev.cray.com`        | `nexus.cmn.shasta.dev.cray.com`           |
| `grafana.shasta.dev.cray.com`      | `grafana.cmn.shasta.dev.cray.com`         |
| `prometheus.shasta.dev.cray.com`   | `prometheus.cmn.shasta.dev.cray.com`      |
| `alertmanager.shasta.dev.cray.com` | `alertmanager.cmn.shasta.dev.cray.com`    |
| `vcs.shasta.dev.cray.com`          | `vcs.cmn.shasta.dev.cray.com`             |
| `kiali-istio.shasta.dev.cray.com`  | `kiali-istio.cmn.shasta.dev.cray.com`     |
| `s3.shasta.dev.cray.com`           | `s3.cmn.shasta.dev.cray.com`              |
| `sma-grafana.shasta.dev.cray.com`  | `sma-grafana.cmn.shasta.dev.cray.com`     |
| `sma-kibana.shasta.dev.cray.com`   | `sma-kibana.cmn.shasta.dev.cray.com`      |
| `api.shasta.dev.cray.com`          | `api.cmn.shasta.dev.cray.com`, `api.chn.shasta.dev.cray.com`, `api.can.shasta.dev.cray.com` |

You must inform your users of the change to the `api.*` endpoint to avoid any unexpected disruptions.

Note that the `*.cmn.<system-domain>`, `*.can.<system-domain>`, `*.chn.<system-domain>` suffixes are not configurable. That is, you
**cannot** configure, for example, `*.cmn.<system-domain>` to instead be `*.my-mgmt-network.<system-domain>`.

## Stage 0.3 - Update SLS

### Abstract (Stage 0.3)

CSM 1.2 introduces network configuration controlled by data in SLS. An offline upgrade of SLS data is performed. For more details on the
upgrade and its sequence of events, see the [SLS upgrade `README`](scripts/sls/README.SLS_Upgrade.md).

The SLS data upgrade is a critical step in moving to CSM 1.2. Upgraded SLS data is used in DNS and management network configuration. For details to aid in understanding and
decision making, see the [Management Network User Guide](../../operations/network/management_network/README.md).

> **Important:** If this is the first time performing the SLS update to CSM 1.2, review the [SLS upgrade `README`](scripts/sls/README.SLS_Upgrade.md) in order to ensure
the correct options for the specific environment are used. Two examples are given below. To see all options from the update script, run `./sls_updater_csm_1.2.py --help`.

### Retrieve SLS data as JSON

1.(`ncn-m001#`) Obtain a token.

   ```bash
   export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1.(`ncn-m001#`) Create a working directory.

   ```bash
   mkdir /root/sls_upgrade && cd /root/sls_upgrade
   ```

1.(`ncn-m001#`) Extract SLS data to a file.

   ```bash
   curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

### Migrate SLS data JSON to CSM 1.2

You can now migrate SLS data to CSM 1.2, using the `sls_input_file.json` obtained above, as well as using the desired
network (new CAN or CHN) and its chosen subnet as per [Decide on subnet ranges for new CAN/CHN](#decide-on-subnet-ranges-for-new-canchn).

- (`ncn-m001#`) Example 1: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

   ```bash
   export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network 5 10.103.11.192/26
   ```

- (`ncn-m001#`) Example 2: The CAN as the system default route, keep the generated CHN (for testing), and preserve the existing `external-dns` entry.

   ```bash
   export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-access-network 6 10.103.15.192/26 \
                         --preserve-existing-subnet-for-cmn external-dns
   ```

- **NOTE**: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UANs, login
  nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure that subnet reservations are correct in order to prevent any data mismatches.

### Upload migrated SLS file to SLS service

If the following command does not complete successfully, check if the `TOKEN` environment variable is set correctly.

```bash
curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
```

## Stage 0.4 - Upgrade management network

### Verify that switches have 1.2 configuration in place

1. Log in to each management switch.

   ```bash
   ssh admin@1.2.3.4
   ```

1. Examine the text displayed when logging in to the switch.

   Specifically, look for output similar to the following:

   ```text
   ##################################################################################
   # CSM version:  1.2
   # CANU version: 1.3.2
   ##################################################################################
   ```

   - Output like the above text means that the switches have a CANU-generated configuration for CSM 1.2 in place. In this case, follow the steps in
     [Management Network 1.0 (`1.2 Preconfig`) to 1.2](../../operations/network/management_network/1.0_to_1.2_upgrade.md).
   - If the banner does NOT contain text like the above, then contact support in order to get the `1.2 Preconfig` applied to the system.
   - See the [Management Network User Guide](../../operations/network/management_network/README.md) for more information on the management network.

## Stage 0.5 - Prerequisites check

1. (`ncn-m001#`) Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the password for `admin` user on the switches. This is needed for preflight tests within the check script.

   > **NOTE** `read -s` is used to prevent the password from being written to the screen or the shell history.

   ```bash
   read -s SW_ADMIN_PASSWORD
   ```

   ```bash
   export SW_ADMIN_PASSWORD
   ```

1. Set the `NEXUS_PASSWORD` variable **only if needed**.

   > **IMPORTANT:** If the password for the local Nexus `admin` account has
   > been changed from the default `admin123` (not typical), then set the
   > `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > and export it, before running `prerequisites.sh`.
   >
   > For example:
   >
   > > `read -s` is used to prevent the password from being written to the screen or the shell history.
   >
   > ```bash
   > read -s NEXUS_PASSWORD
   > export NEXUS_PASSWORD
   > ```
   >
   > Otherwise, a random 32-character base-64-encoded string will be generated
   > and updated as the default `admin` password when Nexus is upgraded.

1. (`ncn-m001#`) Run the script.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version ${CSM_RELEASE}
   ```

   **IMPORTANT:** If any errors are encountered, then potential fixes should be displayed where the error occurred. **If** the upgrade `prerequisites.sh` script fails and does
   not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

1. (`ncn-m001#`) Unset the `NEXUS_PASSWORD` variable, if it was set in the earlier step.

   ```bash
   unset NEXUS_PASSWORD
   ```

1. (`ncn-m001#`) Commit changes to `customizations.yaml` (optional).

   `customizations.yaml` has been updated in this procedure. If
   [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
   then clone a local working tree and commit appropriate changes to `customizations.yaml`.

   For example:

   ```bash
   git clone <URL> site-init
   cd site-init
   kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   git add customizations.yaml
   git commit -m 'CSM 1.2 upgrade - customizations.yaml'
   git push
   ```

## Stage 0.6 - Backup workload manager data

To prevent any possibility of losing workload manager configuration data or files, a backup is required. Execute all backup procedures (for the workload manager in use) located in
the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the
`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

## Stage completed

This stage is completed. Continue to [Stage 1 - Ceph image upgrade](Stage_1.md).
