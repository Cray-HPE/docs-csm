# Backing up switch configuration

Backing up current configuration of the switch in text format
Example

To create a new text-based configuration file, complete the following steps:

Log in to the switch as Admin.

Type the following command:

```
switch (config) # configuration text generate active running save my-filename
```

To upload a text-based configuration file from a switch to an external file server, complete the following steps:

```
switch (config) # configuration text file my-filename upload 
scp://root@my-server/root/tmp/my-filename 
```

[Back to Index](./index.md)