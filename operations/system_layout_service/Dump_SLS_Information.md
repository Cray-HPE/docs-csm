# Dump SLS Information

Perform a dump of the System Layout Service \(SLS\) database.

This procedure will create the file `sls_dump.json` in the current directory.

This procedure preserves the information stored in SLS when backing up or reinstalling the system.

## Prerequisites

- The Cray Command Line Interface is configured. See [Configure the Cray CLI](../configure_cray_cli.md).
- This procedure requires administrative privileges.

## Procedure

(`ncn-mw#`) Perform the SLS dump.
The SLS dump will be stored in the `sls_dump.json` file. The `sls_dump.json` file is required to perform the SLS load state operation.

```bash
cray sls dumpstate list --format json > sls_dump.json
```
