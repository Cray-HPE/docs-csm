# Delete CFS Sessions

Delete an existing Configuration Framework Service \(CFS\) configuration session with the CFS `delete` command.

## Prerequisites

This requires that the Cray command line interface is configured. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

## Delete single CFS session

Use the session name to delete the session:

```bash
ncn# cray cfs sessions delete <session_name>
```

No output is expected.

## Delete multiple CFS sessions

To delete all completed CFS sessions, use the `deleteall` command.

```bash
ncn# cray cfs sessions deleteall
```

This command can also filter the sessions to delete based on tags, name, status, age, and success or failure.
By default, if no other filter is specified, this command only deletes completed sessions.

## Delete old CFS sessions automatically

Completed CFS sessions can be automatically deleted based on age. See the [Automatic Session Deletion with `sessionTTL`](Automatic_Session_Deletion_with_sessionTTL.md) section.
