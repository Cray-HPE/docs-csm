# User Access to Compute Node Power Data

Shasta Liquid Cooled AMD EPYC compute node power management data available to users.

Shasta Liquid Cooled compute blade power management counters (`pm_counters`) enable user access to energy usage over time for billing and job profiling.

The blade-level and node-level accumulated energy telemetry is point-in-time power data.
Blade accumulated energy data is collected out-of-band and is made available via workload managers.
Users have access to the data in-band at the node-level via a special `sysfs` files in `/sys/cray/pm_counters` on the node.

Time-stamped energy data from each node can be captured for a specific job before, during, and after the job to generate a power profile about the job.
This energy usage data can be used in conjunction with current energy costs to assign a monetary value to the job.

The node CPU vendor provides specific in-band and out-of-band interfaces for controlling power management.
In-band interfaces are accessed from the node OS through `/sys/cray/pm_counters`.
Out-of-band interfaces are accessed from a node BMC or Redfish API.

Note that each node has a power supply that can support a fixed number of Watts.
The combined power consumption of the CPU and the accelerator can never exceed this limit, thus, power to either the CPU or the accelerator must be capped so
as not to exceed the total amount of power available.

## `pm_counters`

Access to compute node power and energy data is provided by a set of files located in `/sys/cray/pm_counters/` on the node.
All `pm_counters` are accompanied by a timestamp.

| File            | Description                                                                                                                                       |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `power`         | Point-in-time power (Watts). When accelerators are present, includes `accel_power`. See limitation below on data collection from accelerators.    |
| `energy`        | Accumulated energy, in joules. When accelerators are present, includes `accel_energy`. See limitation below on data collection from accelerators. |
| `cpu_power`     | Point-in-time power (Watts) used by the CPU domain.                                                                                               |
| `cpu_energy`    | The total energy (Joules) used by the CPU domain.                                                                                                 |
| `cpu_temp`      | Temperature reading (Celsius) of the CPU domain.                                                                                                  |
| `memory_power`  | Point-in-time power (Watts) used by the memory domain.                                                                                            |
| `memory_energy` | The total energy (Joules) used by the memory domain.                                                                                              |
| `accel_energy`  | Accumulated accelerator energy (Joules). The data is non-zero only when an accelerator is present on the node.                                    |
| `accel_power`   | Accelerator point-in-time power (Watts). The data is non-zero only when an accelerator is present on the node.                                    |
| `generation`    | A counter that increments each time a power cap value is changed.                                                                                 |
| `startup`       | Startup counter.                                                                                                                                  |
| `freshness`     | Free-running counter that increments at a rate of approximately 10Hz.                                                                             |
| `version`       | Version number for power management counter support.                                                                                              |
| `power_cap`     | Current power cap limit in Watts; 0 indicates no capping. When accelerators are present, includes `accel_power_cap`.                              |
| `raw_scan_hz`   | The power management scanning rate for all data in `pm_counters`.                                                                                 |
