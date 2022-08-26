# Load SLS Database with Dump File

Load the contents of the SLS dump file to restore SLS to the state of the system at the time of the dump. This will upload and overwrite the current SLS database with the contents of the SLS dump file.

Use this procedure to restore SLS data after a system re-install.

## Prerequisites

- The System Layout Service \(SLS\) database has been dumped. See [Dump SLS Information](Dump_SLS_Information.md) for more information.
- The Cray Command Line Interface is configured. See [Configure the Cray CLI](../configure_cray_cli.md).
- This procedure requires administrative privileges.

## Procedure

(`ncn-mw#`) Load the dump file into SLS.
This will upload and overwrite the current SLS database with the contents of the posted file.

```bash
cray sls loadstate create sls_dump.json
```
