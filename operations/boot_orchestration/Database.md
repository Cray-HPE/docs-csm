# BOS database

* [Overview](#overview)
* [Data organization](#data-organization)
* [Access](#access)
* [Source](#source)

## Overview

(`ncn-mw#`) All BOS data is stored in Redis databases running in a pod in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME                           READY   STATUS    RESTARTS   AGE
cray-bos-db-58f4967657-rdj9l   2/2     Running   0          70d
```

## Data organization

Within the Redis pod, the BOS data is divided into 6 databases:

| *Database*                                                                 | *Key*                                                               |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [Components](Components.md)                                                | Node xname                                                          |
| Boot artifacts (`initrd`, kernel, and kernel parameters)                   | [BSS](../../glossary.md#boot-script-service-bss) token              |
| [Options](Options.md)                                                      | `options`                                                           |
| [Session templates](Session_Templates.md)                                  | Hash based on [tenant](Multi_tenancy_with_BOS.md) and template name |
| [Sessions](Sessions.md)                                                    | Hash based on [tenant](Multi_tenancy_with_BOS.md) and session name  |
| [Session statuses](View_the_Status_of_a_BOS_Session.md#bos-session-status) | Hash based on [tenant](Multi_tenancy_with_BOS.md) and session name  |

* The options database has a single entry with a fixed key. This entry contains a dictionary of current BOS option values.
* BOS sessions and session templates are [name-spaced by tenant](Multi_tenancy_with_BOS.md#tenant-name-spacing),
  which requires their corresponding database keys to include the tenant information.

## Access

All access to the BOS databases is done by the [BOS API server](API.md), with a single exception;
The [`power-on` operator](Operators.md#power-on) directly writes to the boot artifacts database.

## Source

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
