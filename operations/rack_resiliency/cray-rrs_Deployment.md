# `cray-rrs` Deployment

`cray-rrs` is the name of the RRS (Rack Resiliency Service) Helm chart. The chart includes both the API and the RMS (Resiliency Monitoring Service),
along with two `init` containers. The chart is deployed in the `rack-resiliency` namespace automatically during the CSM install
or upgrade process.

## Containers

The service includes the following containers:

- `init` containers:
    - `cray-rrs-check`: This checks if Rack Resiliency is enabled and if zones for Kubernetes and Ceph have been provisioned.
    - `cray-rrs-init`: This validates the configuration parameters and initializes the environment required to begin the monitoring of critical services.
- `cray-rrs-api`: This serves the endpoints for the RESTful APIs of RRS.
- `cray-rrs-rms`: This is the core engine of the `cray-rrs` pod. This monitors the critical services and alerts the administrator when thresholds are not met.

## `Kyverno` policy

The RRS Helm chart also includes a `Kyverno` policy named `insert-labels-topology-constraints`. For more information, see [Kyverno Policy](Kyverno_Policy.md).
