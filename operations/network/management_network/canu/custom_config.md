# Generate Switch Configs Including Custom Configurations

Pass in a switch config file that CANU will inject into the generated config. A use case would be to add custom site
connections. This config file will overwrite previously generate config.

The custom-config file type is YAML and a single file can be used for multiple switches. You will need to specify the
switch name and what config inject. The custom-config feature is using the hierarchical configuration library,
documentation can be [found here](https://netdevops.io/hier_config/).

Custom config file examples:

Aruba

```text
sw-spine-001:  |
    ip route 0.0.0.0/0 10.103.15.185
    interface 1/1/36
        no shutdown
        ip address 10.103.15.186/30
        exit
    system interface-group 3 speed 10g
    interface 1/1/2
        no shutdown
        mtu 9198
        description sw-spine-001:16==>ion-node
        no routing
        vlan access 7
        spanning-tree bpdu-guard
        spanning-tree port-type admin-edge
    snmp-server vrf default
    snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
sw-spine-002:  |
    ip route 0.0.0.0/0 10.103.15.189
    interface 1/1/36
        no shutdown
        ip address 10.103.15.190/30
        exit
    system interface-group 3 speed 10g
    snmp-server vrf default
    snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
sw-leaf-bmc-001:  |
    interface 1/1/20
        no routing
        vlan access 4
        spanning-tree bpdu-guard
        spanning-tree port-type admin-edge
    snmp-server vrf default
    snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
```

Mellanox/Dell

```text
sw-spine-001:  |
    interface ethernet 1/1 speed 10G force
    interface ethernet 1/1 description "sw-spine02-1/16"
    interface ethernet 1/1 no switchport force
    interface ethernet 1/1 ip address 10.102.255.14/30 primary
    interface ethernet 1/1 dcb priority-flow-control mode on force
    ip route vrf default 0.0.0.0/0 10.102.255.13
    snmp-server user testuser v3 capability admin
    snmp-server user testuser v3 enable
    snmp-server user testuser v3 enable sets
    snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
    snmp-server user testuser v3 require-privacy
sw-spine-002:  |
    interface ethernet 1/16 speed 10G force
    interface ethernet 1/16 description "sw-spine01-1/16"
    interface ethernet 1/16 no switchport force
    interface ethernet 1/16 ip address 10.102.255.34/30 primary
    interface ethernet 1/16 dcb priority-flow-control mode on force
    ip route vrf default 0.0.0.0/0 10.102.255.33
    snmp-server user testuser v3 capability admin
    snmp-server user testuser v3 enable
    snmp-server user testuser v3 enable sets
    snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
    snmp-server user testuser v3 require-privacy
sw-leaf-bmc-001:  |
    interface ethernet1/1/12
      description sw-leaf-bmc-001:12==>cn003:2
      no shutdown
      switchport access vlan 4
      mtu 9216
      flowcontrol receive off
      flowcontrol transmit off
      spanning-tree bpduguard enable
      spanning-tree port type edge
    interface vlan7
        description CMN
        no shutdown
        ip vrf forwarding Customer
        mtu 9216
        ip address 10.102.4.100/25
        ip access-group cmn-can in
        ip access-group cmn-can out
        ip ospf 2 area 0.0.0.0
    snmp-server group cray-reds-group 3 noauth read cray-reds-view
    snmp-server user testuser cray-reds-group 3 auth md5 xxxxxxxx priv des xxxxxxx
    snmp-server view cray-reds-view 1.3.6.1.2 included
```

To generate switch configuration with custom config injection.

> ***NOTE*** The `--corners` and `--tabs` arguments are often provided in the SHCD Excel file. The example below uses
> example values.

```bash
canu generate switch config \
    --csm CSM_VERSION \
    -a full \
    --shcd FILENAME.xlsx \
    --tabs INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES \
    --corners J14,T44,J14,T48,J14,T24,J14,T23 \
    --sls-file SLS_FILE \
    --name sw-spine-001 \
    --custom-config CUSTOM_CONFIG_FILE.yaml
```

## Generate Network Config

CANU can also generate switch config for all the switches on a network.

In order to generate network config, a valid SHCD or CCJ must be passed in and system variables must be read in from
either CSI output or the SLS API. The instructions are exactly the same as the
above `generate Switch Config](#generate-switch-config)` except there will not be a hostname and a folder must be
specified for config output using the `--folder FOLDERNAME` flag.

To generate switch config from a CCJ paddle run:

```bash
canu generate network config \
    --csm CSM_RELEASE \
    --ccj paddle.json \
    --sls-file SLS_FILE \
    --folder FOLDERNAME
```

To generate switch config from SHCD run:

```bash
canu generate network config \
    --csm CSM_RELEASE \
    -a full \
    --shcd FILENAME.xlsx \
    --tabs INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES \
    --corners J14,T44,J14,T48,J14,T24,J14,T23 \
    --sls-file SLS_FILE \
    --folder switch_config
```

Example output from the above command:

```text
sw-spine-001 Config Generated
sw-spine-002 Config Generated
sw-leaf-001 Config Generated
sw-leaf-002 Config Generated
sw-leaf-003 Config Generated
sw-leaf-004 Config Generated
sw-cdu-001 Config Generated
sw-cdu-002 Config Generated
sw-leaf-bmc-001 Config Generated
```

## Generate Network Config With Custom Config Injection

This option allows extension and maintenance of switch configurations beyond plan-of-record. A YAML file expresses
custom configurations across the network and these configurations are merged with the plan-of-record configurations.

> ***WARNING:*** Extreme diligence should be used applying custom configurations which override plan-of-record generated
configurations. Custom configurations will overwrite generated configurations! Override/overwrite is by design to
support and document cases where site-interconnects demand "non-standard" configurations or a bug must be worked around.

The instructions are exactly the same as Generate Switch Config with Custom Config Injection

To generate network configuration with custom config injection run

```bash
canu generate network config \
    --csm 1.2 \
    -a full \
    --shcd FILENAME.xlsx \
    --tabs INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES \
    --corners J14,T44,J14,T48,J14,T24,J14,T23 \
    --sls-file SLS_FILE \
    --folder switch_config \
    --custom-config CUSTOM_CONFIG_FILE.yaml
```
