# Kubernetes Troubleshooting Information

Commands for performing basic Kubernetes cluster troubleshooting.

* [Access pod logs](#access-pod-logs)
* [Describe a node](#describe-a-node)
* [Describe a pod](#describe-a-pod)
* [Open a shell on a pod](#open-a-shell-on-a-pod)
* [Run a single command on a pod](#run-a-single-command-on-a-pod)
* [Connect to a running container](#connect-to-a-running-container)
* [Scale a deployment](#scale-a-deployment)
* [Remove a deployment with the manifest and reapply the deployment](#remove-a-deployment-with-the-manifest-and-reapply-the-deployment)
* [Delete a pod](#delete-a-pod)

## Access pod logs

Use one of the following commands to retrieve pod-related logs:

```bash
ncn-mw# kubectl logs POD_NAME
```

```bash
ncn-mw# kubectl logs POD_NAME -c CONTAINER_NAME
```

If the pods keeps crashing, open a log for the previous instance using the following command:

```bash
ncn-mw# kubectl logs -p POD_NAME
```

## Describe a node

Use the following command to retrieve information about a node's condition, such as `OutOfDisk`, `MemoryPressure`, `DiskPressure`, etc.

```bash
ncn-mw# kubectl describe node NODE_NAME
```

## Describe a pod

Use the following command to retrieve information that can help debug pod-related errors.

```bash
ncn-mw# kubectl describe pod POD_NAME
```

Use the following command to list all of the containers in a pod, as shown in the following example:

```bash
ncn-mw# kubectl describe pod/cray-tftp-6f85767d76-b28gc -n default
```

## Open a shell on a pod

Use the following command to connect to a pod:

```bash
ncn-mw# kubectl exec -it POD_NAME -c CONTAINER_NAME /bin/sh
```

## Run a single command on a pod

Use the following command to execute a command inside a pod:

```bash
ncn-mw# kubectl exec POD_NAME ls /
```

## Connect to a running container

Use the following command to connect to a currently running container:

```bash
ncn-mw# kubectl attach POD_NAME -i
```

## Scale a deployment

Use the deployment command to scale a deployment up or down, as shown in the following examples:

```bash
ncn-mw# kubectl scale deployment APPLICATION_NAME --replicas=0
ncn-mw# kubectl scale deployment APPLICATION_NAME --replicas=3
```

## Remove a deployment with the manifest and reapply the deployment

Use the following command to remove components of the deployment's manifest, such as services, network policies, and more:

```bash
ncn-mw# kubectl delete –f APPLICATION_NAME.yaml
```

Use the following command to reapply the deployment:

```bash
ncn-mw# kubectl apply –f APPLICATION_NAME.yaml
```

## Delete a pod

Pods can be configured to restart after getting deleted. Use the following command to delete a pod:

```bash
ncn-mw# kubectl delete pod POD_NAME
```

**CAUTION:** It is recommended to be careful while deleting deployments or pods, because doing so can have an effect on other pods.
