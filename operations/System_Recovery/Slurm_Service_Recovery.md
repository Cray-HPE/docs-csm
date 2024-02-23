# Slurm Service Recovery

The following covers restoring Slurm data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.

## Service recovery for Slurm

To restore Slurm data from a backup, see
*Restore Slurm accounting database from a backup* and
*Restore Slurm spool directory from a backup* in the
**HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray EX Systems (S-8063)**.

After restoring Slurm data from backup, check that the procedure was successful.

1. (`uan#`) Check that accounting records were successfully restored. Use a start date from before the backup was taken.

   ```bash
   sacct -a -S <date>
   ```

1. (`uan#`) Check that the job queue was successfully restored.

    ```bash
   squeue
   ```

1. (`uan#`) Check that node states were successfully restored.

   ```bash
   sinfo
   sinfo --list-reasons
   ```
