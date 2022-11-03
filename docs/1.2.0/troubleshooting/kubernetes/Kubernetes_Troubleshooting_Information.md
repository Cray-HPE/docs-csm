# Kubernetes Troubleshooting Information

Commands for performing basic Kubernetes cluster troubleshooting.

### Access Pod Logs

Use one of the following commands to retrieve pod-related logs:

```bash
ncn# kubectl logs POD_NAME
```

```bash
ncn# kubectl logs POD_NAME -c CONTAINER_NAME
```

If the pods keeps crashing, open a log for the previous instance using the following command:

```bash
ncn# kubectl logs -p POD_NAME
```

### Describe a Node

Use the following command to retrieve information about a node's condition, such as `OutOfDisk`, `MemoryPressure`, `DiskPressure`, etc.

```bash
ncn# kubectl describe node NODE_NAME
```

### Describe a Pod

Use the following command to retrieve information that can help debug pod-related errors.

```bash
ncn# kubectl describe pod POD_NAME
```

Use the following command to list all of the containers in a pod, as shown in the following example:

```bash
ncn# kubectl describe pod/cray-tftp-6f85767d76-b28gc -n default
```

### Open a Shell on a Pod

Use the following command to connect to a pod:

```bash
ncn# kubectl exec -it POD_NAME -c CONTAINER_NAME /bin/sh
```

### Run a single Command on a Pod

Use the following command to execute a command inside a pod:

```bash
ncn# kubectl exec POD_NAME ls /
```

### Connect to a Running Container

Use the following command to connect to a currently running container:

```bash
ncn# kubectl attach POD_NAME -i
```

### Scale a Deployment

Use the deployment command to scale a deployment up or down, as shown in the following examples:

```bash
ncn# kubectl scale deployment APPLICATION_NAME --replicas=0
ncn# kubectl scale deployment APPLICATION_NAME --replicas=3
```

### Remove a Deployment with the Manifest and Reapply the Deployment

Use the following command to remove components of the deployment's manifest, such as services, network policies, and more:

```bash
ncn# kubectl delete –f APPLICATION_NAME.yaml
```

Use the following command to reapply the deployment:

```bash
ncn# kubectl apply –f APPLICATION_NAME.yaml
```

### Delete a Pod

Pods can be configured to restart after getting deleted. Use the following command to delete a pod:

```bash
ncn# kubectl delete pod POD_NAME
```

**CAUTION:** It is recommended to be careful while deleting deployments or pods, as doing so can have an affect on other pods.

