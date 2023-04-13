# Slurm Service Recovery

The following covers restoring Slurm data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.

## Service recovery for Slurm

To restore Slurm data from backup, follow sections
*10.3.11 Restore Slurm Accounting Database from Backup* and
*10.3.13 Restore Slurm Spool Directory from Backup* in the
**HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems (S-8003)**.

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
