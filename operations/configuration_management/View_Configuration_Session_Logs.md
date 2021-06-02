## View Configuration Session Logs

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

To view the logs of the various containers:

```bash
ncn# kubectl logs -n services ${CFS_POD_NAME} -c ${CONTAINER_NAME}
```

The `${CONTAINER_NAME}` value is one of the containers mentioned in [Configuration Sessions](Configuration_Sessions.md). Depending on the number of configuration layers in the session, some sessions will have more containers available. Use the -f option in the previous command to follow the logs if the session is still running.

To view the Ansible logs, determine which configuration layer’s logs to view from the order of the configuration set in the session. For example, if it is the first layer, the `${CONTAINER_NAME}` will be `ansible-0`.

```bash
ncn# kubectl logs -n services ${CFS_POD_NAME} -c ansible-0
```

The `git-clone-#` and `ansible-#` containers may not start at 0 and may not be numbered sequentially if the session was created with the --configuration-limit option.



