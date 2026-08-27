# Customer Accessible Networks

There are generally two networks accessible by devices outside of the CSM cluster.
One network is for administrators managing the cluster and one is for users
accessing user services provided by the cluster.

## Customer Management Network

The Customer Management Network (CMN) provides access from outside the customer
network to administrative services and [non-compute nodes (NCNs)][ncn]. This
allows for the following:

- Administrator clients outside of the system:
    - Log in to NCNs.
    - Access administrative web UIs within the system (e.g. Vmselect, Grafana, and more).
    - Access the administrative REST APIs.
    - Access a DNS server within the system for resolution of names for the webUI and
      REST API services.
    - Run administrative [Cray CLI][cli] commands from outside the system.
- NCNs to access systems outside the cluster (e.g. LDAP, license servers, and more).
- Services within the cluster to access systems outside the cluster.

These nodes and services need an IP address that routes to the customer's network in order
to be accessed from outside the network.

### Implications if CMN is not configured

- No direct access to the [NCNs][ncn] other than `ncn-m001`.
    - It will be necessary to hop through `ncn-m001` to get to the rest of the NCNs.
- No direct access to the [UANs][uan] unless the UAN has a direct connection to the customer network.
- NCNs other than `ncn-m001` do not have access to services outside of the system
  (e.g. LDAP, license servers, and more).
    - These nodes will not have an interface on any network with access outside of the
      HPE Cray EX system.
    - These nodes will not have a default route.
    - This includes access to any of the externally exposed services from these nodes.
- Pods running on NCNs other than `ncn-m001` will not have access to services outside of the system.
- No access to externally exposed services.
    - See [Externally Exposed Services](Externally_Exposed_Services.md) for more information.

## Customer User Networks (CAN/CHN)

The CSM cluster can be configured with a user network that uses either the management network
or the high-speed network. The cluster cannot have both Customer Access Network (CAN) and
Customer High-Speed Network (CHN).

The CAN will use a VLAN on the management switches. The CHN will use the high-speed network.

The user network will allow for the following:

- User clients outside of the system:
    - Log in to [UANs][uan].
    - Access user web UIs within the system (e.g. Capsules).
    - Access the user REST APIs.
    - Run user [Cray CLI][cli] commands from outside the system.
- UANs to access systems outside the cluster (e.g. LDAP, license servers, and more).

## Subnet configuration

### CMN subnets

CMN IP addresses are allocated from a single IP subnet that is configured as the `cmn-cidr` value in the
[`csi config init`][csi] input. This subnet is further divided into three smaller subnets:

- Subnet for [NCNs][ncn] and switches.
- Subnet for the MetalLB static pool (`cmn-static-pool`).
    - This is used for services that need to be pinned to the same IP address.
        - For example, the [PowerDNS](../dns/PowerDNS_Configuration.md) service that needs to be
          configured in the upstream DNS server.
    - This subnet needs only a few IP addresses.
- Subnet for the MetalLB dynamic pool (`cmn-dynamic-pool`).
    - This is used for the rest of the externally exposed services and are allocated dynamically.
    - These IP addresses can be allocated differently across deployments because these services are
      accessed by DNS name rather than by IP address.

The minimum size for the CMN subnet is `/25`. The CMN `/25` subnet allows for the following:

- 16 IP addresses for NCNs
- 16 IP addresses for switches.
- 4 IP addresses for the CMN static service IP addresses.
- 64 IP addresses for the rest of the external CMN services.
    - 6 of these IP addresses are used as standard CMN service IP addresses
    - The remaining 58 IP addresses are for [IMS][ims] services.

![CMN /25 Subnet Layout](../../../img/operations/CMN_25_Subnet.png "CMN /25 Subnet Layout")

If there are more IP addresses needed for any of those sections, then the CMN subnet must
be larger than a `/25` subnet.

### CAN/CHN subnets

CAN or CHN IP addresses are allocated from a single IP subnet that is configured as the `can-cidr`
or `chn-cidr` value in the [`csi config init`][csi] input. Only one of these two networks should
be defined. The user network subnet is further divided into two smaller subnets:

- Subnet for [NCNs][ncn], [UANs][uan], and switches.
- Subnet for the MetalLB dynamic pool (`can-dynamic-pool`) or (`chn-dynamic-pool`).
    - This is used for all of the externally exposed services and are allocated dynamically.
    - These IP addresses can be allocated differently across deployments because these services are
      accessed by DNS name rather than by IP address.

The minimum size for the CAN or CHN subnet is `/27`. The `/27` subnet allows for the following:

- 16 IP addresses for NCNs, UANs, and switches
- 16 IP addresses for the external CAN or CHN services.
    - 2 of these IP addresses are used as standard CAN/CHN service IP addresses.

![CAN/CHN /27 Subnet Layout](../../../img/operations/CAN_CHN_27_Subnet.png "CAN/CHN /27 Subnet Layout")

If there are more than 16 IP addresses needed for either of those sections, then the CAN/CHN subnet must
be larger than a `/27` subnet.

### Customer variables

The following variables are defined in the [`csi config init`][csi] input.
These examples use values for the layouts described above.
`cmn-external-dns` must be an IP address within the `cmn-static-pool` CIDR.

`bican-user-network-name` specifies whether the user network is on the management network (CAN)
or the high-speed network (CHN).

```bash
csi config init
```

Example output with CAN:

```text
[...]

     --system-name testsystem
     --site-domain example.com
     --bican-user-network-name CAN
     --cmn-cidr 10.102.5.0/25
     --cmn-gateway 10.102.5.1
     --cmn-static-pool 10.102.5.60/30
     --cmn-dynamic-pool 10.102.5.64/26
     --cmn-external-dns 10.102.5.61
     --can-cidr 10.102.6.0/27
     --can-gateway 10.102.6.1
     --can-dynamic-pool 10.102.6.16/28

[...]
```

Example output with CHN:

```text
[...]

     --system-name testsystem
     --site-domain example.com
     --bican-user-network-name CHN
     --cmn-cidr 10.102.5.0/25
     --cmn-gateway  10.102.5.1
     --cmn-static-pool 10.102.5.60/30
     --cmn-dynamic-pool 10.102.5.64/26
     --cmn-external-dns 10.102.5.61
     --chn-cidr 10.102.6.0/27
     --chn-gateway  10.102.6.1
     --chn-dynamic-pool 10.102.6.16/28

[...]
```

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cmn]: ../../../glossary.md#customer-management-network-cmn
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
