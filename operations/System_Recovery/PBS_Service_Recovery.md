# PBS Service Recovery

The following covers restoring PBS data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.

## Service recovery for PBS

To restore PBS Professional data from backup, follow section
*10.7.7 Restore PBS home directory from backup* in the
**HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems (S-8003)**.

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
