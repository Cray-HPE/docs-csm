# ARP Cache Tuning Guide

To ensure smooth communication on your network, Address Resolution Protocol (ARP) cache settings must be adjusted to handle a larger number of nodes. This guide will help you calculate and set the appropriate values for your system.

## Prerequisites

The following information is required and will need to be gathered before performing the steps outlined in this guide.

- Total number of communicating nodes (master, worker, storage, compute and application nodes).
- Total number of network interface cards (NICs) in each node.

---

## Key ARP cache settings

1. **`gc_thresh1`**: Minimum number of entries the cache attempts to maintain.
2. **`gc_thresh2`**: Threshold where older entries start getting cleared before the cache overfills.
3. **`gc_thresh3`**: Maximum number of cache entries allowed. If exceeded, new entries may be dropped.
4. **`gc_stale_time`**: Time (in seconds) before an ARP entry is marked stale.
5. **`base_reachable_time_ms`**: Time (in milliseconds) an entry remains valid before being re-verified.

---

## Formula for tuning ARP cache settings

Storage nodes do not have HSN connections. To keep `arp` settings management simple, the values calculated for the worker nodes should also be applied to the storage nodes.

To calculate the base `gc_thresh1` value:

**`gc_thresh1`**:

`gc_thresh1 = (number of nodes) × ((NICS per node)²)`

Where:

- **`number of nodes`** = Total number of communicating nodes (master, worker, storage, compute and application nodes).
- **`NICS per node`** = Number of NICs in each node (HSN NICs + NMN NICs). Nodes will have 2, 3, or 5 total NICs.
    - HSN NICs = number of NICs on the HSN per node. If some compute nodes have 1, some have 2, and some have 4 HSN NICs, then use the largest value of **`4`** HSN NICs per node.
    - NMN NICs = number of NICs on the NMN per node. Most nodes have a single NIC on the NMN, but workers will have two. For the formula, assume each node has **`1`** NIC On the NMN.

### Calculate remaining values

- `gc_thresh2 = 1.5 × gc_thresh1`
- `gc_thresh3 = 2 × gc_thresh2`

## Example calculation

**Scenario**:

- Total nodes = 1000 (master, worker, storage, compute and application nodes).
- Each node has:
    - 4 HSN NICs.
    - 1 NMN NIC.
    - `NICS per node = 4 + 1 = 5`

**`gc_thresh1`**:

`gc_thresh1 = 1000 × (5²) = 25000`

**`gc_thresh2`**:

`gc_thresh2 = 1.5 × 25000 = 37500`

**`gc_thresh3`**:

`gc_thresh3 = 2 × 37500 = 75000`

**Example settings**:

```ini
net.ipv4.neigh.default.gc_thresh1 = 25000
net.ipv4.neigh.default.gc_thresh2 = 37500
net.ipv4.neigh.default.gc_thresh3 = 75000
net.ipv4.neigh.default.gc_stale_time = 240
net.ipv4.neigh.default.base_reachable_time_ms = 1500000
```

## IPv6 Considerations

If your environment uses IPv6, you may also want to set the equivalent IPv6 neighbor cache settings. Just like the IPv4 ARP cache, IPv6 maintains a Neighbor Cache table to map IPv6 addresses to MAC addresses.  
The following parameters can be set using the same calculated values from the IPv4 ARP cache settings:

```ini
net.ipv6.neigh.default.gc_thresh1 = 25000
net.ipv6.neigh.default.gc_thresh2 = 37500
net.ipv6.neigh.default.gc_thresh3 = 75000
net.ipv6.route.gc_thresh = 1024
net.ipv6.xfrm6_gc_thresh = 32768
```

## Host configuration

The following steps describe how to use the Configuration Framework Service (CFS) to configure ARP cache settings for NCNs.

### Prepare VCS branch

