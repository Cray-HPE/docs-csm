# Vertical Pod autoscaler

> ***INTERNAL USE***
> Currently, this document is experimental and not for external use outside of Hewlett-Packard Enterprise.

Kubernetes Vertical Pod Autoscaling (VPA) is **a feature that automatically adjusts the resources allocated to Kubernetes pods, based on their actual resource usage**. In recommendation mode these resource changes are simply recommended as opposed to being automatically adjusted.

## Creating a VPA in recommendation mode for a deployment


## Basic Recommendation Mode VPA Example

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: <deployment-name>-vpa
  namespace: <deployment-namespace>
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       <deployment-name>
  updatePolicy:
    updateMode: "Off" # this puts the vpa in recommendation mode
```

## Checking VPA recommendation

In order to check the VPA recommendation for a specific deployment use:

```bash
kubectl describe vpa -n <namespace> <vpa-name> | tail -n 29
```

output:

```yaml
  Recommendation:
    Container Recommendations:
      Container Name:  cray-cps-broker
      Lower Bound:
        Cpu:     12m
        Memory:  248128516
      Target:
        Cpu:     12m
        Memory:  248153480
      Uncapped Target:
        Cpu:     12m
        Memory:  248153480
      Upper Bound:
        Cpu:           12m
        Memory:        260636136
      Container Name:  istio-proxy
      Lower Bound:
        Cpu:     12m
        Memory:  144631212
      Target:
        Cpu:     12m
        Memory:  144645763
      Uncapped Target:
        Cpu:     12m
        Memory:  144645763
      Upper Bound:
        Cpu:     24m
        Memory:  151921757
Events:          <none>
```

## Reading VPA Recommendations

**WARNING:** be cautuous when setting resources to higher amounts, the VPA recommendation does not take into account the total resources of the system and can get the deployment OOM killed

- The **lower bound** is the minimum estimation for the container.
- The **upper bound** is the maximum recommended resource estimation for the container.
- **Target estimation** is the one we will use for setting resource requests.
- All of these estimations are capped based on **min** allowed and **max** allowed container policies.
- The **uncapped target estimation** is a target estimation produced if there were no **minAllowed** and **maxAllowed** restrictions.


