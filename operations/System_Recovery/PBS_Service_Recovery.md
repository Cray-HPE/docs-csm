# PBS Service Recovery

The following covers restoring PBS data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.

## Service recovery for PBS

To restore Portable Batch System data from a backup, see *Restore PBS home directory from a backup* in the
**HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray EX Systems (S-8063)**.

After restoring PBS data from backup, check that the procedure was successful.

1. (`uan#`) Check that accounting records were successfully restored.

   ```bash
   qstat -x
   ```

1. (`uan#`) Check that queued jobs were successfully restored.

   ```bash
   qstat
   ```

1. (`uan#`) Check that node states were successfully restored.

   ```bash
   pbsnodes -a
   ```
