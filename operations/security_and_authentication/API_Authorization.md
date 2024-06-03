# API Authorization

Authorization for REST API calls is only done at the API gateway. This is facilitated through policy checks to the Open Policy Agent \(OPA\).
Every REST API call into the system is sent to the OPA to make an authorization decision.
The decision is based on the authenticated [JSON Web Token (JWT)](../../glossary.md#json-web-token-jwt) passed into the request.

This page lists the available personas and the supported REST API endpoints for each.

- [`admin`](#admin)
- [`system-pxe`](#system-pxe)
- [`system-compute`](#system-compute)
- [`wlm`](#wlm)

## `admin`

Authorized for every possible REST API endpoint.

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
