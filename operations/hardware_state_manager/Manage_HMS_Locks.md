## Manage HMS Locks

This section describes how to check the status of a lock, disable a lock, and repair a lock. It also describes some of the common scenarios an admin might encounter when working with the Hardware State Manager (HSM) Locking API.

### Check Lock Status

Use the following command to verify if an xname is locked or not. The command will show if its locked (admin), reserved (service command), or reservation disabled (either an EPO or an admin command).

The following shows how to interpret the output:

* Locked: Shows if the xname has been locked with the `cray hsm locks lock create` command.
* Reserved: Shows if the xname has been locked for a time-boxed event. Only service can reserve xnames; admins are not able to reserve xnames.
* ReservationDisable: Shows if the ability to reserved an xname has been changed by an EPO or admin command. 

```bash
ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = false
```


### Disable a Lock

Disabling a lock prevents a service from being able to make a reservation on it, and it releases/ends any current reservations. Even though SMD removes the reservation when disabling a lock, it does not mean that the Firmware Action Service (FAS) is aware that it has lost the reservation. 

This is a way to stop new operations from happening, not a way to prevent currently executing operations. 

```bash
ncn-m001# cray hsm locks disable create --component-ids x1003c5s2b1n1
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]
```

The following is an example of a when a lock is disabled:

```bash
ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = true
```

## Repair a Lock

Locks must be manually repaired after disabling a component or performing a manual EPO. This prevents the system from automatically re-issuing reservations or giving out lock requests.

```bash
ncn-m001# cray hsm locks repair create --component-ids x1003c5s2b1n1
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]
```

To verify if the lock was successfully repaired:

```bash
ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = false
```

## Scenario: What Happens to a Lock if a `disable` is Issued?

Before issuing a `disable` command, verify that a lock is already in effect:

```bash
ncn-m001# cray hsm locks lock create --component-ids x1003c5s2b1n1
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]

ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true
Reserved = false
ReservationDisabled = false
```

When attempting to disable, the lock will stay in effect, but the reservation ability will be disabled. For example:

``` bash
ncn-m001# cray hsm locks disable create --component-ids x1003c5s2b1n1
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]

ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true
Reserved = false
ReservationDisabled = true
```

## Scenario: Can a `lock` be Issued to a Currently Locked Component?

A lock cannot be issued to a component that is already locked. The following example shows a component that is already locked, and the returned error message when trying to lock the component again.

```bash
ncn-m001# cray hsm locks status create --component-ids x1003c5s2b1n1
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true  <<-- xname is locked
Reserved = false
ReservationDisabled = true


ncn-m001# cray hsm locks  lock create --component-ids x1003c5s2b1n1
Usage: cray hsm locks lock create [OPTIONS]
Try 'cray hsm locks lock create --help' for help.

Error: Bad Request: Component is Locked
```

