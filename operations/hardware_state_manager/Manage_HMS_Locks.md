# Manage HSM Locks

This section describes how to check the status of a lock, disable reservations, and repair reservations.
The disable and repair operations only affect the ability to make reservations on hardware devices.

Some of the common scenarios an admin might encounter when working with the
[Hardware State Manager (HSM) Locking API](Hardware_Management_Services_HMS_Locking_API.md) are also described.

The commands on this page require the Cray CLI to be configured.
See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

* [Creating a lock](#creating-a-lock)
* [Removing a lock](#removing-a-lock)
* [Check lock status](#check-lock-status)
* [Disable reservations](#disable-reservations)
* [Repair reservations](#repair-reservations)
* [Frequently asked questions](#frequently-asked-questions)
    * [What happens to a lock if a `disable` is issued?](#what-happens-to-a-lock-if-a-disable-is-issued)
    * [Can a lock be issued to a currently locked component?](#can-a-lock-be-issued-to-a-currently-locked-component)
* [Additional information](#additional-information)

## Creating a lock

(`ncn-mw#`) Create a lock on xname `x1003c5s2b1n1`.

```bash
cray hsm locks lock create --component-ids x1003c5s2b1n1 --format toml
```

Example of successful output:

```toml
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]
```

(`ncn-mw#`) Create a lock on xnames `"x3000c0s21b2n0` and `x3000c0s21b4n0`.

```bash
cray hsm locks lock create --component-ids "x3000c0s21b2n0,x3000c0s21b4n0" --format toml
```

Example of successful output:

```toml
Failure = []

[Counts]
Total = 2
Success = 2
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s21b2n0", "x3000c0s21b4n0",]
```

It is also possible to lock components based on other criteria, without specifying
individual xnames.

(`ncn-mw#`) See all of the possible options:

```bash
cray hsm locks lock create --help
```

## Removing a lock

(`ncn-mw#`) Remove the locks on xnames `"x3000c0s21b2n0` and `x3000c0s21b4n0`.

```bash
cray hsm locks unlock create --component-ids "x3000c0s21b2n0,x3000c0s21b4n0" --format toml
```

Example of successful output:

```toml
Failure = []

[Counts]
Total = 2
Success = 2
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s21b2n0", "x3000c0s21b4n0",]
```

It is also possible to unlock components based on other criteria, without specifying
individual xnames.

(`ncn-mw#`) See all of the possible options:

```bash
cray hsm locks unlock create --help
```

## Check lock status

Use the following command to verify if a component name (xname) is locked or not. The command will show
if it is locked (admin), reserved (service command), or reservation disabled (either an EPO or an admin
command).

The following shows how to interpret the output:

* `Locked`: Shows if the component name (xname) has been locked with the `cray hsm locks lock create` command.
* `Reserved`: Shows if the component name (xname) has been locked for a time-boxed event. Only service can reserve component names (xnames); administrators are not able to reserve component names (xnames).
* `ReservationDisable`: Shows if the ability to reserve a component name (xname) has been changed by an EPO or admin command.

```bash
cray hsm locks status create --component-ids x1003c5s2b1n1
```

Example output:

```text
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = false
```

## Disable reservations

Disabling a lock prevents a service from being able to make a reservation on it, and it releases/ends any
current reservations. Even though SMD removes the reservation when disabling a lock, it does not mean that
the Firmware Action Service (FAS) is aware that it has lost the reservation. Additionally, if PCS/CAPMC has
a reservation that is cancelled, disabled, or broken, it will do nothing to the existing PCS/CAPMC operation.
There are no checks by PCS/CAPMC to make sure things are still reserved at any time during a power operation.

This is a way to stop new operations from happening, not a way to prevent currently executing operations.

```bash
cray hsm locks disable create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
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
cray hsm locks status create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = true
```

## Repair reservations

Locks must be manually repaired after disabling a component or performing a manual EPO. This prevents the
system from automatically re-issuing reservations or giving out lock requests.

```bash
cray hsm locks repair create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
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
cray hsm locks status create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = false
Reserved = false
ReservationDisabled = false
```

## Frequently asked questions

### What happens to a lock if a `disable` is issued?

Before issuing a `disable` command, verify that a lock is already in effect:

```bash
cray hsm locks lock create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]
```

```bash
cray hsm locks status create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true
Reserved = false
ReservationDisabled = false
```

When attempting to disable, the lock will stay in effect, but the reservation ability will be disabled. For example:

```bash
cray hsm locks disable create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x1003c5s2b1n1",]
```

```bash
cray hsm locks status create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true
Reserved = false
ReservationDisabled = true
```

### Can a lock be issued to a currently locked component?

A lock cannot be issued to a component that is already locked. The following example shows a component that is already
locked, and the returned error message when trying to lock the component again.

```bash
cray hsm locks status create --component-ids x1003c5s2b1n1 --format toml
```

Example output:

```toml
NotFound = []
[[Components]]
ID = "x1003c5s2b1n1"
Locked = true
Reserved = false
ReservationDisabled = true
```

> Note in the above output that the xname is locked.

```bash
cray hsm locks lock create --component-ids x1003c5s2b1n1
```

Example output:

```text
Usage: cray hsm locks lock create [OPTIONS]
Try 'cray hsm locks lock create --help' for help.

Error: Bad Request: Component is Locked
```

## Additional information

* [HSM Locking API](Hardware_Management_Services_HMS_Locking_API.md)
* [Lock and Unlock Management Nodes](Lock_and_Unlock_Management_Nodes.md)
* [BOS v2 sessions and HSM locks](../boot_orchestration/Sessions.md#bos-v2-sessions-and-hsm-locks)
* [HSM API specification](../../api/smd.md)
