# Setup

This page describes Stage 2 to Stage 6 of [Architecture Overview](README.md#architecture-overview).

Rack Resiliency is setup using an Ansible playbook. This playbook is executed during
[Management Node Personalization](../configuration_management/Management_Node_Personalization.md).

For setting up rack resiliency the following stages are executed by the Ansible playbook:

> Before setting up rack resiliency, enable it using
> [Enable Rack Resiliency in `customizations.yaml`](Enabling_Rack_Resiliency.md#enabling-rack-resiliency),
> without which the following setup will be skipped after
> [Stage 1 - Verify enablement](#stage-1---verify-enablement).

- [Preparation](#preparation)
    - [Stage 1 - Verify enablement](#stage-1---verify-enablement)
    - [Stage 2 - Placement discovery](#stage-2---placement-discovery)
    - [Stage 3 - Placement validation](#stage-3---placement-validation)
- [Kubernetes-setup](#kubernetes-setup)
    - [Stage 4 - Kubernetes zoning](#stage-4---kubernetes-zoning)
    - [Stage 5 - Apply Kyverno policy](#stage-5---apply-kyverno-policy)
- [Ceph-setup](#ceph-setup)
    - [Stage 4 - Ceph zoning](#stage-4---ceph-zoning)
    - [Stage 5 - Ceph HAproxy configuration](#stage-5---ceph-haproxy-configuration)

## Preparation

The below stages are preparatory steps to setup Kubernetes and Ceph for Rack Resiliency.

### Stage 1 - Verify enablement

This Ansible role verifies that Rack Resiliency is enabled in `customizations.yaml`.
If it is not enabled, then the RR setup is skipped.

### Stage 2 - Placement discovery

This Ansible role identifies the physical racks and locates the management nodes in it.
The [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) is queried
for information on all of the management NCNs. This information is used to create a mapping
between the [xnames](../../glossary.md#xname) of the management NCNs and the xnames of the
physical racks that contain them.

The [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) is used to map
these management node xnames to the corresponding Kubernetes and storage node names.
This mapping of rack xnames to Kubernetes and storage node hostnames is stored in the below format
as a JSON file to be consumed by the Kubernetes and Ceph zoning modules later.

Example of JSON file containing rack to management NCN hostname mapping (`rr_hw_discovery.json`):

```json
{
    "x3000": ["ncn-m001", "ncn-w001", "ncn-w004", "ncn-w007", "ncn-s001"],
    "x3001": [
        "ncn-m002",
        "ncn-w002",
        "ncn-w006",
        "ncn-w005",
        "ncn-w008",
        "ncn-s003"
    ],
    "x3002": ["ncn-m003", "ncn-w003", "ncn-w009", "ncn-s002", "ncn-s004"]
}
```

### Stage 3 - Placement validation

This Ansible role uses the discovery results (`rr_hw_discovery.json`) from
[Stage 2 - Placement discovery](#stage-2---placement-discovery) and validates whether the current
placement meets the required criteria for enabling rack resiliency.

![Management nodes placement validation](../../img/rack-resiliency-2.png)

The placement validation algorithm, as shown in the flow chart above, decides whether the current
placement of management nodes is suitable for enabling rack resiliency. If it is found that the
current placement is not suitable for rack resiliency, the validation fails.

This module also evaluates if managed nodes are present in the management rack and informational
messages are generated for the same.

**Note**: [Slingshot](../../glossary.md#slingshot) switch placement discovery and validation is
not included in this process.

## Kubernetes setup

The below stages are used to setup Kubernetes zones and apply the [Kyverno Policy](Kyverno_Policy.md).

### Stage 4 - Kubernetes zoning

This Ansible role uses the discovery results (`rr_hw_discovery.json`) from
[Stage 2 - Placement discovery](#stage-2---placement-discovery) and applies Kubernetes zoning for
Master and Worker nodes. For more information on zoning, see [Zones](Zones.md).

### Stage 5 - Apply Kyverno policy

This Ansible role applies the Kyverno cluster policy `insert-labels-topology-constraints`.
For more information, see [Kyverno Policy](Kyverno_Policy.md).

## Ceph setup

The below stages are used to setup the Ceph zones and update Ceph HAproxy configuration.

### Stage 4 - Ceph zoning

This Ansible role uses the discovery results (`rr_hw_discovery.json`) from
[Stage 2 - Placement discovery](#stage-2---placement-discovery) and applies Ceph zoning for
storage nodes. Along with creating zones for Ceph storage nodes, zones for the Ceph services are
also created. To know more about zoning refer to [Zones](Zones.md).

### Stage 5 - Ceph HAproxy configuration

This Ansible role updates Ceph HAproxy configuration with latest information after performing
Ceph zoning. It also updates `ceph.conf` with latest configuration, on all storage nodes.
