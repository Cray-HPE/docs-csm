# SAT Dependencies

Most `sat` subcommands depend on services or components from CSM or from other
products in the HPE Cray EX software stack. The following list shows these
dependencies for each subcommand. Each service or component is listed under the
product it belongs to.

## `sat auth`

CSM dependencies:

- Keycloak

## `sat bmccreds`

CSM dependencies:

- [System Configuration Service (SCSD)](../../../glossary.md#system-configuration-service-scsd)

## `sat bootprep`

CSM dependencies:

- [Boot Orchestration Service (BOS)](../../../glossary.md#boot-orchestration-service-bos)
- [Configuration Framework Service (CFS)](../../../glossary.md#configuration-framework-service-cfs)
- [Image Management Service (IMS)](../../../glossary.md#image-management-service-ims)
- [Version Control Service (VCS)](../../../glossary.md#version-control-service-vcs)
- Kubernetes
- [Simple Storage Service (S3)](../../../glossary.md#simple-storage-service-s3)

## `sat bootsys`

CSM dependencies:

- [Boot Orchestration Service (BOS)](../../../glossary.md#boot-orchestration-service-bos)
- [Power Control Service (PCS)](../../../glossary.md#power-control-service-pcs)
- Ceph
- Etcd
- [Firmware Action Service (FAS)](../../../glossary.md#firmware-action-service-fas)
- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- Kubernetes
- [Simple Storage Service (S3)](../../../glossary.md#simple-storage-service-s3)

HPE Cray Supercomputing [User Services Software (USS)](../../../glossary.md#user-services-software-uss) dependencies:

- [Node Memory Dump (NMD)](../../../glossary.md#node-memory-dump-nmd)

## `sat diag`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)

CSM Diagnostics dependencies:

- Fox

## `sat firmware`

CSM dependencies:

- [Firmware Action Service (FAS)](../../../glossary.md#firmware-action-service-fas)

## `sat hwhist`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)

## `sat hwinv`

CSM dependencies:

- H[Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)

## `sat hwmatch`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)

## `sat init`

None

## `sat jobstat`

PBS dependencies:

- HPE State Checker

## `sat k8s`

CSM dependencies:

- Kubernetes

## `sat nid2xname`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)

## `sat sensors`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- HM Collector

[System Monitoring Application (SMA)](../../../glossary.md#system-monitoring-application-sma) dependencies:

- Telemetry API

## `sat setrev`

CSM dependencies:

- [Simple Storage Service (S3)](../../../glossary.md#simple-storage-service-s3)

## `sat showrev`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- Kubernetes
- [Simple Storage Service (S3)](../../../glossary.md#simple-storage-service-s3)

## `sat slscheck`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- [System Layout Service (SLS)](../../../glossary.md#system-layout-service-sls)

## `sat status`

CSM dependencies:

- [Boot Orchestration Service (BOS)](../../../glossary.md#boot-orchestration-service-bos)
- [Configuration Framework Service (CFS)](../../../glossary.md#configuration-framework-service-cfs)
- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- [Image Management Service (IMS)](../../../glossary.md#image-management-service-ims)
- [System Layout Service (SLS)](../../../glossary.md#system-layout-service-sls)

## `sat swap`

### `sat swap blade`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
- Kubernetes
- [Power Control Service (PCS)](../../../glossary.md#power-control-service-pcs)

### `sat swap cable` and `sat swap switch`

**DEPRECATED:** For more information, see [Deprecated in CSM 1.6](../../../introduction/deprecated_features/README.md).

Slingshot dependencies:

- Fabric Manager

## `sat switch`

**DEPRECATED:** Instead, see [`sat swap`](#sat-swap).

## `sat xname2nid`

CSM dependencies:

- [Hardware State Manager (HSM)](../../../glossary.md#hardware-state-manager-hsm)
