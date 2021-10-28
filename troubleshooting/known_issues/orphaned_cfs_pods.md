# Orphaned CFS Pods After Booting or Rebooting

After a boot or reboot a few CFS pods may continue running even after they have
finished and never go away.
The state of these pod is that the only container still running in the pod is
`istio-proxy` and the pod does not have a `metadata.ownerReference`.

If `kubectl get pods -n services | grep cfs` is run after a boot or reboot, the
orphaned CFS pods look like this:

```
services         cfs-257e0f3f-f677-4a0f-908a-aede6e6cc2fb-tbwgp                    1/8     NotReady           0          24m
services         cfs-9818f756-8486-49f1-ab7c-0bea733bdbf8-mp296                    1/8     NotReady           0          24m
services         cfs-e8e827c2-9cf0-4a52-9257-e93e275ec394-d8d9z                    1/8     NotReady           0          24m
```

The `READY` field is `1/8`, the `STATUS` is  `NotReady`, and the pod will stay
in this state for much longer than a couple of minutes.

Having a few of these orphaned CFS pods on the system does not cause a problem
but a large number of these could cause problems with monitoring and eventually
no more pods will be able to be scheduled by the system because there is a limit.

The orphaned CFS pods can be cleaned up manually by deleting them, for example,
using the pods above run the following command:

```
# kubectl delete pods -n services cfs-257e0f3f-f677-4a0f-908a-aede6e6cc2fb-tbwgp \
    cfs-9818f756-8486-49f1-ab7c-0bea733bdbf8-mp296 \
    cfs-e8e827c2-9cf0-4a52-9257-e93e275ec394-d8d9z
```

A fix will be provided in a follow-on release such that these orphaned CFS pods
are cleaned up automatically by the system.
