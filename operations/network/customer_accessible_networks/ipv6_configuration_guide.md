# IPv6 Configuration Guide

- [IPv6 Configuration Guide](#ipv6-configuration-guide)
    - [Background](#background)
        - [SLS Changes](#sls-changes)
        - [BSS Changes](#bss-changes)
    - [Enablement](#enablement)
    - [Network Configuration](#network-configuration)
    - [Configure Services](#configure-services)
        - [Domain Name System (DNS)](#domain-name-system-dns)
        - [Keycloak](#keycloak)
        - [Network Time Protocol (NTP)](#network-time-protocol-ntp)
        - [Secure Shell (SSH)](#secure-shell-ssh)

## Background

CSM 1.7 adds support for IPv6 on the Customer Management Network (CMN), and Customer High Speed Network (CHN).

This functionality is limited in scope:

- The Customer Access Network (CAN) is not supported.
- Kubernetes does not have IPv6 support enabled.
- IPv6 addresses will be added to the `bond0.cmn0` interface on the NCNs.
- SSH to the NCNs over the CMN using IPv6 is supported.
- SSH to the management network switches over the CMN using IPv6 is supported.
- SSH to UAN nodes over the CHN using IPv6 is supported.
- The use of IPv6 to access an NTP server is supported.
- The use of IPv6 on the `ncn-m001` `lan0` network interface is supported.
- DNS entries for IPv6 addresses are not created in the CSM DNS services.
- The `cray-dns-unbound` service can be configured to access a site DNS server using IPv6 over the CMN.
- The `cray-keycloak` service can be configured to access an LDAP server using IPv6 over the CMN.

### SLS Changes

The CMN and CAN networks in SLS have `CIDR6`, `Gateway6`, and `IPAddress6` fields added to avoid overlap with existing IPv4 data.

Example output:

```json
{
  "Name": "CMN",
  "FullName": "Customer Management Network",
  "IPRanges": [
    "10.102.193.0/25"
  ],
  "Type": "ethernet",
  "ExtraProperties": {
    "CIDR": "10.102.193.0/25",
    "CIDR6": "2001:db8:100:200::/64",
    "MTU": 9000,
    "MyASN": 65532,
    "PeerASN": 65533,
    "Subnets": [
      {
        "CIDR": "10.102.193.0/25",
        "CIDR6": "2001:db8:100:200::/64",
        "FullName": "CMN Management Network Infrastructure",
        "Gateway": "10.102.193.1",
        "Gateway6": "2001:db8:100:200::1",
        "IPReservations": [
          {
            "Comment": "x3000c0h12s1",
            "IPAddress": "10.102.193.2",
            "IPAddress6": "2001:db8:100:200::2",
            "Name": "sw-spine-001"
          }
        ]
      }
    ]
  }
}
```

### BSS Changes

The `cloud-init` metadata for each NCN has `ip6` and `gateway6` fields added so that IPv6 can be configured when NCNs are rebuilt.

Example output:

```json
{
  "cloud-init": {
    "meta-data": {
      "availability-zone": "x3000",
      "instance-id": "i-899A1802",
      "ipam": {
        "cmn": {
          "gateway": "10.102.193.1",
          "gateway6": "fdf8:413:de2c:200::1",
          "ip": "10.102.193.40/25",
          "ip6": "fdf8:413:de2c:200::108/64",
          "parent_device": "bond0",
          "vlanid": 7
        },
        "hmn": {
          "gateway": "10.254.0.1",
          "gateway6": "fdf8:413:de2c:200::1",
          "ip": "10.254.1.17/17",
          "ip6": "fdf8:413:de2c:200::108/64",
          "parent_device": "bond0",
          "vlanid": 4
        },
        "mtl": {
          "gateway": "10.1.0.1",
          "gateway6": "fdf8:413:de2c:200::1",
          "ip": "10.1.1.8/16",
          "ip6": "fdf8:413:de2c:200::108/64",
          "parent_device": "bond0",
          "vlanid": 0
        },
        "nmn": {
          "gateway": "10.252.0.1",
          "gateway6": "fdf8:413:de2c:200::1",
          "ip": "10.252.1.10/17",
          "ip6": "fdf8:413:de2c:200::108/64",
          "parent_device": "bond0",
          "vlanid": 2
        }
      }
    }
  }
}
```

## Enablement

IPv6 support can be enabled in two different ways.

1. Fresh install of CSM

   New command line options were added to the Cray Site Init tool (`csi`).

   | Option         | Description                                           |
   |----------------|-------------------------------------------------------|
   | `chn-gateway6` | IPv6 Gateway for NCNs on the CHN                      |
   | `chn-cidr6`    | Overall IPv6 CIDR for all Customer High-Speed subnets |
   | `cmn-gateway6` | Overall IPv6 CIDR for all Customer Management subnets |
   | `cmn-cidr6`    | IPv6 Gateway for NCNs on the CMN                      |

   These options can be used during a fresh install to configure IPv6. See [`cray-site-init` updates](../../../RELEASE_NOTES.md#cray-site-init-updates) for more information.

1. During an upgrade of CSM

   A new patch subcommand as been added to `csi`. The `csi patch csm ipv6` command takes the `chn-gateway6`, `chn-cidr6`, `cmn-gateway6`, and `cmn-cidr6` arguments and updates SLS and BSS with IPv6 data.

   This command defaults to a dry run and writes all proposed BSS and SLS changes along with backups of the original data to a timestamped directory in the current working directory unless overridden with the `-b|--backup-dir` option.

   The `--commit` option will apply the proposed changes to BSS and SLS. This should be done before the management rollout stage of the [Upgrade CSM and additional products with IUF](../../iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) procedure
   to ensure that the NCNs are rebuild with IPv6 support enabled.

   See [`cray-site-init` updates](../../../RELEASE_NOTES.md#csi-patch-csm-ipv6) for a detailed description of the `csi patch csm ipv6` options.

## Network Configuration

The CSM Automatic Network Utility (CANU) will automatically generate configuration with IPv6 support enabled when supplied an SLS file with IPv6 entries.

Please refer to the [CSM Automatic Network Utility](../management_network/canu/index.md) documentation for more information on network configuration generation and validation.

CANU only generates the networking configuration required by CSM, it does not configure any routes out of the spine switches to site networks.
External connectivity can configured by means of a CANU custom configuration file.
There are many ways in which external connectivity can be achieved and discussing these options is beyond the scope of this document.
Please see [Connect to the CMN and CAN](./Connect_to_the_CMN_CAN.md) for some suggestions and consult your networking team to design the best solution for your site.

## Configure Services

Several CSM services can be configured to use IPv6.

### Domain Name System (DNS)

The `cray-dns-unbound` service can be configured to access a site DNS server using IPv6. See [`cray-dns-unbound` IPv6 Support](../dns/Manage_the_DNS_Unbound_Resolver.md#ipv6-support) for more information.

**`IMPORTANT`** IPv6 must have been configured and enabled on the CMN and NCNs before this is enabled otherwise DNS queries may timeout resulting in system instability.

### Keycloak

The `cray-keycloak` service can be configured to access an LDAP server using IPv6. See [Keycloak IPv6 Support](../../security_and_authentication/keycloak_ipv6_support.md) for more information.

If using LDAP over SSL then the IPv6 address or hostname used must be present as a Subject Alternative Name in the LDAP server certificate otherwise access will fail due to certificate verification issues.

### Network Time Protocol (NTP)

An IPv6 address can be used to define an NTP time source. See [Configure NTP on NCNs](../../node_management/Configure_NTP_on_NCNs.md) for information on how to reconfigure a running system.
If performing a fresh install simply add the IP address or hostname to `ntp-servers` in `system_config.yaml`.

### Secure Shell (SSH)

- NCNs and management network switches.
    - No special configuration is required beyond ensuring BSS has been updated and CANU generated IPv6 enabled switch configuration has been deployed.
- UAN and other Application nodes.
    - IPv6 addresses are assigned in SLS for UAN nodes in the CHN network. The `uan_can_setup` option must be enabled in the `uss-config-management` VCS repo in order to apply this configuration to the node.
      Please refer to the HPE Cray Supercomputing User Services Software (USS) for more information.
