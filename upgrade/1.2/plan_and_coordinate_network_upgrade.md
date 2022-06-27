# Plan and coordinate network upgrade

Prior to CSM 1.2, a single Customer Access Network (CAN) carried both the administrative network traffic and the user network traffic.
CSM 1.2 introduces bifurcated CAN (BICAN), which is designed to separate administrative network traffic and user network traffic.
With BICAN, the pre-1.2 CAN network is split into two separate networks:

1. Customer Management Network (CMN)

   This network allows only system administrative access from the customer site. The pre-1.2 CAN is renamed to CMN.
   By the end of the CSM 1.2 upgrade, all non-administrative access, such as from UANs, will be removed from CMN.

   During the CSM 1.2 upgrade, UANs will retain their pre-1.2 CAN IP addresses in order to minimize disruption to UANs.
   However, toward the end of the CSM 1.2 upgrade, UANs will stop registering themselves on CMN and will receive new IP addresses on the CAN/CHN network.
   This process is described in more detail in [UAN Migration](#uan-migration).

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

## UAN migration

Steps are taken in order to minimize disruption to UANs during the CSM 1.2 upgrade process. Read these steps
carefully and follow any recommendations and warnings to minimize disruptions to user activity. Note that these steps apply
to all types of application nodes and not just UANs -- the term "UAN" just happens to be more commonly used and understood when
referring to user activity.

1. During the upgrade, the switch `1.2 Preconfig` will not remove UAN ports from the CMN VLAN (the pre-1.2 CAN), allowing UANs
   to retain their existing IP addresses during the CSM 1.2 upgrade process. Traffic to and from UANs will still flow through CMN, but
   may also flow through CAN/CHN networks, if desired.

1. CFS will be temporarily disabled for UANs, in order to prevent CFS plays from removing CMN interfaces from UANs. Note that network
   configuration is controlled by data in SLS but CFS plays also pick up the same SLS data, which can lead to UANs being prematurely
   removed from the CMN and causing UAN outages. As such, CFS plays need to be disabled for UANs.

   To disable CFS plays for UANs, remove CFS assignment for UANs by running the following command:

   ```bash
   ncn-m001# for xname in $(cray hsm state components list --role Application --subrole UAN --type node --format json | jq -r .Components[].ID) ; do
                 cray cfs components update --enabled false --desired-config "" --format json $xname
             done
   ```

   > Note that the above command will disable CFS plays for UANs only. If wishing to disable CFS plays for all types of
   > application nodes (recommended), then remove the `--subrole UAN` portion in the snippet above.

1. UAN reboots must be avoided and are not a supported operation during the CSM 1.2 upgrade.
   Rebooting a UAN during a CSM 1.2 upgrade can re-enable CFS and ultimately lead to removing the CMN interface from UANs, disrupting UAN access for users.
   System administrators must inform users to avoid UAN reboots during the CSM 1.2 upgrade process.

   However, if a UAN is rebooted, then the `roles/uan_interfaces/tasks/can-v2.yml` file in the `vcs/cray/uan-config-management.git` repository must be patched for the current CSM release.
  The UAN must then be rebooted again to bring the CMN (pre-1.2 CAN) interface back in the UAN.
  Use the following patch file and follow the instructions in [Configuration Management](../../operations/index.md#configuration-management) to restore CMN access in the UAN.

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

1. Once UAN has been upgraded to 2.4, the UANs may be rebooted for the new network configuration changes to take effect.
   UANs will not receive an IP address on the CMN network and instead will default their traffic through the new CAN/CHN.
   For concrete details on UAN transition plan for users, see
   [Minimize UAN Downtime](../../operations/network/management_network/bican_enable.md#minimize-uan-downtime).

1. Note that in CSM 1.2, UAN ports will not be removed from the CMN VLAN7 in switches. In the next CSM release, switch
   configuration will be updated to remove UAN ports from the CMN VLAN7. This enables non-rebooted UANs to continue to work
   and allows for better easing into BICAN in CSM 1.2. For more details about this transition plan, see
   [Minimize UAN Downtime](../../operations/network/management_network/bican_enable.md#minimize-uan-downtime).

## Manually removing UAN switch ports from the CMN VLAN 7

After the upgrade to UAN 2.4, the UAN switch ports should be removed from CMN VLAN 7, to prevent user traffic from being able to reach endpoints on the CMN.
In the CSM 1.2 and UAN 2.4 upgrade, this removal is not done automatically. A future release or hotfix to CSM will introduce this automation.

The switch configurations can be updated manually to remove VLAN7 from the UAN port configurations.
This procedure is currently being tested and will be linked here when finished.

Watch [this page](../../operations/network/management_network/bican_disable_uan_vlan7.md) for updates and always use the latest documentation, in order to have the latest procedures.
See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation) for details on obtaining and installing the latest CSM documentation.

## UAI migration

Access to UAIs will be disrupted until CSM 1.2 upgrade completes. After the upgrade is completed, UAIs need to be restarted.

## Decide on subnet ranges for new CAN/CHN

After deciding whether to use the new CAN or to use CHN for user access, the subnet range must be decided. Refer
to [Customer Accessible Networks](../../operations/network/customer_accessible_networks/Customer_Accessible_Networks.md)
for subnet ranges and defaults for CAN/CHN.

## Preserving CMN subnet range

**It is vital** that the subnet range is preserved for the pre-1.2 CAN that is now being renamed to CMN. Changing the subnet
size during the CSM 1.2 upgrade process is unsupported and will break the upgrade.

## Changes to service endpoints

With the introduction of BICAN, URLs for certain services are now different, as it is now necessary to include the network path in the
fully qualified domain name. Furthermore, certain services are only available on CMN:

- Access to administrative services is now restricted to the CMN.
- API access is available via the CMN, new CAN, and CHN.

The following table is a set of examples of how domain names of existing services are impacted. It assumes the system was
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

Users must be informed of the change to the `api.*` endpoint to avoid any unexpected disruptions.

Note that the `*.cmn.<system-domain>`, `*.can.<system-domain>`, and `*.chn.<system-domain>` suffixes are not configurable. That is,
`*.cmn.<system-domain>` **cannot** be configured to instead be `*.my-mgmt-network.<system-domain>`, for example.
