# BOS database

* [Overview](#overview)
* [Source](#source)

## Overview

(`ncn-mw#`) All BOS data is stored in a Redis database running in a pod in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME                           READY   STATUS    RESTARTS   AGE
cray-bos-db-58f4967657-rdj9l   2/2     Running   0          70d
```

## Source

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
