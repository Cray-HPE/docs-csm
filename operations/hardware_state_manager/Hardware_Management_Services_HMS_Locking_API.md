# Hardware Management Services \(HMS\) Locking API

The locking feature is a part of the Hardware State Manager \(HSM\) API. The locking API enables administrators to
lock components on the system. Locking components ensures other system actors, such as administrators or running
services, cannot perform a firmware update with the Firmware Action Service \(FAS\) or a power state change with the
Power Control Service (PCS) or the Cray Advanced Platform Monitoring and Control \(CAPMC\). Locks only constrain FAS
and PCS/CAPMC from each other and help ensure that a firmware update action will not be interfered with by a request
to power off the device through PCS/CAPMC. Locks only work with HMS services and will not impact other system services.

Locks can only be used to prevent actions firmware updates with FAS or power state changes with PCS/CAPMC.
Administrators can still use HMS APIs to view the state of various hardware components on the system, even if a lock
is in place. There is no automatic locking for hardware devices. Locks need to be manually set or unset by an admin.
A scenario that might be encountered is when a larger hardware state change job is run, and one of the components in
the job has a lock on it. If FAS is the service running the job, FAS will attempt to update the firmware on each
component, and will update all devices that do not have a lock on it. The job will not complete until the node lock
ends, or if a timeout is set for the job.

The locking API also includes actions to repair or disable a node's locking ability with respect to HMS services. The
disable function will make it so a device cannot be firmware updated or power controlled \(via an HMS service\) until
a repair is done. Future requests to perform a firmware update via FAS or power state change via PCS/CAPMC cannot be
made on that component until the repair action is used.

**WARNING:** System administrators should **LOCK** NCNs after the system has been brought up to prevent an admin from
unintentionally firmware updating or powering off an NCN. If this lock is not engaged, an authorized request to FAS or
PCS/CAPMC could power off the NCNs, which will negatively impact system stability and the health of services running
on those NCNs.
