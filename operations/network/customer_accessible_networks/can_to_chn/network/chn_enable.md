# Enabling Customer High Speed Network Routing

- [Process overview and warnings](#process-overview-and-warnings)
- [Prerequisites](#prerequisites)
- [Backup phase](#backup-phase)
  - [Preparation](#preparation)
  - [Create system backups](#create-system-backups)
- [Update phase](#update-phase)
  - [Disable CFS for UAN](#disable-cfs-for-uan)
  - [Update SLS](#update-sls)
  - [Update customizations](#update-customizations)
  - [Update CSM service endpoint data (MetalLB)](#update-csm-service-endpoint-data-metallb)
- [Migrate phase](#migrate-phase)
  - [Migrate NCN workers](#migrate-ncn-workers)
  - [Migrate CSM services (MetalLB)](#migrate-csm-services-metallb)
  - [Migrate UAN](#migrate-uan)
  - [Minimizing UAN downtime](#minimizing-uan-downtime)
    - [Enable CFS for UAN](#enable-cfs-for-uan)
    - [Notify UAN users](#notify-uan-users)
  - [Migrate UAI](#migrate-uai)
  - [Migrate computes (optional)](#migrate-computes-optional)
    - [Add compute IP addresses to CHN SLS data](#add-compute-ip-addresses-to-chn-sls-data)
    - [Upload migrated SLS file to SLS service](#upload-migrated-sls-file-to-sls-service)
    - [Enable CFS layer](#enable-cfs-layer)
- [Cleanup phase](#cleanup-phase)
  - [Remove CAN from SLS](#remove-can-from-sls)
  - [Remove CAN from customizations](#remove-can-from-customizations)
  - [Remove CAN from BSS](#remove-can-from-bss)
  - [Remove CAN from CSM services](#remove-can-from-csm-services)
  - [Remove CAN interfaces from NCNs](#remove-can-interfaces-from-ncns)
  - [Remove CAN names from NCN hosts files](#remove-can-names-from-ncn-hosts-files)
- [Update the management network](#update-the-management-network)
- [Testing](#testing)

## Process overview and warnings

**IMPORTANT** This procedure is quite involved and the complexities should be completely understood before beginning. The procedure is designed to be run after a CSM 1.3 upgrade. With careful preparation this could be run as part of the CSM 1.3 upgrade.

The primary objective of this procedure is to move user traffic (users running jobs) from a CAN network running over the CSM management network, to a CHN network over the Slingshot high speed network, while *minimizing* downtime and outages.

For safety and flexibility this procedures brings up the CHN network while the system remains running on the CAN. Components can then be migrated to the CHN in a controlled manner, with minimal interruptions to existing CAN operations.

The overall process can be summarized as:

1. Backup phase
   1. Save critical runtime data
1. Update phase
   1. Prevent UAN from migrating to the CHN
   1. Add the CHN data and configurations while the CAN remains as-is
1. Migrate phase - perform a controlled configuration and migration of components from the CAN to the CHN
   1. NCN workers
   1. CSM services
   1. UAN
   1. UAI
   1. Compute (optional)
1. Cleanup phase
   1. Remove the CAN from operations and all data sets
1. Upgrade the management network switch configurations

The procedure, to be safe and flexible, is intensive from both the number of steps involved and the amount of system data which needs to be managed.
However, during the migration phase, ample time and flexibility exists to contact system users as well as reverse the migration.

**Note** that updates to the CSM management network are at the very end of this procedure. CSM 1.3 network updates consist only of critical bugfixes as well as interface and `ACL` changes. This completes Bifurcated CAN transitions begun in CSM 1.2.

## Prerequisites

1. The system must have successfully completed a CSM 1.3 upgrade or be ready for CSM 1.3 upgrade.
   1. [Gateway tests from outside the system](../../../../../operations/validate_csm_health.md#413-gateway-health-tests-from-outside-the-system)
   1. [UAI creation tests](../../../../../operations/validate_csm_health.md#62-validate-uai-creation)
   1. [Confirm BGP peering of MetalLB with Edge Routers](../../../../../operations/network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md#check-bgp-status-and-reset-sessions)
1. [Install the latest CSM 1.3 documentation](../../../../../update_product_stream/README.md#check-for-latest-documentation)
1. A site-routable IPv4 subnet for the CHN.
   - Minimally this must be sized to accommodate all of the following:
     - Three IP addresses for switching
     - One IP address for each NCN worker on the system
     - One IP address for the API ingress gateway
     - One IP address for the `oath2-proxy` service
     - One IP address for each NCN UAN on the system
     - IP addresses for the maximum number of UAIs required
     - IP addresses for any other services to be brought up dynamically on the CHN
   - **Note** A `/24` subnet is usually more than sufficient for small-to-medium sized systems with minimal UAI requirements.
1. The Slingshot high speed network is configured and up, including the fabric manager service. This network is required to transit CHN traffic.
1. The Slingshot Host Software is installed and configured on NCN Worker nodes. This is required to expose CHN services. For the purpose of CHN, the host software creates the (required) primary IPv4 address on `hsn0`, often a `10.253` IP address.

## Backup phase

### Preparation

1. (`ncn-m001#`) Make working directories for the procedure.

   ```bash
   mkdir migrate_can_to_chn
   cd migrate_can_to_chn
   export BASEDIR=$(pwd)
   mkdir backups updates cleanup
   export BACKUPDIR=${BASEDIR}/backups
   export UPDATEDIR=${BASEDIR}/updates
   export CLEANUPDIR=${BASEDIR}/cleanup
   ```

1. (`ncn-m001#`) Obtain an API token.

   ```bash
   export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                 https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

### Create system backups

Copying and storing all data in `${BACKUPDIR}` off-system in a version control repository is **highly recommended**.

1. (`ncn-m001#`) Change to the backup directory.

   ```bash
   cd "${BACKUPDIR}"
   ```

1. (`ncn-m001#`) Backup running system SLS data.

   ```bash
   curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

1. (`ncn-m001#`) Backup running system customizations data.

   ```bash
   kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml
   ```

1. (`ncn-m001#`) Backup running system MetalLB `ConfigMap` data.

   ```bash
   kubectl get cm -n metallb-system metallb -o yaml | egrep -v 'creationTimestamp:|resourceVersion:|uid:' > metallb.yaml
   ```

1. (`ncn-m001#`) Backup running system manifest data.

   ```bash
   kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > manifest.yaml
   ```

1. (`ncn-m001#`) Backup running system CFS configuration data.

   ```bash
   cray cfs configurations list --format json > cfs-configurations.json
   ```

1. (`ncn-m001#`) Backup running system BSS data.

   ```bash
   curl -s -X GET -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters | jq . > bss-bootparameters.json
   ```

## Update phase

### Disable CFS for UAN

1. (`ncn-m001#`) Disable CFS changes on UAN to prevent migration to the CHN.

   ```bash
   for xname in $(cray hsm state components list --role Application --subrole UAN --type Node --format json | jq -r .Components[].ID) ; do
       cray cfs components update --enabled false --format json "${xname}"
   done
   ```

### Update SLS

1. (`ncn-m001#`) Move to the update directory.

   ```bash
   cd "${UPDATEDIR}"
   ```

1. (`ncn-m001#`) Set the directory location for the SLS CHN script.

   ```bash
   export SLS_CHN_DIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/sls
   ```

1. (`ncn-m001#`) Add CHN to SLS data.

   ```bash
   "${SLS_CHN_DIR}/sls_can_to_chn.py" --sls-input-file "${BACKUPDIR}/sls_input_file.json" \
      --customer-highspeed-network <CHN VLAN> <CHN IPv4 Subnet> \
      --number-of-chn-edge-switches <number of edge switches> \
      --sls-output-file "${UPDATEDIR}/sls_file_with_chn.json"
   ```

   where:

      - `<CHN VLAN>` is the "stub" VLAN for the CHN. This is currently used only on the edge switches in access mode, not a trunk through the high speed network.
      - `<CHN IPv4 Subnet>` is the pre-requisite site-routable IPv4 subnet for the CHN.
      - `<number of edge switches>` is typically 2 Arista or Aruba switches, but some pre-production systems have 1.

1. (`ncn-m001#`) Upload data to SLS.

   ```bash
   curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F "sls_dump=@${UPDATEDIR}/sls_file_with_chn.json"
   ```

### Update customizations

Add CHN to `customizations.yaml`

1. (`ncn-m001#`) Move to the update directory.

   ```bash
   cd "${UPDATEDIR}"
   ```

1. (`ncn-m001#`) Set the directory location for the customizations script to add CHN.

   ```bash
   export CUSTOMIZATIONS_SCRIPT_DIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/util
   ```

1. (`ncn-m001#`) Create updated `customizations.yaml` against updated SLS.

   ```bash
   "${CUSTOMIZATIONS_SCRIPT_DIR}/update-customizations-network.sh" "${BACKUPDIR}/customizations.yaml" > "${UPDATEDIR}/customizations.yaml"
   yq validate "${UPDATEDIR}/customizations.yaml"
   ```

   **Important** If the updated `customizations.yaml` file is empty or not valid YAML, do not proceed. Instead, stop and debug.

1. (`ncn-m001#`) Upload new `customizations.yaml`.

   This ensures that changes persist across updates.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file="${UPDATEDIR}/customizations.yaml"
   ```

### Update CSM service endpoint data (MetalLB)

1. (`ncn-m001#`) Create new MetalLB configuration map from updated customizations data.

   The new ConfigMap will not be applied in the update phase because this would change service endpoints earlier than desired.

   ```bash
    yq r "${UPDATEDIR}/customizations.yaml" 'spec.network.metallb' |
        yq p - 'data.config.' |
        sed 's/config\:/config\:\ \|/' |
        yq m - "${BACKUPDIR}/metallb.yaml" > "${UPDATEDIR}/metallb.yaml"
   ```

## Migrate phase

### Migrate NCN workers

1. (`ncn-m001#`) Change to updates directory

   ```bash
   cd "${UPDATEDIR}"
   ```

1. (`ncn-m001#`) Ensure that SHS is active by testing if there is an HSN IP address (typically `10.253`) on the `hsn0` interfaces.

   If there is not a primary address on the `hsn0` interface, then this must be fixed before proceeding.

   ```bash
   pdsh -w ncn-w[$(printf "%03d-%03d" 1 $(egrep 'ncn-w...\.nmn' /etc/hosts | wc -l))] ip address list dev hsn0
   ```

   **NOTE** If some interfaces have an HSN address and others do not, then this typically indicates that SHS install is failing. This must be resolved before proceeding.

1. Determine the CFS configuration in use on the worker nodes.

   1. (`ncn#`) Identify the all worker nodes.

      ```bash
      cray hsm state components list --role Management --subrole Worker --format json | jq -r '.Components[] | .ID'
      ```

      Example output:

      ```text
      x3000c0s4b0n0
      x3000c0s6b0n0
      x3000c0s5b0n0
      x3000c0s7b0n0
      ```

   1. (`ncn#`) Identify CFS configuration in use by running the following for each of the the worker nodes identified above.

      ```bash
      cray cfs components describe --format json x3000c0s4b0n0 | jq .desiredConfig
      ```

      Example output:

      ```json
      "management-23.03"
      ```

      **Note** Errors or failed CFS personalization runs may be fixed via the following process, because CFS will be re-run. However, it is better to take time now to troubleshoot the current issue.

1. (`ncn#`) Extract the CFS configuration identified in the previous step.

   ```bash
   CFS_CONFIG_NAME="management-23.03"
   cray cfs configurations describe "${CFS_CONFIG_NAME}" --format json | jq 'del(.lastUpdated) | del(.name)' > ncn-cfs-configuration.json
   ```

   The resulting output file should look similar to this in structure. However, installed products, versions, commit hashes, playbooks, and names will vary.
   **Note** This is an example and should not be used directly as-is.

   ```json
   {
     "layers": [
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/slingshot-host-software-config-management.git",
         "commit": "f4e2bb7e912c39fc63e87a9284d026a5bebb6314",
         "name": "shs-1.7.3-45-1.0.26",
         "playbook": "shs_mellanox_install.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "commit": "92ce2c9988fa092ad05b40057c3ec81af7b0af97",
         "name": "csm-1.9.21",
         "playbook": "site.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git",
         "commit": "4e14a37b32b0a3b779b7e5f2e70998dde47edde1",
         "name": "sat-2.3.4",
         "playbook": "sat-ncn.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
         "commit": "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7",
         "name": "cos-integration-2.3.75",
         "playbook": "ncn.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
         "commit": "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7",
         "name": "cos-integration-2.3.75",
         "playbook": "ncn-final.yml"
       }
     ]
   }
   ```

1. Edit the extracted file.

   Copy the existing CSM layer and create a new layer to run the `enable_chn.yml` playbook. The original CSM layer should still exist after this operation as well as the new layer.

   **Note** this is a an example and should not be copied into the running configuration.

   ```json
   {
     "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
     "commit": "92ce2c9988fa092ad05b40057c3ec81af7b0af97",
     "name": "csm-1.9.21",
     "playbook": "enable_chn.yml"
   }
   ```

   **Important:** This new layer *must* run after the COS `ncn-final.yml` layers, otherwise the HSN interfaces will not be configured correctly and this playbook will fail.
   Typically, placing the new layer at the end of the list is okay.

1. (`ncn#`) Update the CFS configuration.

   ```bash
   cray cfs configurations update "${CFS_CONFIG_NAME}" --file ncn-cfs-configuration.json --format toml
   ```

   Example output:

   ```toml
   lastUpdated = "2023-05-25T09:22:44Z"
   name = "management-23.03"
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/slingshot-host-software-config-management.git"
   commit = "f4e2bb7e912c39fc63e87a9284d026a5bebb6314"
   name = "shs-1.7.3-45-1.0.26"
   playbook = "shs_mellanox_install.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git"
   commit = "4e14a37b32b0a3b779b7e5f2e70998dde47edde1"
   name = "sat-2.3.4"
   playbook = "sat-ncn.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-integration-2.3.75"
   playbook = "ncn.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-integration-2.3.75"
   playbook = "ncn-final.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "enable_chn.yml"
   ```

1. (`ncn#`) Check that NCN personalization runs and completes successfully on all worker nodes.

   Updating the CFS configuration will cause CFS to schedule the nodes for configuration. Run the following command for all worker xnames to verify this has occurred.

   ```bash
   cray cfs components describe --format toml x3000c0s4b0n0
   ```

   Example output:

   ```toml
   configurationStatus = "pending"
   desiredConfig = "management-23.03"
   enabled = true
   errorCount = 0
   id = "x3000c0s4b0n0"
   state = []
   
   [tags]
   ```

   `configurationStatus` should change from `pending` to `configured` once NCN personalization completes successfully.

For more information on management node personalization, see
[Management Node Personalization](../../../../configuration_management/Management_Node_Personalization.md).

### Migrate CSM services (MetalLB)

**Note** this will activate CHN service endpoints and deactivate CAN endpoints.

1. (`ncn-m001#`) Change to updates directory.

   ```bash
   cd "${UPDATEDIR}"
   ```

1. (`ncn-m001#`) Apply MetalLB configuration map with CHN data to the system.

   ```bash
   kubectl apply -f ${UPDATEDIR}/metallb.yaml 
   ```

1. (`ncn-m001#`) Reload MetalLB with CHN data to activate new services.

   ```bash
   kubectl rollout restart deployments -n metallb-system metallb-controller
   ```

### Migrate UAN

### Minimizing UAN downtime

UANs running before and during an upgrade to CHN will continue running with no connectivity or local data impacts until an administrator-scheduled transition takes place. UAN rebuilds and reboots during this time are not supported.

The time frame over which the transition can be scheduled is quite large and the transition requires only that UAN users log out of the UAN (over the old IPv4 address) and log back in (over a new IPv4 address).

Administrators should enable CFS for UAN, ensure plays run successfully and then notify users to migrate by logging out of the UAN over the CAN and back in over the CHN.

#### Enable CFS for UAN

1. (`ncn-m001#`) Enable CFS changes on UAN.

   ```bash
   for xname in $(cray hsm state components list --role Application --subrole UAN --type Node --format json | jq -r .Components[].ID) ; do
      cray cfs components update --enabled true --state "[]" --format json "${xname}"
   done
   ```

1. Reboot UANs.

   When the UAN comes back up it should now have the CHN interface and updated default route configured.

   1. (`uan#`) Verify default route configuration.

      ```bash
      ip r show default
      ```

      Example output

      ```text
      default via 10.103.11.193 dev hsn0
      ```

   1. (`uan#`) Verify `hsn0` interface configuration.

      ```bash
      ip a show hsn0
      ```

      Example output

      ```text
      6: hsn0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP group default qlen 1000
          link/ether 02:00:00:00:00:07 brd ff:ff:ff:ff:ff:ff permaddr ec:0d:9a:c1:b4:30
          altname enp3s0np0
          altname ens2np0
          inet 10.253.0.9/16 scope global hsn0
             valid_lft forever preferred_lft forever
          inet 10.103.11.200/26 scope global hsn0
             valid_lft forever preferred_lft forever
          inet6 fe80::ff:fe00:7/64 scope link 
             valid_lft forever preferred_lft forever
      ```

#### Notify UAN users

Notify users to log out of the UAN over the CAN and back in over the CHN. The old CAN interface is removed during UAN rebuild, but access over the CAN will be removed during the [management network upgrade](#update-the-management-network).

### Migrate UAI

Newly created User Access Instances (UAI) will use the network configured as the `SystemDefaultRoute` in the SLS BICAN network structure.

Existing UAIs will continue to use the network that was set when it was created. Users with existing UAI will need to recreate their instances before the CAN network is removed from workers and the management network switches in the cleanup phase below.

### Migrate computes (optional)

**Important** This part of the procedure is needed only if all compute nodes will have a CHN IPv4 address. The CHN subnet must be large enough to hold *all* compute nodes in the system. The same UAN CFS configuration is used for computes.

#### Add compute IP addresses to CHN SLS data

1. (`ncn-m001#`) Change to updates directory.

   ```bash
   cd "${UPDATEDIR}"
   ```

1. (`ncn-m001#`) Process the SLS file.

   ```bash
   DOCDIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/sls
   "${DOCDIR}/add_computes_to_chn.py" --sls-input-file "${UPDATEDIR}/sls_file_with_chn.json" --sls-output-file "${UPDATEDIR}/sls_file_with_chn_and_computes.json"
   ```

#### Upload migrated SLS file to SLS service

(`ncn-m001#`) If the following command does not complete successfully, then check if the `TOKEN` environment variable is set correctly.

   ```bash
   curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F "sls_dump=@${UPDATEDIR}/sls_file_with_chn_and_computes.json"
   ```

#### Enable CFS layer

CHN network configuration of compute nodes is performed by the UAN CFS configuration layer. This procedure describes how to identify the UAN layer and add it to the compute node configuration.

1. (`ncn-m001#`) Enable CFS changes on compute nodes.

   ```bash
   for xname in $(cray hsm state components list --role Compute --type Node --format json | jq -r .Components[].ID) ; do
      cray cfs components update --enabled true --state "[]" --format json "${xname}"
   done
   ```

1. Determine the CFS configuration that is currently in use on the compute nodes.

   1. (`ncn-m001#`) Identify the compute nodes.

      ```bash
      cray hsm state components list --role Compute --format json | jq -r '.Components[] | .ID'
      ```

      Example output:

      ```text
      x1000c5s1b0n1
      x1000c5s1b0n0
      x1000c5s0b0n0
      x1000c5s0b0n1
      ```

   1. (`ncn-m001#`) Identify the CFS configuration in use on the compute nodes.

      ```bash
      cray cfs components describe --format toml x1000c5s1b0n1
      ```

      Example output:

      ```toml
      configurationStatus = "configured"
      desiredConfig = "cos-config-full-2.3-integration"
      enabled = true
      errorCount = 0
      id = "x1000c5s1b0n1"
      ```

   1. (`ncn-m001#`) Extract the CFS configuration.

      ```bash
      cray cfs configurations describe cos-config-full-2.3-integration --format json | jq 'del(.lastUpdated) | del(.name)' > "${UPDATEDIR}/cos-config-full-2.3-integration.json"
      ```

1. Identify the UAN CFS configuration.

   1. (`ncn-m001#`) Identify the UAN nodes.

      ```bash
      cray hsm state components list --role Application --subrole UAN --format json | jq -r '.Components[] | .ID'
      ```

      Example output:

      ```text
      x3000c0s25b0n0
      x3000c0s16b0n0
      x3000c0s15b0n0
      ```

   1. (`ncn-m001#`) Identify the CFS configuration currently in use for the UANs.

      ```bash
      cray cfs components describe --format toml x3000c0s25b0n0
      ```

      Example output:

      ```toml
      configurationStatus = "configured"
      desiredConfig = "chn-uan-cn"
      enabled = true
      errorCount = 0
      id = "x3000c0s25b0n0"
      ```

   1. (`ncn-m001#`) Identify the UAN CFS configuration layer.

      ```bash
      cray cfs configurations describe chn-uan-cn --format json
      ```

      The resulting output should look similar to this. Installed products, versions, and commit hashes will vary.

      ```json
      {
        "lastUpdated": "2022-05-27T20:15:10Z",
        "layers": [
          {
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
            "commit": "359611be2f6893ddd0020841b73a3d4924120bb1",
            "name": "chn-uan-cn",
            "playbook": "site.yml"
          }
        ],
        "name": "chn-uan-cn"
      }
      ```

1. Edit the JSON file with the extracted compute node configuration and add the UAN layer to the end of the JSON file.

1. (`ncn-m001#`) Update the compute node CFS configuration.

   ```bash
   cray cfs configurations update cos-config-full-2.3-integration --file "${UPDATEDIR}/cos-config-full-2.3-integration.json" --format toml
   ```

   Example output:

   ```toml
   lastUpdated = "2022-05-27T20:47:18Z"
   name = "cos-config-full-2.3-integration"
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/   slingshot-host-software-config-management.git"
   commit = "dd428854a04a652f825a3abbbf5ae2ff9842dd55"
   name = "shs-integration"
   playbook = "shs_mellanox_install.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-compute-integration-2.3.75"
   playbook = "cos-compute.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git"
   commit = "2219ca094c0a2721f3bf52f5bd542d8c4794bfed"
   name = "sma-base-config"
   playbook = "sma-base-config.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git"
   commit = "2219ca094c0a2721f3bf52f5bd542d8c4794bfed"
   name = "sma-ldms-ncn"
   playbook = "sma-ldms-ncn.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/slurm-config-management.git"
   commit = "0982661002a857d743ee5b772520e47c97f63acc"
   name = "slurm master"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/pbs-config-management.git"
   commit = "874050c9820cc0752c6424ef35295289487acccc"
   name = "pbs master"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git"
   commit = "d4b26b74d08e668e61a1e5ee199e1a235e9efa3b"
   name = "analytics integration"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-compute-last-integration-2.3.75"
   playbook = "cos-compute-last.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git"
   commit = "359611be2f6893ddd0020841b73a3d4924120bb1"
   name = "chn-uan-cn"
   playbook = "site.yml"
   ```

1. (`ncn-m001#`) Check that the CFS configuration of the compute node completes successfully.

   Updating the CFS configuration will cause CFS to schedule the nodes for configuration. Run the following command to verify this has occurred.

   ```bash
   cray cfs components describe --format toml x1000c5s1b0n1
   ```

   Example output:

   ```toml
   configurationStatus = "pending"
   desiredConfig = "cos-config-full-2.3-integration"
   enabled = true
   errorCount = 0
   id = "x1000c5s1b0n1"
   state = []

   [tags]
   ```

   `configurationStatus` should change from `pending` to `configured` once CFS configuration of the node is complete.

For more information on managing node with CFS, see [Configuration Management](../../../../../README.md#configuration-management).

## Cleanup phase

Copying and storing all data in the ${CLEANUPDIR} off-system in a version control repository is **highly recommended**.

### Remove CAN from SLS

1. (`ncn-m001#`) Move to the update directory.

   ```bash
   cd "${CLEANUPDIR}"
   ```

1. (`ncn-m001#`) Set the directory location for the SLS CHN script and SLS file.

   ```bash
   export SLS_CHN_DIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/sls
   [[ -f ${UPDATEDIR}/sls_file_with_chn_and_computes.json ]] &&
      export SLS_CHN_FILE=${UPDATEDIR}/sls_file_with_chn_and_computes.json ||
      export SLS_CHN_FILE=${UPDATEDIR}/sls_file_with_chn.json
   ```

1. (`ncn-m001#`) Remove CAN from SLS data.

   ```bash
   "${SLS_CHN_DIR}/sls_del_can.py" \
      --sls-input-file "${SLS_CHN_FILE}" \
      --sls-output-file "${CLEANUPDIR}/sls_file_without_can.json"
   ```

1. (`ncn-m001#`) Upload data to SLS.

   ```bash
   curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F "sls_dump=@${CLEANUPDIR}/sls_file_without_can.json"
   ```

### Remove CAN from customizations

1. (`ncn-m001#`) Move to the cleanup directory.

   ```bash
   cd "${CLEANUPDIR}"
   ```

1. (`ncn-m001#`) Set the directory location for the customizations script to remove CAN.

   ```bash
   export CUSTOMIZATIONS_SCRIPT_DIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/util
   ```

1. (`ncn-m001#`) Remove CAN from `customizations.yaml`.

   ```bash
   "${CUSTOMIZATIONS_SCRIPT_DIR}/update-customizations-network.sh" "${UPDATEDIR}/customizations.yaml" > "${CLEANUPDIR}/customizations.yaml"
   yq validate "${CLEANUPDIR}/customizations.yaml"
   ```

   **Important** If the updated `customizations.yaml` file is empty or not valid YAML, then do not proceed. Instead, stop and debug.

1. (`ncn-m001#`) Upload new `customizations.yaml`.

   This ensures that changes persist across updates.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init "--from-file=${CLEANUPDIR}/customizations.yaml"
   ```

### Remove CAN from BSS

1. (`ncn-m001#`) Move to the cleanup directory.

   ```bash
   cd "${CLEANUPDIR}"
   ```

1. (`ncn-m001#`) Set the directory location for the BSS CHN script.

   ```bash
   export BSS_CAN_DIR=/usr/share/doc/csm/operations/network/customer_accessible_networks/can_to_chn/scripts/bss
   ```

1. (`ncn-m001#`) Remove CAN from BSS data.

   ```bash
   "${BSS_CAN_DIR}/bss_remove_can.py" --bss-input-file "${BACKUPDIR}/bss-bootparameters.json" --bss-output-file "${CLEANUPDIR}/bss-output-chn.json"
   ```

1. (`ncn-m001#`) Upload data to BSS.

   ```bash
   "${BSS_CAN_DIR}/post-bootparameters.sh" -u https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters -f "${CLEANUPDIR}/bss-output-chn.json"
   ```

### Remove CAN from CSM services

**Note** this will remove CAN service endpoints in Kubernetes.

1. (`ncn-m001#`) Create new MetalLB configuration map from updated customizations data.

   ```bash
   yq r "${CLEANUPDIR}/customizations.yaml" 'spec.network.metallb' |
      yq p - 'data.config.' |
      sed 's/config\:/config\:\ \|/' |
      yq m - "${UPDATEDIR}/metallb.yaml" > "${CLEANUPDIR}/metallb.yaml"
   ```

1. (`ncn-m001#`) Apply MetalLB configuration map with CHN data to the system.

   ```bash
   kubectl apply -f "${CLEANUPDIR}/metallb.yaml"
   ```

1. (`ncn-m001#`) Reload MetalLB without CAN data to remove CAN services.

   ```bash
   kubectl rollout restart deployments -n metallb-system metallb-controller
   ```

### Remove CAN interfaces from NCNs

1. (`ncn-m001#`) Remove CAN interfaces from NCN master, worker, and storage nodes.

   ```bash
   pdsh -w $(grep -oP 'ncn-[mws]\d+' /etc/hosts | sort -u |  tr -t '\n' ',') \
                     'rm /etc/sysconfig/network/ifcfg-bond0.can0; \
                      wicked ifdown bond0.can0'
   ```

### Remove CAN names from NCN hosts files

1. (`ncn-m001#`) Remove CAN names from host files on NCN master, worker, and storage nodes.

   ```bash
   pdsh -w $(grep -oP 'ncn-[mws]\d+' /etc/hosts | sort -u |  tr -t '\n' ',') \
                    sed -i '/\.can/d' /etc/hosts
   ```

## Update the management network

Follow the process outlined in [update the management network from CSM 1.2 to CSM 1.3](network_upgrade_1.2_to_1.3.md).

## Testing

The following tests should be run to confirm that the system is operating correctly on the CHN.

1. [Gateway tests from outside the system](../../../../validate_csm_health.md#413-gateway-health-tests-from-outside-the-system)
1. [UAI creation tests](../../../../validate_csm_health.md#62-validate-uai-creation)
1. [Confirm BGP peering of MetalLB with Edge Routers](../../../metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md#check-bgp-status-and-reset-sessions)
