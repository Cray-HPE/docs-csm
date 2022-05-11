# Troubleshoot Intermittent HTTP 503 Code Failures

There are cases where API calls or `cray` command invocations will intermittently return an HTTP 503 code, even when the backing service is up and functional.
In the event that this occurs, the following steps may be useful to remediate the issue.

1. Inspect the `istio-ingressgateway` pod logs:

   ```bash
   ncn-m # kubectl -n istio-system logs -l app=istio-ingressgateway
   ```

   If the logs include TLS errors similar to the following, then proceed to the next step to restart the `istio-ingressgateway` pods.
   Istio can occasionally get into this state when NCNs are being rebooted, as well as when many deployments are being created.

   ```text
   [2022-05-10T16:27:29.232Z] "POST /apis/hbtd/hmi/v1/heartbeat HTTP/2" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 132 91 25 - "10.39.0.0" "-"
   "08274ec4-2d93-4070-8fe1-fc6946f1cf26" "api-gw-service-nmn.local" "10.33.0.90:28500" outbound|80||cray-hbtd.services.svc.cluster.local - 10.33.0.43:443 10.39.0.0:29543 api-gw-service-nmn.local -
   ```

1. Perform a rolling restart of the `istio-ingressgateway` pods:

   ```bash
   ncn-m # kubectl rollout restart -n istio-system deployment.apps/istio-ingressgateway
   ```

1. Wait for the roll out to complete:

   ```bash
   ncn-m # kubectl rollout status -n istio-system deployment.apps/istio-ingressgateway
   deployment "istio-ingressgateway" successfully rolled out
   ```

Once the roll out is complete, the HTTP 503 messages should clear, and the intermittent API behavior should resolve.
