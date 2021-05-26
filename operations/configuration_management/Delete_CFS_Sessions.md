## Delete CFS Sessions

Describes how to use the Cray CLI to delete an existing configuration session.

Delete a Configuration Framework Service \(CFS\) session with the CFS delete command. Use the session name to delete the session:

```bash
ncn# cray cfs sessions delete example
<no output expected>
```

To delete all completed CFS sessions, use the deleteall command. This command can also filter the sessions to delete based on tags, name, status, age, and success or failure. By default, if no other filter is specified, this command only deletes completed sessions.

<<<<<<< HEAD
<<<<<<< HEAD
Completed CFS sessions can also be automatically deleted based on age. See the [Automatic Session Deletion with sessionTTL](Automaitc_Session_Deletion_with_sessionTTL.md) section.
=======
Completed CFS sessions can also be automatically deleted based on age. See the [Automatic Session Deletion with sessionTTL](/portal/developer-portal/operations/Automaitc_Session_Deletion_with_sessionTTL.md) section.
>>>>>>> 269058d (STP-2624: imported several files from the admin guide)
=======
Completed CFS sessions can also be automatically deleted based on age. See the [Automatic Session Deletion with sessionTTL](Automaitc_Session_Deletion_with_sessionTTL.md) section.
>>>>>>> f416af2 (STP-2624: formatting changes)



