# API Authorization

Authorization for REST API calls is only done at the API gateway. This is facilitated through policy checks to the Open Policy Agent \(OPA\).
Every REST API call into the system is sent to the OPA to make an authorization decision.
The decision is based on the authenticated [JSON Web Token (JWT)](../../glossary.md#json-web-token-jwt) passed into the request.

This page lists the available personas and the supported REST API endpoints for each.

- [`admin`](#admin)
- [`user`](#user)
- [`system-pxe`](#system-pxe)
- [`system-compute`](#system-compute)
- [`wlm`](#wlm)

## `admin`

Authorized for every possible REST API endpoint.

## `user`

**NOTE:** UAS and User Access Instances are deprecated in CSM 1.5.2 and will be removed in CSM 1.6.

Authorized for a subset of endpoints to allow users to create and use [User Access Instances (UAIs)](../../glossary.md#user-access-instance-uai),
run jobs, view job results, and use capsules.

- [`user` UAS endpoints](#user-uas-endpoints)
- [`user` PALS endpoints](#user-pals-endpoints)
- [`user` Replicant endpoints](#user-replicant-endpoints)
- [`user` Analytics Capsules endpoints](#user-analytics-capsules-endpoints)

### `user` UAS endpoints

REST API endpoints for the `user` persona for the [User Access Service (UAS)](../../glossary.md#user-access-service-uas):

| Method   | Endpoint                    | Description |
| -------- | --------------------------- | ----------- |
| `GET`    | `/apis/uas-mgr/v1/`         | Get UAS API version |
| `GET`    | `/apis/uas-mgr/v1/uas`      | List UAIs for current user |
| `POST`   | `/apis/uas-mgr/v1/uas`      | Create a UAI for current user |
| `DELETE` | `/apis/uas-mgr/v1/uas`      | Delete UAIs for current user |
| `GET`    | `/apis/uas-mgr/v1/images`   | List available UAI images |
| `GET`    | `/apis/uas-mgr/v1/mgr-info` | Get UAS service version |

### `user` PALS endpoints

The `user` persona is authorized to make `DELETE`, `GET`, `HEAD`, `PATCH`, `POST` or `PUT` calls to any
[Parallel Application Launch Service (PALS)](../../glossary.md#parallel-application-launch-service-pals) endpoint (`/apis/pals/v1/*`).

### `user` Replicant endpoints

REST API endpoints for the `user` persona for Replicant:

| Method   | Endpoint                    | Description |
| -------- | --------------------------- | ----------- |
| `GET`    | `/apis/rm/v1/report/<id>`   | Get report by ID |
| `GET`    | `/apis/rm/v1/reports`       | Get reports |

### `user` Analytics Capsules endpoints

The `user` persona is authorized to make `DELETE`, `GET`, `HEAD`, `PATCH`, `POST` or `PUT` calls to any Analytics Capsules endpoint (`/apis/capsules/*`).

## `system-pxe`

Authorized for endpoints related to booting.

The `system-pxe` persona is authorized to make `GET`, `HEAD`, or `POST` calls to any [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) endpoint (`/apis/bss/*`).

## `system-compute`

Authorized for endpoints required by the [Cray Operating System (COS)](../../glossary.md#cray-operating-system-cos) to manage compute nodes and NCN services.

The `system-compute` persona is authorized to make:

- `GET`, `HEAD`, or `PATCH` calls to any [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) endpoint (`/apis/cfs/*`).
- `GET`, `HEAD`, or `POST` calls to any [Content Projection Service (CPS)](../../glossary.md#content-projection-service-cps) endpoint (`/apis/v2/cps/*`).
- `GET`, `HEAD`, or `POST` calls to any [Heartbeat Tracker Daemon (HBTD)](../../glossary.md#heartbeat-tracker-daemon-hbtd) endpoint (`/apis/hbtd/*`).
- `GET`, `HEAD`, `POST`, or `PUT` calls to any [Node Memory Dump (NMD)](../../glossary.md#node-memory-dump-nmd) endpoint (`/apis/v2/nmd/*`).
- `GET` or `HEAD` calls to any [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) endpoint (`/apis/smd/*`).
- `DELETE`, `GET`, `HEAD`, `PATCH`, or `POST` calls to any
  [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd) endpoint (`apis/hmnfd/*`).

## `wlm`

Authorized for endpoints related to the use of the Slurm or PBS workload managers.

The `wlm` persona is authorized to make:

- `DELETE`, `GET`, `HEAD`, or `POST` calls to any PALS endpoint (`/apis/pals/*`).
- `GET`, `HEAD`, or `POST` calls to any [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
  endpoint (`/apis/capmc/*`).
- `DELETE`, `GET`, `HEAD`, `PATCH`, or `POST` calls to any [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) endpoint (`/apis/bos/*`).
- `GET` or `HEAD` calls to any [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) endpoint (`/apis/sls/*`).
- `GET` or `HEAD` calls to any HSM endpoint (`/apis/smd/*`).
- `DELETE`, `GET`, `HEAD`, `PATCH`, `POST` or `PUT` calls to any [Virtual Network Identifier Daemon (VNID)](../../glossary.md#virtual-network-identifier-daemon-vnid)
  endpoint (`/apis/vnid/*`).
