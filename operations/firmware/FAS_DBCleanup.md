# Cleaning up FAS Database

FAS stores actions along with all of its operations and snapshots in the database.
To clean these actions and snapshots use the following scripts.

## Prerequisites

Cray CLI installed and configured.

## `FASrmActions.sh`

Removes FAS actions from database greater than number of days ago.

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASrmActions.sh num_of_days [-y]
```

Parameters:

- `num_of_days` - the number of days to keep actions (all actions older will be deleted) (required)
- `-y` - optional parameter - adding the -y will skip the confirmation prompt

Example - This will remove actions > 50 days ago: (`ncn-mw#`)

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASrmActions.sh 50
```

Expected output:

```text
FAS Actions before 2024-08-07:
13c336d6-d090-4b21-855e-41603d42476e 69288a53-3d4e-48a8-bdaa-3310b279033f f2bfb5ef-d332-4e1a-88a6-b8a606f616b2
-----------------------
Actions to be removed:
13c336d6-d090-4b21-855e-41603d42476e,2024-07-30 18:11:44.976172732 +0000 UTC,Upgrade of Node BIOS -- Dryrun 07/30/2024 18:11:23,14
69288a53-3d4e-48a8-bdaa-3310b279033f,2024-07-30 20:09:56.254527556 +0000 UTC,Upgrade of Node BIOS -- Dryrun 07/30/2024 20:09:37,14
f2bfb5ef-d332-4e1a-88a6-b8a606f616b2,2024-07-31 15:58:12.848910552 +0000 UTC,Upgrade of Node BIOS -- Dryrun 07/31/2024 15:57:52,14
-----------------------
Continue to remove 3 FAS actions? y
Removing: 13c336d6-d090-4b21-855e-41603d42476e

Removing: 69288a53-3d4e-48a8-bdaa-3310b279033f

Removing: f2bfb5ef-d332-4e1a-88a6-b8a606f616b2
```

## `FASrmSnapshots.sh`

Removes FAS snapshots from database greater than number of days ago.

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASrmSnapshots.sh num_of_days [-y]
```

Parameters:

- `num_of_days` - the number of days to keep snapshots (all snapshots older will be deleted) (required)
- `-y` - optional parameter - adding the -y will skip the confirmation prompt

Example - This will remove snapshots > 30 days ago: (`ncn-mw#`)

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASrmSnapshots.sh 30
```

Expected output:

```text
FAS Snapshots before 2024-08-27:
snapshot_08192024.1 snapshot_08192024.2 snapshot_08192024.3 snapshot_08192024.4 snapshot_08192024.5 snapshot_08192024.6 testsnapshot
-------------------------
Snapshots to be removed:
snapshot_08192024.1,2024-08-19 20:42:47.060050059 +0000 UTC
snapshot_08192024.2,2024-08-19 20:44:45.290255555 +0000 UTC
snapshot_08192024.3,2024-08-19 20:45:27.590469268 +0000 UTC
snapshot_08192024.4,2024-08-19 20:47:18.490428941 +0000 UTC
snapshot_08192024.5,2024-08-19 20:47:39.479192236 +0000 UTC
snapshot_08192024.6,2024-08-19 20:48:18.168322841 +0000 UTC
testsnapshot,2024-08-19 21:14:00.78474315 +0000 UTC
-----------------------
Continue to remove 7 FAS snapshots? y
Removing: snapshot_08192024.1

Removing: snapshot_08192024.2

Removing: snapshot_08192024.3

Removing: snapshot_08192024.4

Removing: snapshot_08192024.5

Removing: snapshot_08192024.6

Removing: testsnapshot
```
