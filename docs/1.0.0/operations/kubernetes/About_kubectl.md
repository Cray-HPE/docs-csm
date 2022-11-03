# About kubectl

`kubectl` is a CLI that can be used to run commands against a Kubernetes cluster. The format of the `kubectl` command is shown below:

```bash
ncn# kubectl COMMAND RESOURCE_TYPE RESOURCE_NAME FLAGS
```

An example of using kubectl to retrieve information about a pod is shown below:

```bash
ncn# kubectl get pod POD_NAME1 POD_NAME2
```

`kubectl` is installed by default on the non-compute node \(NCN\) image. To learn more about `kubectl`, refer to [https://kubernetes.io/docs](https://kubernetes.io/docs)
