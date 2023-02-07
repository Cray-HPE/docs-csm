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

(`ncn-mw#`) Use one of the following commands to retrieve pod-related logs:

```bash
kubectl logs POD_NAME
```

```bash
kubectl logs POD_NAME -c CONTAINER_NAME
```

(`ncn-mw#`) If the pods keeps crashing, open a log for the previous instance using the following command:

```bash
kubectl logs -p POD_NAME
```

## Describe a node

(`ncn-mw#`) Use the following command to retrieve information about a node's condition, such as `OutOfDisk`, `MemoryPressure`, `DiskPressure`, etc.

```bash
kubectl describe node NODE_NAME
```

## Describe a pod

(`ncn-mw#`) Use the following command to retrieve information that can help debug pod-related errors.

```bash
kubectl describe pod POD_NAME
```

(`ncn-mw#`) Use the following command to list all of the containers in a pod, as shown in the following example:

```bash
kubectl describe pod/cray-tftp-6f85767d76-b28gc -n default
```

## Open a shell on a pod

(`ncn-mw#`) Use the following command to connect to a pod:

```bash
kubectl exec -it POD_NAME -c CONTAINER_NAME /bin/sh
```

## Run a single command on a pod

(`ncn-mw#`) Use the following command to execute a command inside a pod:

```bash
kubectl exec POD_NAME ls /
```

## Connect to a running container

(`ncn-mw#`) Use the following command to connect to a currently running container:

```bash
kubectl attach POD_NAME -i
```

## Scale a deployment

(`ncn-mw#`) Use the deployment command to scale a deployment up or down, as shown in the following examples:

```bash
kubectl scale deployment APPLICATION_NAME --replicas=0
kubectl scale deployment APPLICATION_NAME --replicas=3
```

## Remove a deployment with the manifest and reapply the deployment

(`ncn-mw#`) Use the following command to remove components of the deployment's manifest, such as services, network policies, and more:

```bash
kubectl delete –f APPLICATION_NAME.yaml
```

(`ncn-mw#`) Use the following command to reapply the deployment:

```bash
kubectl apply –f APPLICATION_NAME.yaml
```

## Delete a pod

(`ncn-mw#`) Pods can be configured to restart after getting deleted. Use the following command to delete a pod:

```bash
kubectl delete pod POD_NAME
```

**CAUTION:** It is recommended to be careful while deleting deployments or pods, because doing so can have an effect on other pods.
