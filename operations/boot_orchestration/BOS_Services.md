# BOS Options

The Boot Orchestration Service \(BOS\) consists of many different micro-services and other components, including the API, operators and `bos-state-reporter`.

## The BOS API

The API is the point of contact for the user and all other services, including BOS' own services, that want to query or update BOS data.

## The Boot Orchestration Agent \(BOA\)

BOA is a feature of BOS v1 only. It is a Kubernetes job that is responsible for tracking all of the components in a BOS session and taking actions against them.

## The BOS operators

The BOS operators are a v2 feature only.
Rather than relying on a single actor to handle all components and actions, the actions are broken up against several operators that monitor for components that require a specific action and handle only those components.

### The `actual-state-cleanup` operator

This operator clears the `actual_state` field for components when the field has not been updated with the `component_actual_state_ttl` time.
This ensures that BOS keeps accurate information on the state of all components.
See [Options](Options.md) for more information on setting `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.

### The `configuration` operator

This operator is responsible for setting the desired configuration in CFS for components that are in the `configuring` phase of the boot process.
Because the `power-on` operator sets the desired configuration prior to booting components, this is typically only needed when booting to the same boot artifacts, but with a different configuration.

### The `discovery` operator

This operator periodically checks with HSM to discover new components and create the component records for BOS.

### The `power-off-forceful` operator

This operator calls CAPMC to forcefully power off components when a previous power off action fails to power off the component.

### The `power-off-graceful` operator

This operator calls CAPMC to gracefully power off components for components that have a `power-off-pending` status.

### The `power-on` operator

This operator calls CAPMC to power on components for components that have a `power-on-pending` status.

### The `session-cleanup` operator

This operator deletes session from BOS that are older than the `cleanup_completed_session_ttl` value.

### The `session-completion` operator

This operator marks sessions as complete and saves a final status for the session when all components that a session is responsible for have been disabled.

### The `session-setup` operator

This operator monitors for pending sessions, and translates the session template into a list of components and the boot artifacts and configuration to be set as the desired state for those components.

### The `status` operator

This operator monitors all components that are enabled in BOS and sets their `phase` based on the components desired and current state in BOS, the components power state as reported by HSM, and the component's configuration status as reported by CFS.

## The BOS state reporter

The `bos-state-reporter` is a v2 feature only.  It runs on all components managed by BOS and periodically reports back the actual state of the component it runs on.  This is installed as a package at image customization time.
    See [Options](Options.md) for more information on setting `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.
