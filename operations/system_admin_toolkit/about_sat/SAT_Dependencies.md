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

- System Configuration Service (SCSD)

## `sat bootprep`

CSM dependencies:

- Boot Orchestration Service (BOS)
- Configuration Framework Service (CFS)
- Image Management Service (IMS)
- Version Control Service (VCS)
- Kubernetes
- S3

## `sat bootsys`

CSM dependencies:

- Boot Orchestration Service (BOS)
- Cray Advanced Platform Monitoring and Control (CAPMC)
- Ceph
- Etcd
- Firmware Action Service (FAS)
- Hardware State Manager (HSM)
- Kubernetes
- S3

HPE Cray Supercomputing Compute Node Software Environment dependencies:

- Node Memory Dump (NMD)

## `sat diag`

CSM dependencies:

- Hardware State Manager (HSM)

CSM Diagnostics dependencies:

- Fox

## `sat firmware`

CSM dependencies:

- Firmware Action Service (FAS)

## `sat hwhist`

CSM dependencies:

- Hardware State Manager (HSM)

## `sat hwinv`

CSM dependencies:

- Hardware State Manager (HSM)

## `sat hwmatch`

CSM dependencies:

- Hardware State Manager (HSM)

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

- Hardware State Manager (HSM)

## `sat sensors`

CSM dependencies:

- Hardware State Manager (HSM)
- HM Collector

SMA dependencies:

- Telemetry API

## `sat setrev`

CSM dependencies:

- S3

## `sat showrev`

CSM dependencies:

- Hardware State Manager (HSM)
- Kubernetes
- S3

## `sat slscheck`

CSM dependencies:

- Hardware State Manager (HSM)
- System Layout Service (SLS)

## `sat status`

CSM dependencies:

- Boot Orchestration Service (BOS)
- Configuration Framework Service (CFS)
- Hardware State Manager (HSM)
- Image Management Service (IMS)
- System Layout Service (SLS)

## `sat swap`

Slingshot dependencies:

- Fabric Manager

## `sat switch`

*Deprecated*: See `sat swap`

## `sat xname2nid`

CSM dependencies:

- Hardware State Manager (HSM)
