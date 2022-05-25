# Delete CFS Sessions

Delete an existing Configuration Framework Service \(CFS\) configuration session with the CFS `delete` command.

Use the session name to delete the session:

```bash
ncn# cray cfs sessions delete example
```

No output is expected.

To delete all completed CFS sessions, use the `deleteall` command. This command can also filter the sessions to delete based on tags, name, status, age, and success or failure. By default, if no other filter is specified, this command only deletes completed sessions.

Completed CFS sessions can also be automatically deleted based on age. See the [Automatic Session Deletion with sessionTTL](Automatic_Session_Deletion_with_sessionTTL.md) section.

