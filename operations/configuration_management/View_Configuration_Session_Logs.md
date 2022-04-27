# View Configuration Session Logs

Logs for the individual steps of a session are available via the kubectl log command for each container of a Configuration Framework Service \(CFS\) session. Refer to [Configuration Sessions](Configuration_Sessions.md) for more info about these containers.

To find the name of the Kubernetes pod that is running the CFS session:

```bash
ncn# kubectl get pods --no-headers -o \
custom-columns=":metadata.name" -n services -l cfsession=example
cfs-f9d18751-e6d1-4326-bf76-434293a7b1c5-q8tsc
```

Store the returned pod name as the `CFS_POD_NAME` variable for future use:

```bash
ncn# export CFS_POD_NAME=cfs-f9d18751-e6d1-4326-bf76-434293a7b1c5-q8tsc
```

Alternatively, if the session is one of many recent sessions and the session name is not known, it is possible to list all CFS pods by start time and pick the desired pod based on status or start time:

```bash
ncn# kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
cfs-47bed8b5-e1b1-4dd7-b71c-40e9750d3183-7msmr                 0/7     Completed   0          36m
cfs-0675d19f-5bec-424a-b0e1-9d466299aff5-dtwhl                 0/7     Error       0          5m25s
cfs-f49af8e9-b8ab-4cbb-a4f6-febe519ef65f-nw76v                 0/7     Error       0          4m14s
cfs-31635b42-6d03-4972-9eba-b011baf9c5c2-jmdjx                 6/7     NotReady    0          3m33s
cfs-b9f50fbe-04de-4d9a-b5eb-c75d2d561221-dhgg6                 6/7     NotReady    0          2m10s
```

To view the logs of the various containers:

```bash
ncn# kubectl logs -n services ${CFS_POD_NAME} -c ${CONTAINER_NAME}
```

The `${CONTAINER_NAME}` value is one of the containers mentioned in [Configuration Sessions](Configuration_Sessions.md). Depending on the number of configuration layers in the session, some sessions will have more containers available. Use the `-f` option in the previous command to follow the logs if the session is still running.

To view the Ansible logs, determine which configuration layer's logs to view from the order of the configuration set in the session. For example, if it is the first layer, the `${CONTAINER_NAME}` will be `ansible-0`.

```bash
ncn# kubectl logs -n services ${CFS_POD_NAME} -c ansible-0
```

The `git-clone-#` and `ansible-#` containers may not start at 0 and may not be numbered sequentially if the session was created with the `--configuration-limit` option.

