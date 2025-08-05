# Deploying helm charts for Rack Resiliency Service (RRS)

The RRS (Rack Resiliency Service) Helm chart includes both the API and the RMS (Resiliency Monitoring Service) along with two init containers. The chart is deployed in the rack-resiliency namespace automatically during the CSM install or upgrade process, provided RR is enabled. Otherwise, the chart will not be deployed.

## Service details

The service constitutes the following containers:

* init containers:
  * `cray-rrs-check`: This checks if Rack Resiliency is enabled and zones for kubernetes ad ceph have been provisioned.
  * `cray-rrs-init`: This validates the configuration parameters and initializes the environment required to begin the  monitoring of critical services.
* `cray-rrs-api`: This serves the endpoints for the RESTful APIS of RRS.
* `cray-rrs-rms`: This is the core engine of `cray-rrs` pod. This monitors the critical services and alerts the administrator when thresholds are not met.
