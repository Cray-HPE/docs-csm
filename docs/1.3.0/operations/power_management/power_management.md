# Power Management

HPE Cray System Management \(CSM\) software manages and controls power out-of-band through Redfish APIs. Note that power management features are "asynchronous," in that the client must determine whether the component status has changed after a power management API call returns.

In-band power management features are not supported in v1.4.

HPE supports Slurm as a workload manager which reports job energy usage and records it in the ITDB for system accounting purposes.

### `sma-postgres-cluster`

A time-series PostgreSQL database \(`sma-postgres-cluster`\) contains the power telemetry data and tracks job start/end times, job-id, application-id, user-id, and application node allocation data. This data is made available through the System Monitoring Framework \(SMF\). Power monitoring and job data in `sma-postgres-cluster` enable out-of-band power profiling on the management nodes. Slurm interfaces with the PostgreSQL database through a plug-in.

### HPE Cray EX EX Systems

Cabinet-level power/energy data from compute blades, switch blades, and chassis rectifiers is collected by each Chassis Management Module \(CMM\) and provided on system management network. This power telemetry can be monitored by the SMF. Cabinet-level power data is collected and forwarded to the management nodes. The management nodes store the telemetry in the power management database.

### PM Counters

The blade-level and node-level accumulated energy telemetry is point-in-time power data. Blade accumulated energy data is collected out-of-band and is made available via workload managers. Users have access to the data in-band at the node-level via a special sysfs files in /sys/cray/pm\_counters on the node.

### HPE Cray EX Standard Rack Systems

Rack systems support 2 intelligent power distribution units \(iPDUs\). The power/energy telemetry, temperature, and humidity measurements \(supported by optional probes\), are accessible through the iPDU HTTP interface.

Node-level accumulated energy data is point-in-time power and accumulated energy data collected via Redfish through the server BMC.

