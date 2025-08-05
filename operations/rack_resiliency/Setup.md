# Setup

For setting up rack resiliency the following steps are necessary:

- [Enabling rack resiliency in `customizations.yaml`](Enabling_Rack_Resiliency.md#1-enabling-rack-resiliency)
- [Running the ansible playbooks](#running-ansible-playbooks)
  - [Setting up kubernetes zoning](#setting-up-kubernetes-zoning)
    - [Stage 1 - Check enablement](#stage-1---check-enablement)
    - [Stage 2 - Placement Discovery](#stage-2---placement-discovery)
    - [Stage 3 - Placement Validation](#stage-3---placement-validation)
    - [Stage 4 - Kubernetes Zoning](#stage-4---kubernetes-zoning)
    - [Stage 5 - Apply Kyverno policy](#stage-5---apply-kyverno-policy)
  - [Setting up ceph zoning](#setting-up-ceph-zoning)
    - [Stage 1 - Check enablement](#stage-1---check-enablement-1)
    - [Stage 2 - Placement Discovery](#stage-2---placement-discovery-1)
    - [Stage 3 - Placement Validation](#stage-3---placement-validation-1)
    - [Stage 4 - Ceph Zoning](#stage-4---ceph-zoning)
    - [Stage 5 - Ceph HAproxy Configuration](#stage-5---ceph-haproxy-configuration)
- [Deploying helm charts for Rack Resiliency Service (RRS)](#deploying-helm-charts-for-rack-resiliency-service-rrs)

### Running ansible playbooks

The Ansible playbooks are executed during the node personalisation phase of **Management Node Rollout**
stage of [CSM upgrade](../iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md). There are separate personalisations for master and storage nodes to setup rack resiliency.

**NOTE:** The [HPC CSM Software Recipe](https://github.hpe.com/hpe/hpc-csm-software-recipe/blob/main/vcs/bootprep/management-bootprep.yaml) includes a CFS layer for rack resiliency from CSM 1.7.0

#### Setting up kubernetes zoning

The below stages are used to setup the kubernetes zones and apply the kyverno policy required for RRS using Ansible plays:

##### Stage 1 - Check enablement

This ansible play checks whether rack resiliency is enabled in the `customizations.yaml` file. If it is not enabled then the remaining playbooks do not run.

##### Stage 2 - Placement Discovery

This ansible play identifies the physical racks and locates the management nodes in it. The [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) is queried for information on all of the management NCNs. This information is used to create a mapping between the [xnames](../../glossary.md#xname) of the management NCNs and the xnames of the racks that contain them.

The [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) is used to map these management node xnames to the corresponding Kubernetes and storage node names. This mapping of rack xnames to Kubernetes and storage node hostnames is stored in the below format as a JSON file to be consumed by the Kubernetes and Ceph zoning modules later.

Example of JSON file containing rack to management NCN hostname mapping (`rr_hw_discovery.json`):

```json
{
  "x3000": ["ncn-m001", "ncn-w001", "ncn-w004", "ncn-w007", "ncn-s001"],
  "x3001": ["ncn-m002", "ncn-w002", "ncn-w006", "ncn-w005", "ncn-w008", "ncn-s003"],
  "x3002": ["ncn-m003", "ncn-w003", "ncn-w009", "ncn-s002", "ncn-s004"]
}
```

##### Stage 3 - Placement Validation

This ansible play uses the discovery results (`rr_hw_discovery.json`) from [Stage 2 - Placement Discovery](#stage-2---placement-discovery) and validates whether the current placement meets the required criteria for enabling rack resiliency.

![Management nodes placement validation](../../img/rack-resiliency-2.png)

The placement validation algorithm, as shown in the flow chart above, decides whether the current placement of management nodes is suitable for enabling rack resiliency. If it is found that the current placement is not suitable for rack resiliency, the validation fails.

This module also evaluates if managed nodes are present in the management rack and informational messages are generated for the same.

**Note**: [Slingshot](../../glossary.md#slingshot) switch placement discovery and validation is not included in this process.

##### Stage 4 - Kubernetes Zoning

This ansible play uses the discovery results (`rr_hw_discovery.json`) from [Stage 2 - Placement Discovery](#stage-2---placement-discovery) and applies kubernetes zoning for Master and Worker nodes.

##### Stage 5 - Apply Kyverno policy

This ansible play applies the kyverno clusterpolicy `insert-labels-topology-constraints`. To know more on kyverno policy refer to [kyverno policy](kyverno.md).

#### Setting up ceph zoning

The below stages are used to setup the ceph zones and update CEPH haproxy configuration required for RRS using Ansible plays: 

##### Stage 1 - Check enablement

[Refer to](#stage-1---check-enablement)

##### Stage 2 - Placement Discovery

[Refer to](#stage-2---placement-discovery)

##### Stage 3 - Placement Validation

[Refer to](#stage-3---placement-validation)

##### Stage 4 - Ceph Zoning

This ansible play uses the discovery results (`rr_hw_discovery.json`) from [Stage 2 - Placement Discovery](#stage-2---placement-discovery) and applies ceph zoning for storage nodes.

##### Stage 5 - Ceph HAproxy Configuration

This ansible play updates CEPH haproxy configuration with latest information after performing CEPH zoning and also updates ceph.conf on all storage nodes with latest configuration.

### Deploying helm charts for Rack Resiliency Service (RRS)

The RRS (Rack Resiliency Service) Helm chart includes both the RRS and the RMS (Resiliency Monitoring Service). The chart will be deployed automatically during the CSM install or upgrade process, provided that RR is enabled. Otherwise, the chart will not be deployed.
