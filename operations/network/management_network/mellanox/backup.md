# Backing Up A Switch Configuration

This document describes how to back up the current configuration of the switch in text format.

## Back up configuration

(`switch (config) #`) Save the configuration to a text file.

```console
configuration text generate active running save my-filename
```

## Copy configuration to external location

(`switch (config) #`) To upload a text-based configuration file from a switch to an external file server,
run the following command:

```console
configuration text file my-filename upload scp://root@my-server/root/tmp/my-filename
```

[Back to Index](../README.md)
