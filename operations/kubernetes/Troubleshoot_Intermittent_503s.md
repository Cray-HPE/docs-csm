# Troubleshoot Intermittent HTTP 503 Code Failures

There are cases where API calls or `cray` command invocations will fail (sometimes intermittently) with an HTTP 503 error code.
In the event that this occurs, take the following actions according to specific error codes found in the pod or Envoy container
log may be useful to remediate the issue. The Envoy container is typically named `istio-proxy`, it runs as a sidecar for pods
that are part of the Istio mesh. For these pods with sidecar, the logs can be viewed by running a command similar to the following (`ncn-m#`):

```bash
kubectl logs <podname> -n <namespace> -c istio-proxy | grep 503
```

1. (`ncn-m#`) Troubleshoot a `UF,URX` code with a TLS error.

   The logs include errors similar to the following:

   ```text
   [2022-05-10T16:27:29.232Z] "POST /apis/hbtd/hmi/v1/heartbeat HTTP/2" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS"
   ```

   Envoy container can occasionally get into this state when NCNs are being rebooted or upgraded, as well as when many deployments
   are being created. When this happens, delete the pod if it is a single replica or perform a rolling restart of the Deployment
   or StatefulSet if it is part of a multiple replica exhibiting the issue, like:

   ```bash
   kubectl rollout restart -n istio-system deployment istio-ingressgateway
   ```

   Once the roll out is complete, the HTTP 503 message should clear.

1. (`ncn-m#`) Troubleshoot a `UAEX` error code.

   The logs include errors similar to the following:

   ```text
   [2022-06-24T14:16:27.229Z] "POST /apis/hbtd/hmi/v1/heartbeat HTTP/2" 503 UAEX "-" 131 0 30 - "10.34.0.0" "-" "1797b0d3-56f0-4674-8cf2-a8a61f9adaea" "api-gw-service-nmn.local" "-" - - 10.40.0.29:443 10.34.0.0:15995 api-gw-service-nmn.local -
   ```

   This error code typically indicates an issue with the authorization service (for example, Spire). When this happens, perform a rolling restart of the following:

   ```bash
   kubectl rollout restart -n spire statefulset spire-server
   kubectl rollout restart -n spire daemonset spire-agent
   kubectl rollout restart -n spire deployment spire-jwks
   kubectl rollout restart -n spire deployment spire-postgres
   kubectl rollout restart -n spire deployment spire-postgres-pooler
   kubectl rollout restart -n spire daemonset request-ncn-join-token
   ```

   Once the roll out is complete, the HTTP 503 message should clear.

1. Troubleshoot other error codes.

   Although `UF,URX` and `UAEX` codes are most common, various other issues such as networking or application errors can cause different errors in
   the pod or sidecar logs. Please refer to <https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#> for a list of
   possible Envoy response flags. In general, running a rolling restart of the application itself to see if it clears the error is a good practice; otherwise,
   an understanding of what the error message or response flag means is required to further troubleshoot the issue.