1. Use the [Cloning a VCS repository](./Version_Control_Service_VCS.md#cloning-a-vcs-repository) procedure to clone the `csm-config-management` repository.

1. List the available CSM versions (`CSM_RELEASE`).

   ```bash
   kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   ```

1. Determine the import branch to use.

   > **`NOTE`** Update `CSM_RELEASE` for the version being used.

   ```bash
   export CSM_RELEASE=1.7.0
   export IMPORT_BRANCH=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq4 ".[\"${CSM_RELEASE}\"].configuration.import_branch") && echo "${IMPORT_BRANCH}"
   ```

1. Create an integration branch from the import branch for the required configuration.

   ```bash
   cd csm-config-management
   git checkout -b integration-${IMPORT_BRANCH##*/} origin/${IMPORT_BRANCH}
   ```

   Example output:

   ```text
   branch 'integration-1.26.0' set up to track 'origin/cray/csm/1.26.0'.
   Switched to a new branch 'integration-1.26.0'
   ```

   > **`NOTE`** In this example, `integration-1.26.0` is the name of your new branch.

   See [VCS Branching Strategy](./VCS_Branching_Strategy.md) for more information about Git branches.

#### Configure the `csm.ncn.sysctl` Ansible role

1. Update the appropriate variables in `roles/csm.ncn.sysctl/vars/main.yml` using the values calculated in [Formula for Tuning ARP cache settings](#formula-for-tuning-arp-cache-settings).

   > **`NOTE`** The following values are only examples and MUST be updated using the calculated values.

   ```yaml
   sysctl_config:
     - name: net.ipv4.neigh.default.gc_thresh1
       value: 25000
     - name: net.ipv4.neigh.default.gc_thresh2
       value: 37500
     - name: net.ipv4.neigh.default.gc_thresh3
       value: 75000
     - name: net.ipv4.neigh.default.gc_stale_time
       value: 240
     - name: net.ipv4.neigh.default.base_reachable_time_ms
       value: 1500000
   ```
   
   > **`NOTE`** If IPv6 neighbor cache table is also required for a system, add them to the `sysctl_config` list as well.

1. Commit the change and push it back up to the VCS.

   ```bash
   git add roles/csm.ncn.sysctl/vars/main.yml
   git commit -m 'Set ARP cache values for all NCNs'
   git push --set-upstream origin integration-1.26.0
   ```

#### Configure CFS to run the `csm.ncn.sysctl` role

1. Create a CFS configuration using the committed changes.

   1. Obtain the commit hash and create a configuration template file.

      ```bash
      COMMIT=$(git rev-parse --verify HEAD)
      cat << EOF > arp-settings.json
      {
        "layers": [
          {
             "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
             "commit": "${COMMIT}",
             "name": "arp-cache-settings",
             "playbook": "ncn_sysctl.yml"
          }
        ]
      }
      EOF
      ```

   1. Create a CFS configuration from the template file.

      ```bash
      cray cfs configurations update arp-cache-settings --file ./arp-settings.json
      ```

      Example output:

      ```toml
      lastUpdated = "2025-01-06T22:39:46Z"
      name = "arp-cache-settings"
      [[layers]]
      cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
      commit = "36811473a8b98e88ef8afee1df021d55eac50114"
      name = "arp-cache-settings"
      playbook = "ncn_sysctl.yml"
      ```

1. Create a CFS session to apply the configuration to the nodes.

   ```bash
   SESSION=arp-cache-settings-$(date +%Y%m%d%H%M%S)
   cray cfs sessions create --name "${SESSION}" --configuration-name arp-cache-settings
   ```

   Example output:

   ```toml
   name = "arp-cache-settings-20250106224045"   
   
   [ansible]
   config = "cfs-default-ansible-cfg"
   verbosity = 0   
   
   [configuration]
   limit = ""
   name = "arp-cache-settings"   
   
   [status]
   artifacts = []   
   
   [tags]   
   
   [target]
   definition = "dynamic"
   groups = []
   image_map = []   
   
   [status.session]
   startTime = "2025-01-06T22:41:04"
   status = "pending"
   succeeded = "none"
   ```

## Verification

1. Check the CFS session completed successfully.

   ```bash
   cray cfs sessions describe ${SESSION}
   ```

   Example output:

   ```ini
   name = "arp-cache-settings-20250106224045"

   [ansible]
   config = "cfs-default-ansible-cfg"
   verbosity = 0

   [configuration]
   limit = ""
   name = "arp-cache-settings"

   [status]
   artifacts = []

   [tags]

   [target]
   definition = "dynamic"
   groups = []
   image_map = []

   [status.session]
   completionTime = "2025-01-06T22:41:14"
   job = "cfs-e7962be9-1cfa-4604-bb07-d5ae99be5456"
   startTime = "2025-01-06T22:41:04"
   status = "complete"
   succeeded = "true"
   ```

   The session status should be "complete" and succeeded should be "true". See the [troubleshooting](#troubleshooting) section if that is not the case.

1. (`ncn-m001`) Verify ARP settings.

      ```bash
      NCNS=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr '\r\n\t' ',')

      pdsh -w ${NCNS} "sysctl -a | grep -E 'net.ipv4.neigh.default.gc_thresh[1-3]|net.ipv4.neigh.default.gc_stale_time|net.ipv4.neigh.default.base_reachable_time_ms'" | dshbak -c
      ```

      Example output:

      ```ini
      ncn-s001: net.ipv4.neigh.default.base_reachable_time_ms = 30000
      ncn-s001: net.ipv4.neigh.default.gc_stale_time = 240
      ncn-s001: net.ipv4.neigh.default.gc_thresh1 = 2048
      ncn-s001: net.ipv4.neigh.default.gc_thresh2 = 4096
      ncn-s001: net.ipv4.neigh.default.gc_thresh3 = 8192
      ncn-w001: net.ipv4.neigh.default.base_reachable_time_ms = 30000
      ncn-w001: net.ipv4.neigh.default.gc_stale_time = 240
      ncn-w001: net.ipv4.neigh.default.gc_thresh1 = 2048
      ncn-w001: net.ipv4.neigh.default.gc_thresh2 = 4096
      ncn-w001: net.ipv4.neigh.default.gc_thresh3 = 8192
      ncn-m001: net.ipv4.neigh.default.base_reachable_time_ms = 30000
      ncn-m001: net.ipv4.neigh.default.gc_stale_time = 240
      ncn-m001: net.ipv4.neigh.default.gc_thresh1 = 2048
      ncn-m001: net.ipv4.neigh.default.gc_thresh2 = 4096
      ncn-m001: net.ipv4.neigh.default.gc_thresh3 = 8192
      ```
   
2. (`ncn-m001`) Verify IPv6 neighbor table cache settings (if configured).

      ```bash
      pdsh -w ${NCNS} "sysctl -a | grep -E 'net.ipv6.neigh.default.gc_thresh[1-3]|net.ipv6.route.gc_thresh|net.ipv6.xfrm6_gc_thresh'" | dshbak -c
      ```

      Example output:

      ```ini
      ----------------
      ncn-m[001-003],ncn-s[001-003],ncn-w[001-006]
      ----------------
      net.ipv6.neigh.default.gc_thresh1 = 128
      net.ipv6.neigh.default.gc_thresh2 = 512
      net.ipv6.neigh.default.gc_thresh3 = 1024
      net.ipv6.route.gc_thresh = 1024
      net.ipv6.xfrm6_gc_thresh = 32768
      ```

## Troubleshooting

Refer to [View Configuration Session Logs](./View_Configuration_Session_Logs.md) to troubleshoot why the CFS session failed to complete successfully.

## Additional steps

This procedure performs a one time configuration of the target nodes. The ARP cache settings will persist through a reboot of the node but a rebuild of the node
will wipe it.

In order to persist this configuration through a rebuild of the node, the CFS layer should be added to the CFS configuration used for the NCNs.
It may also be desirable to add this layer to the `site_vars.yaml` as well as any bootprep file used for `sat bootprep` to ensure that the `update-cfs-configuration` stage of IUF does not remove this layer.

See [CFS Configurations](CFS_Configurations.md) and the IUF [overview](../iuf/IUF.md) and [configuration](../iuf/workflows/configuration.md) documentation for more information.
