# Configure HSN NIC Bonding

* [Configure HSN NIC Bonding](#configure-hsn-nic-bonding)
    * [References](#references)
    * [Limitations](#limitations)
    * [Prerequisites](#prerequisites)
    * [Setup](#setup)
        * [Fabric configuration](#fabric-configuration)
        * [Host configuration](#host-configuration)
            * [Prepare VCS branch](#prepare-vcs-branch)
            * [Configure the `csm.ncn.hsn_bonding` Ansible role](#configure-the-csmncnhsn_bonding-ansible-role)
            * [Configure CFS to run the `csm.ncn.hsn_bonding` role](#configure-cfs-to-run-the-csmncnhsn_bonding-role)
    * [Verification](#verification)
    * [Troubleshooting](#troubleshooting)
    * [Additional steps](#additional-steps)

This procedure can be used to create a bonded HSN interface on an NCN worker node. The `csm.ncn.hsn_bonding` Ansible role is
merely an automation of the manual steps outlined in the "How to create a bonded IP host interface with HPE Slingshot" document (See [References](#references))

## References

The "How to create a bonded IP host interface with HPE Slingshot" document is available from the HPE Support Portal. The other documentation is bundled with the HPE Slingshot software download.

* HPE Slingshot Installation Guide for CSM
* HPE Slingshot Administration Guide
* [How to create a bonded IP host interface with HPE Slingshot](https://support.hpe.com/hpesc/public/docDisplay?docId=dp00004881en_us&docLocale=en_US)

## Limitations

* This procedure is only supported on nodes with HPE Cassini interfaces.
* More than one bonded interface per NCN worker node is not supported.

## Prerequisites

The following steps should have occurred before configuring a bonded interface on a NCN worker node.

* The Slingshot Fabric Manager is installed and configured.
* The Slingshot Host Software is installed and an image containing it has been deployed to the NCN worker nodes.
* The User Services Software is installed and an image containing it has been deployed to the NCN worker nodes.
* Link Aggregation Groups (LAG) have been created using the Slingshot Fabric Manager.
    * An IP address and netmask have been provided by the fabric administrator.
    * The bonding mode used for the LAG has been provided by the fabric administrator.
    * The DMAC used for the LAG has been provided by the fabric administrator (See "How to create a bonded IP host interface with HPE Slingshot") for more information.

## Setup

### Fabric configuration

Configuring a LAG using the Slingshot Fabric Manager is beyond the scope of this document (See the Link Aggregation section of the
"HPE Slingshot Installation Guide for CSM" for more information) however the following example configuration is provided for the
purpose of illustration.

```json
{
  "lagPropertyMap": {
    "2": {
      "portLinks": [
        "/fabric/ports/x3000c0r15j4p0",
        "/fabric/ports/x3000c0r15j4p1"
      ],
      "dmacs": [
        "b2:00:00:00:00:01"
      ],
      "lacpMode": "ACTIVE",
      "lagFeatureMode": "DYNAMIC",
      "lacpTimeout": "SHORT"
    }
  }
}
```

### Host configuration

The following steps describe how to use CFS to configure a bond on an NCN worker node.

#### Prepare VCS branch

1. Use the [Cloning a VCS repository](./Version_Control_Service_VCS.md#cloning-a-vcs-repository) procedure to clone the `csm-config-management` repository.

1. Determine the import branch to use.

   > ***`NOTE`*** Update `CSM_RELEASE` for the version being used.

   ```bash
   CSM_RELEASE=1.6.0
   kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq4 ".[\"${CSM_RELEASE}\"].configuration.import_branch"
   ```

   Example output:

   ```text
   cray/csm/1.26.0
   ```

1. Create an integration branch from the import branch for the required configuration.

   ```bash
   cd csm-config-management
   git checkout -b integration-1.26.0 origin/cray/csm/1.26.0
   ```

   Example output:

   ```text
   branch 'integration-1.26.0' set up to track 'origin/cray/csm/1.26.0'.
   Switched to a new branch 'integration-1.26.0'
   ```

   Refer to [VCS Branching Strategy](./VCS_Branching_Strategy.md) for more information about git branches.

#### Configure the `csm.ncn.hsn_bonding` Ansible role

1. Determine eligible NCN worker nodes.

   ```bash
   sat status --hsm-fields --filter SubRole=Worker
   ```

   Example output:

   ```text
   +----------------+------+--------+-------+------+---------+------+-------+------------+---------+----------+
   | xname          | Type | NID    | State | Flag | Enabled | Arch | Class | Role       | SubRole | Net Type |
   +----------------+------+--------+-------+------+---------+------+-------+------------+---------+----------+
   | x3000c0s4b0n0  | Node | 100008 | Ready | OK   | True    | X86  | River | Management | Worker  | Sling    |
   | x3000c0s5b0n0  | Node | 100007 | Ready | OK   | True    | X86  | River | Management | Worker  | Sling    |
   | x3000c0s6b0n0  | Node | 100006 | Ready | OK   | True    | X86  | River | Management | Worker  | Sling    |
   | x3000c0s30b0n0 | Node | 100005 | Ready | OK   | True    | X86  | River | Management | Worker  | Sling    |
   | x3000c0s31b0n0 | Node | 100004 | Ready | OK   | True    | X86  | River | Management | Worker  | Sling    |
   +----------------+------+--------+-------+------+---------+------+-------+------------+---------+----------+
   ```

1. Define the node-specific Ansible variables.

   This example uses the node `x3000c0s31b0n0` and the following parameters.

   | Parameter             | Value               |
   |-----------------------|---------------------|
   | `hsn_bond_enable`     | `true`              |
   | `hsn_bond_mac` (DMAC) | `b2:00:00:00:00:01` |
   | `hsn_bond_ip`         | `10.253.254.1`      |
   | `hsn_bond_netmask`    | `255.255.0.0`       |

   The DMAC used should match the one defined in the fabric LAG configuration. The four parameters in this table *must* be provided. The values for
   `hsn_bond_mac`, `hsn_bond_ip`, and `hsn_bond_netmask` cannot be derived so must be set. Interface configuration will fail if these values are not provided.

   > **`NOTE`** The `hsn_bond_options` parameter defaults to `"mode=802.3ad xmit_hash_policy=layer2+3 miimon=100 ad_select=bandwidth lacp_rate=fast"` and may need changing if static mode
   > LAGs are to be used instead of LACP. See `roles/csm.nmn_hsn_bonding/README.md` in the `csm-config-management` repository for a full list Ansible variables that can be changed.

1. Create the node-specific variables file.

   Create the file `host_vars/x3000c0s31b0n0.yml` containing the following values. It may be necessary to create the `host_vars` directory if it does not
   already exist.

   ```yaml
   hsn_bond_enable: true
   hsn_bond_mac: "b2:00:00:00:00:01"
   hsn_bond_ip: "10.253.254.1"
   hsn_bond_netmask: '255.255.0.0'
   ```

1. Commit the change and push it back up to the VCS.

   ```bash
   git add host_vars/x3000c0s31b0n0.yml
   git commit -m 'Configure HSN bonding on ncn-w005'
   git push --set-upstream origin integration-1.26.0
   ```

#### Configure CFS to run the `csm.ncn.hsn_bonding` role

1. Create a CFS configuration using the committed changes.

   1. Obtain the commit hash and create a configuration template file.

      ```bash
      COMMIT=$(git rev-parse --verify HEAD)
      cat << EOF > hsn-nic-bonding.json
      {
        "layers": [
          {
             "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
             "commit": "${COMMIT}",
             "name": "hsn-nic-bonding",
             "playbook": "ncn_hsn_bonding.yml"
          }
        ]
      }
      EOF
      ```

   1. Create a CFS configuration from the template file.

      ```bash
      cray cfs configurations update hsn-nic-bonding --file ./hsn-nic-bonding.json
      ```

      Example output:

      ```text
      lastUpdated = "2024-10-11T11:13:39Z"
      name = "hsn-nic-bonding"
      [[layers]]
      cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
      commit = "e8de8f5be0ba6576b4102137db821a0da3b28375"
      name = "hsn-nic-bonding"
      playbook = "ncn_hsn_bonding.yml"
      ```

1. Create a CFS session to apply the configuration to the node(s).

```bash
SESSION=hsn-nic-bonding-$(date +%Y%m%d%H%M%S)
cray cfs sessions create --name "${SESSION}" --configuration-name hsn-nic-bonding
```

Example output:

```text
debug_on_failure = false
logs = "ara.cmn.surtur.hpc.amslabs.hpecorp.net/?label=hsn-nic-bonding-20241011111435"
name = "hsn-nic-bonding-20241011111435"

[ansible]
config = "cfs-default-ansible-cfg"
limit = ""
passthrough = ""
verbosity = 0

[configuration]
limit = ""
name = "hsn-nic-bonding"

[status]
artifacts = []

[tags]

[target]
definition = "dynamic"
groups = []
image_map = []

[status.session]
start_time = "2024-10-11T11:14:48"
status = "pending"
succeeded = "none"
```

## Verification

1. Check the CFS session completed successfully.

   ```bash
   cray cfs sessions describe ${SESSION}
   ```

   Example output:

   ```text
   name = "hsn-nic-bonding-20241011111435"

   [ansible]
   config = "cfs-default-ansible-cfg"
   limit = ""
   passthrough = ""
   verbosity = 0

   [configuration]
   limit = ""
   name = "hsn-nic-bonding"

   [status]
   artifacts = []

   [tags]

   [target]
   definition = "dynamic"
   groups = []
   image_map = []

   [status.session]
   completionTime = "2024-10-11T12:05:21"
   job = "cfs-f2e9a676-7faa-4554-8e20-1d28024c2859"
   startTime = "2024-10-11T12:02:58"
   status = "complete"
   succeeded = "true"
   ```

   The session status should be "complete" and succeeded should be "true". See the [troubleshooting](#troubleshooting) section if that is not the case.

1. Verify the bonded interface is configured.

   1. SSH to the target node.

   1. Check the interface is configured with the correct IP address and MAC address.

      ```bash
      ip ad show bond1
      ```

      Example output:

      ```text
      5: bond1: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
          link/ether b2:00:00:00:00:01 brd ff:ff:ff:ff:ff:ff
          inet 10.253.254.1/16 brd 10.253.255.255 scope global bond1
             valid_lft forever preferred_lft forever
          inet6 fe80::b000:ff:fe00:1/64 scope link proto kernel_ll
             valid_lft forever preferred_lft forever
      ```

   1. Verify both interfaces forming the bonded interface are up.

      ```bash
      cat /proc/net/bonding/bond1
      ```

      Example output:

      ```text
      Ethernet Channel Bonding Driver: v6.4.0-150600.23.17-default

      Bonding Mode: IEEE 802.3ad Dynamic link aggregation
      Transmit Hash Policy: layer2+3 (2)
      MII Status: up
      MII Polling Interval (ms): 100
      Up Delay (ms): 0
      Down Delay (ms): 0
      Peer Notification Delay (ms): 0

      802.3ad info
      LACP active: on
      LACP rate: fast
      Min links: 0
      Aggregator selection policy (ad_select): bandwidth
      System priority: 65535
      System MAC address: b2:00:00:00:00:01
      Active Aggregator Info:
          Aggregator ID: 1
          Number of ports: 2
          Actor Key: 31
          Partner Key: 2
          Partner Mac Address: 02:00:00:00:00:01

      Slave Interface: macvlan1
      MII Status: up
      Speed: 200000 Mbps
      Duplex: full
      Link Failure Count: 2
      Permanent HW addr: b2:00:00:00:00:01
      Slave queue ID: 0
      Aggregator ID: 1
      Actor Churn State: none
      Partner Churn State: none
      Actor Churned Count: 1
      Partner Churned Count: 2
      details actor lacp pdu:
          system priority: 65535
          system mac address: b2:00:00:00:00:01
          port key: 31
          port priority: 255
          port number: 1
          port state: 63
      details partner lacp pdu:
          system priority: 32768
          system mac address: 02:00:00:00:00:01
          oper key: 2
          port priority: 255
          port number: 4
          port state: 63

      Slave Interface: macvlan0
      MII Status: up
      Speed: 200000 Mbps
      Duplex: full
      Link Failure Count: 2
      Permanent HW addr: b2:00:00:00:00:01
      Slave queue ID: 0
      Aggregator ID: 1
      Actor Churn State: none
      Partner Churn State: none
      Actor Churned Count: 0
      Partner Churned Count: 2
      details actor lacp pdu:
          system priority: 65535
          system mac address: b2:00:00:00:00:01
          port key: 31
          port priority: 255
          port number: 2
          port state: 63
      details partner lacp pdu:
          system priority: 32768
          system mac address: 02:00:00:00:00:01
          oper key: 2
          port priority: 255
          port number: 3
          port state: 63
      ```

## Troubleshooting

Refer to [View Configuration Session Logs](./View_Configuration_Session_Logs.md) to troubleshoot why the CFS session failed to complete successfully.

If the underlying HSN interfaces are not up or present refer to the Slingshot documentation listed in [References](#references) to verify the fabric is healthy.
Troubleshooting Slingshot is beyond the scope of this document.

## Additional steps

This procedure performs a one time configuration of the target nodes. The bonded HSN configuration will persist through a reboot of the node but a rebuild of the node
will wipe it.

In order to persist this configuration through a rebuild of the node, the CFS layer should be added to the CFS configuration used for the NCN Worker nodes.
It may also be desirable to add this layer to the `site_vars.yaml` as well as any bootprep file used for `sat bootprep` to ensure that the `update-cfs-configuration` stage
of IUF does not remove this layer.

See [CFS Configurations](CFS_Configurations.md) and the IUF [overview](../iuf/IUF.md) and [configuration](../iuf/workflows/configuration.md) documentation for more information.

